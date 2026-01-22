import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/settings_service.dart';

class WorkoutPreferencesScreen extends ConsumerStatefulWidget {
  const WorkoutPreferencesScreen({super.key});

  @override
  ConsumerState<WorkoutPreferencesScreen> createState() => _WorkoutPreferencesScreenState();
}

class _WorkoutPreferencesScreenState extends ConsumerState<WorkoutPreferencesScreen> {
  final _restTimerController = TextEditingController();
  final _focusNode = FocusNode();
  String _weightUnit = 'kg'; // Default
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final settings = ref.read(settingsServiceProvider);
    
    final restTimer = await settings.getRestTimer();
    final weightUnit = await settings.getWeightUnit();
    
    if (mounted) {
      setState(() {
        _restTimerController.text = restTimer.toString();
        _weightUnit = weightUnit;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _restTimerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    final settings = ref.read(settingsServiceProvider);
    
    // Save Rest Timer
    final restTimer = int.tryParse(_restTimerController.text) ?? 60;
    await settings.setRestTimer(restTimer);
    
    // Save Weight Unit
    await settings.setWeightUnit(_weightUnit);
    
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved'),
          backgroundColor: AppTheme.tealPrimary,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Workout Preferences'),
        backgroundColor: AppTheme.darkBackground,
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
                  _buildTextField(
                    controller: _restTimerController,
                    label: 'Rest Timer (seconds)',
                    hint: '60',
                    icon: Icons.timer_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildWeightUnitSelector(),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _savePreferences,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.tealPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.save, color: AppTheme.darkBackground),
                      label: const Text(
                        'Save Preferences',
                        style: TextStyle(
                          color: AppTheme.darkBackground,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
          style: const TextStyle(
            color: AppTheme.textSecondary,
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
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: AppTheme.darkSurface,
            prefixIcon: Icon(icon, color: AppTheme.tealPrimary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.tealPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightUnitSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weight Unit',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(12),
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
                          ? AppTheme.tealPrimary.withValues(alpha: 0.2) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: _weightUnit == 'kg'
                          ? Border.all(color: AppTheme.tealPrimary.withValues(alpha: 0.5))
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Kilograms (kg)',
                        style: TextStyle(
                          color: _weightUnit == 'kg' 
                              ? AppTheme.tealPrimary 
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _weightUnit = 'lbs'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _weightUnit == 'lbs' 
                          ? AppTheme.tealPrimary.withValues(alpha: 0.2) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: _weightUnit == 'lbs'
                          ? Border.all(color: AppTheme.tealPrimary.withValues(alpha: 0.5))
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Pounds (lbs)',
                        style: TextStyle(
                          color: _weightUnit == 'lbs' 
                              ? AppTheme.tealPrimary 
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
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
