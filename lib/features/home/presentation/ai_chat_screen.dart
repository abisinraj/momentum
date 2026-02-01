import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:momentum/core/providers/ai_providers.dart';
import 'package:momentum/core/services/settings_service.dart';
import 'package:momentum/core/providers/database_providers.dart';
import 'package:momentum/core/database/app_database.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  int? _editingMessageId;

  @override
  void initState() {
    super.initState();
    // Check for offline messages if needed, similar to DietScreen
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 1024);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<String> _getDietContext() async {
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    // Manual query since we need it as a future string
    final logs = await (db.select(db.foodLogs)
      ..where((t) => t.date.isBiggerOrEqualValue(startOfDay))
      ..orderBy([(t) => drift.OrderingTerm.asc(t.date)]))
      .get();
      
    if (logs.isEmpty) return "";
    
    final context = logs.map((log) {
      return "- ${log.description} (${log.calories} kcal, P:${log.protein}g)";
    }).join("\n");
    
    return "Today's Meals:\n$context";
  }

  Future<String> _getWorkoutContext() async {
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    final todaysSessions = await (db.select(db.sessions)
      ..where((t) => t.startedAt.isBiggerOrEqualValue(startOfDay)))
      .get();
      
    if (todaysSessions.isEmpty) return "No workouts recorded today.";
    
    String context = "Today's Workouts:\n";
    for (var session in todaysSessions) {
      final exercises = await db.getSessionExerciseDetails(session.id);
      context += "- Session at ${session.startedAt.hour}:${session.startedAt.minute}\n";
      for (var ex in exercises) {
        context += "  * ${ex['exerciseName']}: ${ex['completedSets']} sets\n";
      }
    }
    return context;
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    final image = _selectedImageBytes;

    if (text.isEmpty && image == null) return;
    
    final db = ref.read(appDatabaseProvider);

    setState(() {
      _isLoading = true;
    });

    // Save User Message
    await db.addHomeChatMessage(HomeChatMessagesCompanion.insert(
      role: 'user',
      content: text,
      isProcessed: const drift.Value(true), // Assuming online for now
    ));

    setState(() {
      _textController.clear();
      _selectedImageBytes = null;
    });

    _scrollToBottom();

    try {
      final apiKey = ref.read(geminiApiKeyProvider).valueOrNull;
      
      // Get Context (Diet + Workout)
      final dietContext = await _getDietContext();
      final workoutContext = await _getWorkoutContext();
      final combinedContext = "$dietContext\n\n$workoutContext";
      
      final responseFragment = await ref.read(aiInsightsServiceProvider).analyzeMessage(
        text: text.isEmpty && image != null ? "Analyze this image" : text,
        imageBytes: image != null ? List<int>.from(image) : null,
        apiKey: apiKey,
        extraContext: combinedContext,
      );

      if (mounted) {
        await db.addHomeChatMessage(HomeChatMessagesCompanion.insert(
          role: 'ai',
          content: responseFragment,
        ));
        
        setState(() {
            _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        await db.addHomeChatMessage(HomeChatMessagesCompanion.insert(
          role: 'ai',
          content: "Error: $e",
        ));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveEditedMessage() async {
    if (_editingMessageId == null) return;
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final db = ref.read(appDatabaseProvider);
    await db.updateHomeChatMessage(HomeChatMessagesCompanion(
      id: drift.Value(_editingMessageId!),
      content: drift.Value(text),
    ));

    setState(() {
      _editingMessageId = null;
      _textController.clear();
      _isLoading = true;
    });
    
    // Re-analyze logic? For now just save.
    // Ideally we should re-trigger analysis.
    // Let's re-trigger analysis for the edited message.
    try {
       final apiKey = ref.read(geminiApiKeyProvider).valueOrNull;
       final dietContext = await _getDietContext();
        final response = await ref.read(aiInsightsServiceProvider).analyzeMessage(
           text: text,
           apiKey: apiKey,
           extraContext: dietContext,
        );
       
       if (mounted) {
          await db.addHomeChatMessage(HomeChatMessagesCompanion.insert(
             role: 'ai',
             content: response,
          ));
       }
    } catch (e) {
       // ...
    }
    
    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _clearChat() async {
    final db = ref.read(appDatabaseProvider);
    await db.clearHomeChatHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat history cleared')),
      );
    }
  }
  
  void _editMessage(HomeChatMessage msg) {
    setState(() {
      _editingMessageId = msg.id;
      _textController.text = msg.content;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final db = ref.watch(appDatabaseProvider);
    final timeFormatAsync = ref.watch(timeFormatProvider);
    final is24h = timeFormatAsync.valueOrNull == '24h';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Momentum AI'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear_history') {
                _clearChat();
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
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<HomeChatMessage>>(
              stream: db.watchHomeChatHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Icon(Icons.smart_toy_outlined, size: 48, color: colorScheme.primary.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            "I'm your Momentum Assistant.\nAsk me about your workouts or diet!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg, colorScheme, is24h);
                  },
                );
              },
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(),
          _buildInputArea(colorScheme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(HomeChatMessage msg, ColorScheme colorScheme, bool is24h) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isUser ? () => _editMessage(msg) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          decoration: BoxDecoration(
            color: isUser ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: isUser ? Radius.zero : null,
              bottomLeft: !isUser ? Radius.zero : null,
            ),
            border: _editingMessageId == msg.id 
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                 msg.content, 
                 style: TextStyle(
                   color: isUser ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                 )
               ),
               const SizedBox(height: 4),
               Row(
                 mainAxisSize: MainAxisSize.min,
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                    Text(
                      DateFormat(is24h ? 'HH:mm' : 'h:mm a').format(msg.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: isUser 
                             ? colorScheme.onPrimaryContainer.withValues(alpha: 0.6)
                             : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                 ],
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          // Removed top border for cleaner integration in bottomNavigationBar
        ),
        child: Column(
          children: [
            if (_selectedImageBytes != null)
              Stack(
                children: [
                   Container(
                     margin: const EdgeInsets.only(bottom: 8),
                     height: 100,
                     decoration: BoxDecoration(
                       border: Border.all(color: colorScheme.primary),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                   ),
                   Positioned(
                     right: 0,
                     top: 0,
                     child: IconButton(
                       icon: const Icon(Icons.close, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                       onPressed: () => setState(() => _selectedImageBytes = null),
                     ),
                   ),
                ],
              ),
            Row(
              children: [
                 IconButton(
                   icon: Icon(_editingMessageId != null ? Icons.cancel : Icons.add_photo_alternate),
                   onPressed: () {
                      if (_editingMessageId != null) {
                         setState(() {
                            _editingMessageId = null;
                            _textController.clear();
                         });
                      } else {
                         _pickImage(ImageSource.gallery);
                      }
                   },
                   tooltip: _editingMessageId != null ? 'Cancel Edit' : 'Gallery',
                 ),
                 if (_editingMessageId == null)
                   IconButton(
                     icon: const Icon(Icons.camera_alt),
                     onPressed: () => _pickImage(ImageSource.camera),
                     tooltip: 'Camera',
                   ),
                 const SizedBox(width: 8),
                 Expanded(
                   child: TextField(
                     controller: _textController,
                     decoration: InputDecoration(
                       hintText: _editingMessageId != null ? 'Edit message...' : 'Ask or describe...',
                       border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     ),
                     maxLines: null,
                     textCapitalization: TextCapitalization.sentences,
                     onSubmitted: (_) => _editingMessageId != null ? _saveEditedMessage() : _sendMessage(),
                   ),
                 ),
                 const SizedBox(width: 8),
                 IconButton.filled(
                   onPressed: (_isLoading && _editingMessageId == null) ? null : (_editingMessageId != null ? _saveEditedMessage : _sendMessage),
                   icon: Icon(_editingMessageId != null ? Icons.check : Icons.send),
                 ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final Uint8List? imageBytes;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.imageBytes,
  });
}
