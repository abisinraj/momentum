import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'dart:async';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/diet_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/settings_service.dart';

class DietAiTab extends ConsumerStatefulWidget {
  const DietAiTab({super.key});

  @override
  ConsumerState<DietAiTab> createState() => _DietAiTabState();
}

class _DietAiTabState extends ConsumerState<DietAiTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _textInputController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  // Chat State
  bool _isAnalyzing = false;
  int? _editingMessageId;

  @override
  bool get wantKeepAlive => true;

  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _textInputController.dispose();
    _chatScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
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

  Future<void> _analyzeText(String text, {bool isRetry = false, int? messageId}) async {
    if (text.trim().isEmpty) return;
    
    final db = ref.read(appDatabaseProvider);
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity.any((c) => c != ConnectivityResult.none);

    if (!isRetry) {
      _editingMessageId = null; 
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
      setState(() {
        _isAnalyzing = false;
      });
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
        content: 'Error: ${e.toString()}. Please check your API key in Settings.',
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
        final extendedResult = Map<String, dynamic>.from(result);
        extendedResult['imageUrl'] = pickedFile.path;
        
        await _handleAnalysisResult(extendedResult);
      } catch (e) {
        if (!mounted) return;
        final db = ref.read(appDatabaseProvider);
        await db.addDietChatMessage(DietChatMessagesCompanion.insert(
          role: 'ai',
          content: 'Error analyzing image: ${e.toString()}',
        ));
        setState(() {
          _isAnalyzing = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _handleAnalysisResult(Map<String, dynamic> result) async {
    final items = result['items'] as List<dynamic>?;
    
    if (items == null || items.isEmpty) {
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
      
      _showLogConfirmationDialog(result);
      _scrollToBottom();
      return;
    }
    
    final itemCount = items.length;
    final itemDescriptions = items.map((item) => item['description'] ?? 'Unknown').join(', ');
    
    final responseText = itemCount == 1
        ? "I found: **${items[0]['description']}**\n"
          "Calories: ${items[0]['calories']} kcal\n"
          "P: ${items[0]['protein']}g | C: ${items[0]['carbs']}g | F: ${items[0]['fats']}g"
        : "I found $itemCount items: **$itemDescriptions**\n"
          "Total Calories: ${items.fold<int>(0, (sum, item) => sum + (item['calories'] as int? ?? 0))} kcal";

    if (!mounted) return;
    final db = ref.read(appDatabaseProvider);
    await db.addDietChatMessage(DietChatMessagesCompanion.insert(
      role: 'ai',
      content: responseText,
    ));

    setState(() {
      _isAnalyzing = false;
    });
    
    for (final item in items) {
      if (mounted) {
        await _showLogConfirmationDialog(item as Map<String, dynamic>);
      }
    }
    
    _scrollToBottom();
  }

  void _editMessage(DietChatMessage message) {
    setState(() {
      _editingMessageId = message.id;
      _textInputController.text = message.content;
    });
    _focusNode.requestFocus();
  }

  Future<void> _saveEditedMessage(String text) async {
    if (_editingMessageId == null) return;
    if (text.trim().isEmpty) return;

    try {
      final db = ref.read(appDatabaseProvider);
      await db.updateDietChatMessage(DietChatMessagesCompanion(
        id: drift.Value(_editingMessageId!),
        content: drift.Value(text),
      ));

      final messageIdToUpdate = _editingMessageId;

      setState(() {
        _editingMessageId = null;
        _textInputController.clear();
        _isAnalyzing = true;
      });

      // Analyze the updated text
      await _analyzeText(text, isRetry: true, messageId: messageIdToUpdate);

    } catch (e) {
      debugPrint('Error saving edited message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update message: $e')),
        );
      }
    }
  }



  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  // Dialogs
  Future<void> _showLogConfirmationDialog(Map<String, dynamic> data) async {
    final descCtrl = TextEditingController(text: data['description']);
    final calCtrl = TextEditingController(text: data['calories'].toString());
    final pCtrl = TextEditingController(text: data['protein'].toString());
    final cCtrl = TextEditingController(text: data['carbs'].toString());
    final fCtrl = TextEditingController(text: data['fats'].toString());
    
    final fibCtrl = TextEditingController(text: (data['fiber'] ?? 0.0).toString());
    final sugCtrl = TextEditingController(text: (data['sugar'] ?? 0.0).toString());
    final sodCtrl = TextEditingController(text: (data['sodium'] ?? 0.0).toString());
    
    final waterCtrl = TextEditingController(text: "0"); 
    if (data['description'].toString().toLowerCase().contains('water')) {
       waterCtrl.text = "250"; 
    }

    bool showMicros = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit & Log Meal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _buildNumField(calCtrl, 'Calories', 'kcal')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildNumField(waterCtrl, 'Water', 'ml')),
                  ]),
                  const SizedBox(height: 12),
                  const Text('Macros', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(child: _buildNumField(pCtrl, 'Protein', 'g')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildNumField(cCtrl, 'Carbs', 'g')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildNumField(fCtrl, 'Fats', 'g')),
                  ]),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setDialogState(() => showMicros = !showMicros),
                    child: Row(children: [
                      Icon(showMicros ? Icons.expand_less : Icons.expand_more),
                      const Text('Micronutrients (Optional)', style: TextStyle(color: Colors.blue)),
                    ]),
                  ),
                   if (showMicros) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _buildNumField(fibCtrl, 'Fiber', 'g')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildNumField(sugCtrl, 'Sugar', 'g')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildNumField(sodCtrl, 'Sodium', 'mg')),
                      ]),
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
                    'imageUrl': data['imageUrl'],
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
        labelText: label, suffixText: suffix, isDense: true, border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Future<void> _logToDatabase(Map<String, dynamic> data) async {
    final db = ref.read(appDatabaseProvider);
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
    // Provide visual feedback handled by stream
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final db = ref.watch(appDatabaseProvider);
    final timeFormatAsync = ref.watch(timeFormatProvider);
    final is24h = timeFormatAsync.valueOrNull == '24h';
    
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

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
                                  if (isUser) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _editMessage(msg),
                                      child: Icon(
                                        Icons.edit, 
                                        size: 14, 
                                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.6)
                                      ),
                                    ),
                                  ],
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
          // Input Area
          Container(
            padding: EdgeInsets.fromLTRB(
              16, 
              16, 
              16, 
              isKeyboardOpen ? 16 : 72,
            ),
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
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: _editingMessageId != null ? 'Edit your message...' : 'e.g. "Ate a chicken burger"',
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _textInputController,
                        builder: (context, value, child) {
                          return (value.text.isNotEmpty && _editingMessageId == null)
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => _textInputController.clear(),
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onChanged: (val) {},
                    onSubmitted: (val) => val.trim().isNotEmpty 
                        ? (_editingMessageId != null ? _saveEditedMessage(val) : _analyzeText(val)) 
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textInputController,
                  builder: (context, value, child) {
                    return IconButton.filled(
                      icon: Icon(_editingMessageId != null ? Icons.check : Icons.send),
                      onPressed: (_isAnalyzing || value.text.trim().isEmpty) 
                          ? null 
                          : () {
                            if (_editingMessageId != null) {
                              _saveEditedMessage(value.text);
                            } else {
                              _analyzeText(value.text);
                            }
                          },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
