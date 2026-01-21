import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/seed_data.dart';
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
  bool _isLoading = true;
  bool _isSeeding = false;

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

    if (mounted) {
      setState(() {
        _pexelsController.text = pexels ?? '';
        _unsplashController.text = unsplash ?? '';
        _openaiController.text = openai ?? '';
        _restTimerController.text = restTimer.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pexelsController.dispose();
    _unsplashController.dispose();
    _openaiController.dispose();
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
    
    // Invalidate providers
    ref.invalidate(pexelsApiKeyProvider);
    ref.invalidate(unsplashApiKeyProvider);
    ref.invalidate(restTimerProvider);
    
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
      context.pop();
    }
  }

  Future<void> _seedDemoData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Load Demo Data?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will add sample workouts and session history. Existing data will not be overwritten.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Load Data'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isSeeding = true);
    
    try {
      final db = ref.read(appDatabaseProvider);
      final seedService = SeedDataService(db);
      await seedService.seedAll();
      
      // Invalidate providers to refresh data
      ref.invalidate(workoutsStreamProvider);
      ref.invalidate(nextWorkoutProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(activityGridProvider);
      ref.invalidate(isSetupCompleteProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo data loaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
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
}
