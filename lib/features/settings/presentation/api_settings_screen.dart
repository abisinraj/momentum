import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momentum/core/services/settings_service.dart';
import 'package:momentum/core/services/thumbnail_service.dart';
import 'package:momentum/core/providers/ai_providers.dart';

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
  bool _isFetchingModels = false;
  String _selectedGeminiModel = 'gemini-1.5-flash';

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
    final model = await service.getGeminiModel();

    if (mounted) {
      setState(() {
        _pexelsController.text = pexels ?? '';
        _unsplashController.text = unsplash ?? '';
        _geminiController.text = gemini ?? '';
        _selectedGeminiModel = model;
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

  Future<void> _fetchModels() async {
    final apiKey = _geminiController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter Gemini API Key first')),
      );
      return;
    }

    setState(() => _isFetchingModels = true);

    try {
      final models = await ref.read(aiInsightsServiceProvider).listAvailableModels(apiKey);
      if (mounted) {
        setState(() {
           _isFetchingModels = false;
        });
        _showModelsDialog(models);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingModels = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showModelsDialog(List<String> models) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Available Gemini Models'),
         content: SizedBox(
           width: double.maxFinite,
           child: ListView.builder(
             shrinkWrap: true,
             itemCount: models.length,
             itemBuilder: (context, index) {
               final model = models[index];
               final isSelected = model == _selectedGeminiModel;
               return ListTile(
                 leading: Icon(
                   Icons.model_training, 
                   size: 20, 
                   color: isSelected ? Theme.of(context).colorScheme.primary : null
                 ),
                 title: Text(
                   model, 
                   style: TextStyle(
                     fontSize: 14,
                     fontWeight: isSelected ? FontWeight.bold : null,
                     color: isSelected ? Theme.of(context).colorScheme.primary : null,
                   )
                 ),
                 trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 18) : null,
                 onTap: () async {
                   setState(() {
                     _selectedGeminiModel = model;
                   });
                   await ref.read(settingsServiceProvider).setGeminiModel(model);
                   ref.invalidate(geminiModelProvider);
                   if (context.mounted) {
                     Navigator.pop(context);
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Model set to $model')),
                     );
                   }
                 },
                 dense: true,
               );
             },
           ),
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('Close'),
           ),
         ],
       ),
     );
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
                   const SizedBox(height: 8),
                   Align(
                     alignment: Alignment.centerRight,
                     child: TextButton.icon(
                       onPressed: _isFetchingModels ? null : _fetchModels,
                       icon: _isFetchingModels 
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.list_alt, size: 18),
                       label: Text('Model: $_selectedGeminiModel', style: const TextStyle(fontSize: 12)),
                     ),
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

                   _buildInfo(
                     context, 
                     'Pexels provides high-quality stock photos and videos for your workout covers. It is a media provider, not a generative AI model platform.',
                     icon: Icons.image_search,
                     color: Colors.teal,
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

  Widget _buildInfo(BuildContext context, String text, {IconData icon = Icons.lock_outline, Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: effectiveColor, size: 20),
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
