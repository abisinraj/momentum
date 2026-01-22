import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/thumbnail_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _pexelsController = TextEditingController();
  final _unsplashController = TextEditingController();
  final _openaiController = TextEditingController();
  final _geminiController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final service = ref.read(settingsServiceProvider);
    final pexels = await service.getPexelsKey();
    final unsplash = await service.getUnsplashKey();
    final openai = await service.getOpenAiKey();
    final gemini = await service.getGeminiKey();

    if (mounted) {
      setState(() {
        _pexelsController.text = pexels ?? '';
        _unsplashController.text = unsplash ?? '';
        _openaiController.text = openai ?? '';
        _geminiController.text = gemini ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pexelsController.dispose();
    _unsplashController.dispose();
    _openaiController.dispose();
    _geminiController.dispose();
    super.dispose();
  }

  Future<void> _saveKeys() async {
    setState(() => _isLoading = true);
    final service = ref.read(settingsServiceProvider);
    await service.setPexelsKey(_pexelsController.text.trim());
    await service.setUnsplashKey(_unsplashController.text.trim());
    await service.setOpenAiKey(_openaiController.text.trim());
    await service.setGeminiKey(_geminiController.text.trim());
    
    // Invalidate providers
    ref.invalidate(pexelsApiKeyProvider);
    ref.invalidate(unsplashApiKeyProvider);
    ref.invalidate(thumbnailServiceProvider); // Force recreate to pick up new keys
    
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Settings'),
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
                   _buildSectionHeader('General'),
                   const SizedBox(height: 16),
                   
                   _buildSettingsTile(
                     icon: Icons.tune,
                     iconColor: AppTheme.tealPrimary,
                     title: 'Workout Settings',
                     subtitle: 'Timer, units, and preferences',
                     onTap: () => context.push(AppRoute.workoutPreferences.path),
                   ),
                   const SizedBox(height: 12),
                   _buildSettingsTile(
                     icon: Icons.widgets_outlined,
                     iconColor: Colors.blueAccent,
                     title: 'Home Screen Widget',
                     subtitle: 'Customize appearance',
                     onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Widget settings coming soon')),
                       );
                     },
                   ),
                   const SizedBox(height: 12),
                   _buildSettingsTile(
                     icon: Icons.notifications_outlined,
                     iconColor: AppTheme.yellowAccent,
                     title: 'Notifications',
                     subtitle: 'On',
                     onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Notification settings coming soon')),
                       );
                     },
                   ),
                   const SizedBox(height: 12),
                   _buildSettingsTile(
                     icon: Icons.widgets_outlined,
                     iconColor: Colors.blueAccent,
                     title: 'Home Screen Widget',
                     subtitle: 'Customize appearance',
                     onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Widget settings coming soon')),
                       );
                     },
                   ),
                   const SizedBox(height: 12),
                   _buildSettingsTile(
                     icon: Icons.palette_outlined,
                     iconColor: Colors.purpleAccent,
                     title: 'Appearance',
                     subtitle: 'System Default',
                     onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Appearance settings coming soon')),
                       );
                     },
                   ),

                   const SizedBox(height: 32),

                   _buildSectionHeader('API Integrations'),
                   const SizedBox(height: 16),
                   _buildInfo('Add your API keys to enable dynamic features.'),
                   const SizedBox(height: 24),

                   _buildTextField(
                     controller: _geminiController,
                     label: 'Google Gemini API Key',
                     hint: 'AI Insights will be enabled',
                     icon: Icons.auto_awesome,
                   ),
                   const SizedBox(height: 16),
                   
                   _buildTextField(
                     controller: _pexelsController,
                     label: 'Pexels API Key',
                     hint: 'Ex: 563492ad6f91...',
                     icon: Icons.photo_library,
                   ),
                   const SizedBox(height: 16),
                   _buildTextField(
                     controller: _unsplashController,
                     label: 'Unsplash Access Key',
                     hint: 'Ex: vK9...',
                     icon: Icons.camera_alt,
                   ),
                   const SizedBox(height: 16),
                   _buildTextField(
                     controller: _openaiController,
                     label: 'OpenAI API Key',
                     hint: 'Ex: sk-...',
                     icon: Icons.smart_toy,
                   ),
                   
                   const SizedBox(height: 32),
                   
                   SizedBox(
                     width: double.infinity,
                     child: FilledButton.icon(
                       onPressed: _saveKeys,
                       icon: const Icon(Icons.save),
                       label: const Text('Save API Keys'),
                     ),
                   ),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null ? Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.tealPrimary,
      ),
    );
  }
  
  Widget _buildInfo(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.tealPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.tealPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
