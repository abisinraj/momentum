import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momentum/core/services/settings_service.dart';
import 'package:momentum/core/services/thumbnail_service.dart';

class APISettingsScreen extends ConsumerStatefulWidget {
  const APISettingsScreen({super.key});

  @override
  ConsumerState<APISettingsScreen> createState() => _APISettingsScreenState();
}

class _APISettingsScreenState extends ConsumerState<APISettingsScreen> {
  final _pexelsController = TextEditingController();
  final _unsplashController = TextEditingController();
  final _geminiController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final service = ref.read(settingsServiceProvider);
    final pexels = await service.getPexelsKey();
    final unsplash = await service.getUnsplashKey();
    final gemini = await service.getGeminiKey();

    if (mounted) {
      setState(() {
        _pexelsController.text = pexels ?? '';
        _unsplashController.text = unsplash ?? '';
        _geminiController.text = gemini ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pexelsController.dispose();
    _unsplashController.dispose();
    _geminiController.dispose();
    super.dispose();
  }

  Future<void> _saveKeys() async {
    setState(() => _isSaving = true);
    final service = ref.read(settingsServiceProvider);
    await service.setPexelsKey(_pexelsController.text.trim());
    await service.setUnsplashKey(_unsplashController.text.trim());
    await service.setGeminiKey(_geminiController.text.trim());
    
    // Invalidate providers
    ref.invalidate(pexelsApiKeyProvider);
    ref.invalidate(unsplashApiKeyProvider);
    ref.invalidate(thumbnailServiceProvider); // Force recreate to pick up new keys
    
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Keys saved securely')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('API Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildInfo(context, 'Add your API keys to enable dynamic features like AI insights and workout covers.'),
                   const SizedBox(height: 24),

                   _buildTextField(
                     context,
                     controller: _geminiController,
                     label: 'Google Gemini API Key',
                     hint: 'Enables AI Workout Insights',
                     icon: Icons.auto_awesome,
                   ),
                   const SizedBox(height: 16),
                   
                   _buildTextField(
                     context,
                     controller: _pexelsController,
                     label: 'Pexels API Key',
                     hint: 'For workout cover images',
                     icon: Icons.photo_library,
                   ),
                   const SizedBox(height: 16),
                   _buildTextField(
                     context,
                     controller: _unsplashController,
                     label: 'Unsplash Access Key',
                     hint: 'Alternative for images',
                     icon: Icons.camera_alt,
                   ),
                   const SizedBox(height: 16),

                   
                   const SizedBox(height: 32),
                   
                   SizedBox(
                     width: double.infinity,
                       child: FilledButton.icon(
                       onPressed: _isSaving ? null : _saveKeys,
                       style: FilledButton.styleFrom(
                         backgroundColor: colorScheme.primary,
                         disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.5),
                       ),
                       icon: _isSaving 
                           ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)) 
                           : Icon(Icons.save, color: colorScheme.onPrimary),
                       label: Text(
                         _isSaving ? 'Saving...' : 'Save API Keys',
                         style: TextStyle(color: colorScheme.onPrimary),
                       ),
                     ),
                   ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfo(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: colorScheme.onSurface),
          obscureText: true, // Secure entry by default for keys
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            filled: true,
            fillColor: colorScheme.surfaceContainer,
            prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
            suffixIcon: IconButton(
              icon: Icon(Icons.paste, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
              onPressed: () async {
                // TODO: Paste logic if needed, or simple Paste via long press
              },
            ), 
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}
