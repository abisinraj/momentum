import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:momentum/core/providers/ai_providers.dart';
import 'package:momentum/core/services/settings_service.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    // Add initial greeting
    _messages.add(ChatMessage(
      text: "Hello! I'm your fitness assistant. Ask me anything or send a photo of your meal/equipment!",
      isUser: false,
    ));
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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    final image = _selectedImageBytes;

    if (text.isEmpty && image == null) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        imageBytes: image,
        isUser: true,
      ));
      _isLoading = true;
      _textController.clear();
      _selectedImageBytes = null;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    try {
      final apiKey = ref.read(geminiApiKeyProvider).valueOrNull;
      final response = await ref.read(aiInsightsServiceProvider).analyzeMessage(
        text: text.isEmpty && image != null ? "Analyze this image" : text,
        imageBytes: image != null ? List<int>.from(image) : null,
        apiKey: apiKey,
      );

      if (mounted) {
        setState(() {
            _messages.add(ChatMessage(text: response, isUser: false));
            _isLoading = false;
        });
        // Scroll again
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: "Error: $e", isUser: false, isError: true));
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, colorScheme);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          _buildInputArea(colorScheme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, ColorScheme colorScheme) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             if (msg.imageBytes != null)
               Padding(
                 padding: const EdgeInsets.only(bottom: 8.0),
                 child: ClipRRect(
                   borderRadius: BorderRadius.circular(8),
                   child: Image.memory(msg.imageBytes!, height: 150, fit: BoxFit.cover),
                 ),
               ),
             if (msg.text.isNotEmpty)
                Text(
                  msg.text, 
                  style: TextStyle(
                    color: isUser ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                    // If it's an error, maybe red?
                  )
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
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
                 icon: const Icon(Icons.add_photo_alternate),
                 onPressed: () => _pickImage(ImageSource.gallery),
                 tooltip: 'Gallery',
               ),
               IconButton(
                 icon: const Icon(Icons.camera_alt),
                 onPressed: () => _pickImage(ImageSource.camera),
                 tooltip: 'Camera',
               ),
               const SizedBox(width: 8),
               Expanded(
                 child: TextField(
                   controller: _textController,
                   decoration: const InputDecoration(
                     hintText: 'Ask or describe...',
                     border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                     contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   ),
                   maxLines: null,
                   textCapitalization: TextCapitalization.sentences,
                 ),
               ),
               const SizedBox(width: 8),
               IconButton.filled(
                 onPressed: _isLoading ? null : _sendMessage,
                 icon: const Icon(Icons.send),
               ),
            ],
          ),
        ],
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
