
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/services/diet_service.dart';
import 'dart:io';
import 'package:drift/drift.dart' as drift;

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
  final List<Map<String, String>> _messages = []; // role: user/ai, content: text
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textInputController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _analyzeText(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isAnalyzing = true;
    });
    _textInputController.clear();
    _scrollToBottom();

    try {
      final dietService = ref.read(dietServiceProvider);
      final result = await dietService.analyzeFoodText(text);
      
      if (!mounted) return;
      _handleAnalysisResult(result);
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'ai', 'content': 'Error: $e. Please check your API key in Settings.'});
        _isAnalyzing = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      setState(() {
        _messages.add({'role': 'user', 'content': 'Analyzing image...'});
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
        
        _handleAnalysisResult(extendedResult);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _messages.add({'role': 'ai', 'content': 'Error analyzing image: $e'});
          _isAnalyzing = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _handleAnalysisResult(Map<String, dynamic> result) {
    // Format the result nicely
    final desc = result['description'] ?? 'Food';
    final cal = result['calories'] ?? 0;
    final p = result['protein'] ?? 0;
    final c = result['carbs'] ?? 0;
    final f = result['fats'] ?? 0;
    // imageUrl is stored in result for logging but not displayed here

    final responseText = "I found: **$desc**\n"
        "Calories: $cal kcal\n"
        "P: ${p}g | C: ${c}g | F: ${f}g";

    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'ai', 'content': responseText});
      _messages.add({'role': 'action_log', 'data': responseText, 'json': result.toString()}); 
      // We store the structured data to allow one-tap logging
      // But for simplicity in this MVP, let's just use a special message type or just a button below?
      // Better: Add a "Log this" button inside the AI message bubble if possible.
      // For now, I'll store the 'pending' log in a separate state or just immediately ask to log?
      // Let's make the AI message actionable.
      _isAnalyzing = false;
    });
    
    // Auto-prompt to log
    if (mounted) {
      _showLogConfirmationDialog(result);
      _scrollToBottom();
    }
  }
  
  void _showLogConfirmationDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Meal?'),
        content: Text(
          "${data['description']}\n"
          "${data['calories']} kcal\n"
          "Protein: ${data['protein']}g\n"
          "Carbs: ${data['carbs']}g\n"
          "Fats: ${data['fats']}g"
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              _logToDatabase(data);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal logged!')));
            },
            child: const Text('Log Meal'),
          ),
        ],
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
          _chatScrollController.position.maxScrollExtent,
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
           IconButton(
             icon: const Icon(Icons.settings),
             onPressed: () {
               context.push('/settings');
             },
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
    
    return FutureBuilder<List<FoodLog>>(
      future: db.getFoodLogsForDate(DateTime.now()),
      builder: (context, snapshot) {
         // Note: FutureBuilder won't auto-refresh on add. 
         // Better to use StreamBuilder if we had a stream, or `setState` trigger.
         // For now, let's assume we might need a workaround or better provider.
         // A simple workaround is to wrap this in a Consumer that watches a provider we invalidate.
         // BUT, simpler: let's make a new Provider in database_providers.dart in next step?
         // Or just use the Future and call setState on log add.
         
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
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    msg['content'] ?? '',
                    style: TextStyle(
                      color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
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
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () => _showImageSourceSheet(),
              ),
              Expanded(
                child: TextField(
                  controller: _textInputController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. "Ate a chicken burger"',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: _analyzeText,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _analyzeText(_textInputController.text),
              ),
            ],
          ),
        ),
      ],
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
