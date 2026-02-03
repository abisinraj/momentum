
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/services/diet_service.dart';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/settings_service.dart'; // Import settings service

class DietScreen extends ConsumerStatefulWidget {
  const DietScreen({super.key});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends ConsumerState<DietScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textInputController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  
  // Chat State
  bool _isAnalyzing = false;
  int? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initConnectivity();
  }

  void _initConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
       // if any result in results is not none, we are online
       final isOnline = results.any((r) => r != ConnectivityResult.none);
       if (isOnline) {
         _processOfflineMessages();
       }
    });
  }

  Future<void> _processOfflineMessages() async {
    final db = ref.read(appDatabaseProvider);
    final history = await db.getDietChatHistory();
    final unprocessed = history.where((msg) => msg.role == 'user' && !msg.isProcessed).toList();
    
    if (unprocessed.isEmpty) return;
    
    for (final msg in unprocessed) {
       await _analyzeText(msg.content, isRetry: true, messageId: msg.id);
    }
    
    NotificationService.showNotification(
      id: 1,
      title: 'Diet Analysis Complete',
      body: 'Processed ${unprocessed.length} pending food logs.',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textInputController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _analyzeText(String text, {bool isRetry = false, int? messageId}) async {
    if (text.trim().isEmpty) return;
    
    final db = ref.read(appDatabaseProvider);
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity.any((c) => c != ConnectivityResult.none);

    if (!isRetry) {
      _editingMessageId = null; // Reset editing state
      await db.addDietChatMessage(DietChatMessagesCompanion.insert(
        role: 'user',
        content: text,
        isProcessed: drift.Value(isOnline),
      ));
    } else if (messageId != null && isOnline) {
      await db.updateDietChatMessage(DietChatMessagesCompanion(
        id: drift.Value(messageId),
        isProcessed: const drift.Value(true),
      ));
    }

    if (!isOnline) {
      _textInputController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline. Meal will be processed when you reconnect.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });
    _textInputController.clear();
    _scrollToBottom();

    try {
      final dietService = ref.read(dietServiceProvider);
      final result = await dietService.analyzeFoodText(text);
      
      if (!mounted) return;
      await _handleAnalysisResult(result);
      
    } catch (e) {
      if (!mounted) return;
      final db = ref.read(appDatabaseProvider);
      await db.addDietChatMessage(DietChatMessagesCompanion.insert(
        role: 'ai',
        content: 'Error: $e. Please check your API key in Settings.',
      ));
      setState(() {
        _isAnalyzing = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      final db = ref.read(appDatabaseProvider);
      await db.addDietChatMessage(DietChatMessagesCompanion.insert(
        role: 'user',
        content: 'Analyzing image...',
      ));

      setState(() {
        _isAnalyzing = true;
      });
      _scrollToBottom();

      try {
        final dietService = ref.read(dietServiceProvider);
        final imageBytes = await File(pickedFile.path).readAsBytes();
        final result = await dietService.analyzeFoodImage(imageBytes);
        
        if (!mounted) return;
        // Also save image path? 
        // For now just passing the result. 
        // We could attach the image path to the log if we wanted.
        final extendedResult = Map<String, dynamic>.from(result);
        extendedResult['imageUrl'] = pickedFile.path;
        
        extendedResult['imageUrl'] = pickedFile.path;
        
        await _handleAnalysisResult(extendedResult);
      } catch (e) {
        if (!mounted) return;
        final db = ref.read(appDatabaseProvider);
        await db.addDietChatMessage(DietChatMessagesCompanion.insert(
          role: 'ai',
          content: 'Error analyzing image: $e',
        ));
        setState(() {
          _isAnalyzing = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _handleAnalysisResult(Map<String, dynamic> result) async {
    // Format the result nicely
    final desc = result['description'] ?? 'Food';
    final cal = result['calories'] ?? 0;
    final p = result['protein'] ?? 0;
    final c = result['carbs'] ?? 0;
    final f = result['fats'] ?? 0;

    final responseText = "I found: **$desc**\n"
        "Calories: $cal kcal\n"
        "P: ${p}g | C: ${c}g | F: ${f}g";

    if (!mounted) return;
    final db = ref.read(appDatabaseProvider);
    await db.addDietChatMessage(DietChatMessagesCompanion.insert(
      role: 'ai',
      content: responseText,
    ));

    setState(() {
      _isAnalyzing = false;
    });
    
    // Auto-prompt to log
    if (mounted) {
      _showLogConfirmationDialog(result);
      _scrollToBottom();
    }
  }

  Future<void> _editMessage(DietChatMessage message) async {
    _editingMessageId = message.id;
    _textInputController.text = message.content;
    _tabController.animateTo(1); // Switch to AI Assistant tab
  }

  Future<void> _saveEditedMessage() async {
    if (_editingMessageId == null) return;
    final text = _textInputController.text.trim();
    if (text.isEmpty) return;

    final db = ref.read(appDatabaseProvider);
    await db.updateDietChatMessage(DietChatMessagesCompanion(
      id: drift.Value(_editingMessageId!),
      content: drift.Value(text),
    ));

    setState(() {
      _editingMessageId = null;
      _textInputController.clear();
      _isAnalyzing = true;
    });

    // Re-analyze after edit
    await _analyzeText(text);
  }

  Future<void> _clearChat() async {
    final db = ref.read(appDatabaseProvider);
    await db.clearDietChatHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat history cleared')),
      );
    }
  }
  
  void _showLogConfirmationDialog(Map<String, dynamic> data) {
    // Controllers for editing
    final descCtrl = TextEditingController(text: data['description']);
    final calCtrl = TextEditingController(text: data['calories'].toString());
    final pCtrl = TextEditingController(text: data['protein'].toString());
    final cCtrl = TextEditingController(text: data['carbs'].toString());
    final fCtrl = TextEditingController(text: data['fats'].toString());
    
    // Micros
    final fibCtrl = TextEditingController(text: (data['fiber'] ?? 0.0).toString());
    final sugCtrl = TextEditingController(text: (data['sugar'] ?? 0.0).toString());
    final sodCtrl = TextEditingController(text: (data['sodium'] ?? 0.0).toString());
    
    // Water
    final waterCtrl = TextEditingController(text: "0"); // Default 0 for meal, or auto if 'water' detected? 
    if (data['description'].toString().toLowerCase().contains('water')) {
       // Estimation if water is main item
       waterCtrl.text = "250"; 
    }

    bool showMicros = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit & Log Meal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildNumField(calCtrl, 'Calories', 'kcal')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildNumField(waterCtrl, 'Water', 'ml')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Macros', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: _buildNumField(pCtrl, 'Protein', 'g')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildNumField(cCtrl, 'Carbs', 'g')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildNumField(fCtrl, 'Fats', 'g')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setState(() => showMicros = !showMicros),
                    child: Row(
                      children: [
                        Icon(showMicros ? Icons.expand_less : Icons.expand_more),
                        const Text('Micronutrients (Optional)', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                   if (showMicros) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildNumField(fibCtrl, 'Fiber', 'g')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildNumField(sugCtrl, 'Sugar', 'g')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildNumField(sodCtrl, 'Sodium', 'mg')),
                        ],
                      ),
                   ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  final updatedData = {
                    'description': descCtrl.text,
                    'calories': int.tryParse(calCtrl.text) ?? 0,
                    'protein': double.tryParse(pCtrl.text) ?? 0.0,
                    'carbs': double.tryParse(cCtrl.text) ?? 0.0,
                    'fats': double.tryParse(fCtrl.text) ?? 0.0,
                    'fiber': double.tryParse(fibCtrl.text) ?? 0.0,
                    'sugar': double.tryParse(sugCtrl.text) ?? 0.0,
                    'sodium': double.tryParse(sodCtrl.text) ?? 0.0,
                    'waterMl': int.tryParse(waterCtrl.text) ?? 0,
                    'imageUrl': data['imageUrl'], // Keep original if any
                  };
                  
                  _logToDatabase(updatedData);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Meal logged!')));
                },
                child: const Text('Save Log'),
              ),
            ],
          );
        }
      ),
    );
  }
  
  Widget _buildNumField(TextEditingController ctrl, String label, String suffix) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Future<void> _logToDatabase(Map<String, dynamic> data) async {
    final db = ref.watch(appDatabaseProvider);
    await db.addFoodLog(FoodLogsCompanion.insert(
      description: data['description'] ?? 'Unknown',
      calories: data['calories'] is int ? data['calories'] : int.tryParse(data['calories'].toString()) ?? 0,
      protein: drift.Value(double.tryParse(data['protein'].toString()) ?? 0.0),
      carbs: drift.Value(double.tryParse(data['carbs'].toString()) ?? 0.0),
      fats: drift.Value(double.tryParse(data['fats'].toString()) ?? 0.0),
      fiber: drift.Value(double.tryParse(data['fiber'].toString()) ?? 0.0),
      sugar: drift.Value(double.tryParse(data['sugar'].toString()) ?? 0.0),
      sodium: drift.Value(double.tryParse(data['sodium'].toString()) ?? 0.0),
      waterMl: drift.Value(int.tryParse(data['waterMl'].toString()) ?? 0),
      imageUrl: drift.Value(data['imageUrl']),
      date: drift.Value(DateTime.now()),
    ));
    // Provide visual feedback or refresh journal tab
    if (_tabController.index != 0) {
      // Maybe switch or just letting the stream update
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          0.0, // Scroll to bottom (start of reversed list)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Diet & Nutrition'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Journal'),
            Tab(text: 'AI Assistant'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear_history') {
                _showClearConfirmation();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_history',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear Chat History'),
                  ],
                ),
              ),
              PopupMenuItem(
                enabled: false,
                child: Consumer(
                  builder: (context, ref, _) {
                    final is24h = ref.watch(timeFormatProvider).asData?.value == '24h';
                    return GestureDetector(
                      onTap: () {
                         final newFormat = is24h ? '12h' : '24h';
                         ref.read(timeFormatProvider.notifier).setFormat(newFormat);
                         Navigator.pop(context); // Close menu
                      },
                      child: Row(
                        children: [
                          Icon(is24h ? Icons.access_time_filled : Icons.access_time, size: 20, color: theme.colorScheme.onSurface),
                          const SizedBox(width: 8),
                          Text(is24h ? 'Use 12h Format' : 'Use 24h Format'),
                        ],
                      ),
                    );
                  }
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJournalTab(theme),
          _buildAiChatTab(theme),
        ],
      ),
    );
  }

  Widget _buildJournalTab(ThemeData theme) {
    // Watch today's logs
    // We need a StreamProvider for this in database_providers.dart or just FutureBuilder here for MVP
    // Let's use a FutureBuilder that watches a stream locally or creating a quick ad-hoc stream
    final db = ref.watch(appDatabaseProvider);
    
    return StreamBuilder<List<FoodLog>>(
      stream: db.watchFoodLogsForDate(DateTime.now()),
      builder: (context, snapshot) {
         if (!snapshot.hasData) {
           return const Center(child: CircularProgressIndicator());
         }
         
         final logs = snapshot.data!;
         final totalCal = logs.fold<int>(0, (sum, item) => sum + item.calories);
         final totalP = logs.fold<double>(0, (sum, item) => sum + item.protein);
         final totalC = logs.fold<double>(0, (sum, item) => sum + item.carbs);
         final totalF = logs.fold<double>(0, (sum, item) => sum + item.fats);
         
         return ListView(
           padding: const EdgeInsets.all(16),
           children: [
             // Summary Card
             Card(
               color: theme.colorScheme.primaryContainer,
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                   children: [
                      _buildMacroSummary('Calories', '$totalCal', 'kcal', theme),
                      _buildMacroSummary('Protein', totalP.toStringAsFixed(1), 'g', theme),
                      _buildMacroSummary('Carbs', totalC.toStringAsFixed(1), 'g', theme),
                      _buildMacroSummary('Fats', totalF.toStringAsFixed(1), 'g', theme),
                   ],
                 ),
               ),
             ),
             const SizedBox(height: 16),
             const Text('Today\'s Meals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
             const SizedBox(height: 8),
             if (logs.isEmpty)
               const Center(child: Padding(
                 padding: EdgeInsets.all(32.0),
                 child: Text('No meals logged today.\nUse the AI Assistant to add one!'),
               )),
             ...logs.map((log) => Card(
               margin: const EdgeInsets.only(bottom: 8),
               child: ListTile(
                 leading: log.imageUrl != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(log.imageUrl!), width: 50, height: 50, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.fastfood),
                        ),
                      ) 
                    : const Icon(Icons.fastfood),
                 title: Text(log.description),
                 subtitle: Text('${log.calories} kcal • P:${log.protein} C:${log.carbs} F:${log.fats}'),
                 trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await db.deleteFoodLog(log.id);
                      setState(() {}); // Refresh
                    },
                 ),
               ),
             )),
           ],
         );
      },
    );
  }
  
  Widget _buildMacroSummary(String label, String value, String unit, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
        Text('$unit $label', style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildAiChatTab(ThemeData theme) {
    final db = ref.watch(appDatabaseProvider);
    final timeFormatAsync = ref.watch(timeFormatProvider);
    final is24h = timeFormatAsync.valueOrNull == '24h';
    
    return SafeArea(
      bottom: true,
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<DietChatMessage>>(
              stream: db.watchDietChatHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = (snapshot.data ?? []).reversed.toList();
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet.\nAsk me about your meals!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg.role == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: isUser ? () => _editMessage(msg) : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isUser ? Radius.zero : null,
                              bottomLeft: !isUser ? Radius.zero : null,
                            ),
                            border: _editingMessageId == msg.id 
                                ? Border.all(color: theme.colorScheme.onPrimary, width: 2)
                                : null,
                          ),
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                msg.content,
                                style: TextStyle(
                                  color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isUser && !msg.isProcessed)
                                    Icon(Icons.access_time, size: 10, color: theme.colorScheme.onPrimary.withValues(alpha: 0.5))
                                  else if (isUser)
                                    Icon(Icons.done_all, size: 10, color: theme.colorScheme.onPrimary.withValues(alpha: 0.7)),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat(is24h ? 'HH:mm' : 'h:mm a').format(msg.createdAt),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isUser 
                                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.6)
                                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isAnalyzing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_editingMessageId != null ? Icons.cancel : Icons.camera_alt),
                  onPressed: () {
                    if (_editingMessageId != null) {
                      setState(() {
                        _editingMessageId = null;
                        _textInputController.clear();
                      });
                    } else {
                      _showImageSourceSheet();
                    }
                  },
                  tooltip: _editingMessageId != null ? 'Cancel Edit' : 'Take Photo',
                ),
                Expanded(
                  child: TextField(
                    controller: _textInputController,
                    decoration: InputDecoration(
                      hintText: _editingMessageId != null ? 'Edit your message...' : 'e.g. "Ate a chicken burger"',
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      suffixIcon: _textInputController.text.isNotEmpty && _editingMessageId == null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => _textInputController.clear(),
                            )
                          : null,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) => _editingMessageId != null ? _saveEditedMessage() : _analyzeText(val),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1F1F1F), // Dark background always
                    foregroundColor: Colors.white, // White icon always
                  ),
                  icon: Icon(_editingMessageId != null ? Icons.check : Icons.send),
                  onPressed: () {
                    if (_editingMessageId != null) {
                      _saveEditedMessage();
                    } else {
                      _analyzeText(_textInputController.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text('This will permanently delete all messages in this chat.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearChat();
            },
            child: Text('Clear', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
  
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
           ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }
}
