import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/providers/database_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _pexelsController = TextEditingController();
  final _unsplashController = TextEditingController();
  final _openaiController = TextEditingController();
  final _restTimerController = TextEditingController();
  String _weightUnit = 'kg'; // 'kg' or 'lbs'
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
    final restTimer = await service.getRestTimer();
    final weightUnit = await service.getWeightUnit();

    if (mounted) {
      setState(() {
        _pexelsController.text = pexels ?? '';
        _unsplashController.text = unsplash ?? '';
        _openaiController.text = openai ?? '';
        _restTimerController.text = restTimer.toString();
        _weightUnit = weightUnit;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pexelsController.dispose();
    _unsplashController.dispose();
    _openaiController.dispose();
    _restTimerController.dispose();
    super.dispose();
  }

  Future<void> _saveKeys() async {
    setState(() => _isLoading = true);
    final service = ref.read(settingsServiceProvider);
    await service.setPexelsKey(_pexelsController.text.trim());
    await service.setUnsplashKey(_unsplashController.text.trim());
    await service.setOpenAiKey(_openaiController.text.trim());
    
    final restTime = int.tryParse(_restTimerController.text.trim()) ?? 60;
    await service.setRestTimer(restTime);
    await service.setWeightUnit(_weightUnit);
    
    // Invalidate providers
    ref.invalidate(pexelsApiKeyProvider);
    ref.invalidate(unsplashApiKeyProvider);
    ref.invalidate(restTimerProvider);
    ref.invalidate(weightUnitProvider);
    
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
                   _buildSectionHeader('API Integrations'),
                   const SizedBox(height: 16),
                   _buildInfo('Add your API keys to enable dynamic features.'),
                   const SizedBox(height: 24),
                   
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
                   
                   _buildSectionHeader('Workout Preferences'),
                   const SizedBox(height: 16),
                   _buildTextField(
                     controller: _restTimerController,
                     label: 'Rest Timer (seconds)',
                     hint: '60',
                     icon: Icons.timer_outlined,
                     keyboardType: TextInputType.number,
                   ),
                   const SizedBox(height: 16),
                   _buildWeightUnitSelector(),

                   const SizedBox(height: 32),
                   
                   SizedBox(
                     width: double.infinity,
                     child: FilledButton.icon(
                       onPressed: _saveKeys,
                       icon: const Icon(Icons.save),
                       label: const Text('Save Settings'),
                     ),
                   ),
                ],
              ),
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
        border: Border.all(color: AppTheme.tealPrimary.withOpacity(0.3)),
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

  Widget _buildWeightUnitSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weight Unit',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.tealPrimary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _weightUnit = 'kg'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _weightUnit == 'kg'
                          ? AppTheme.tealPrimary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                    ),
                    child: Center(
                      child: Text(
                        'Kilograms (kg)',
                        style: TextStyle(
                          color: _weightUnit == 'kg'
                              ? AppTheme.tealPrimary
                              : AppTheme.textSecondary,
                          fontWeight: _weightUnit == 'kg' ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _weightUnit = 'lbs'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _weightUnit == 'lbs'
                          ? AppTheme.tealPrimary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                    ),
                    child: Center(
                      child: Text(
                        'Pounds (lbs)',
                        style: TextStyle(
                          color: _weightUnit == 'lbs'
                              ? AppTheme.tealPrimary
                              : AppTheme.textSecondary,
                          fontWeight: _weightUnit == 'lbs' ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
