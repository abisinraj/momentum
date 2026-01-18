import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/user_providers.dart';
import '../../../core/providers/workout_providers.dart';
import '../../../core/database/app_database.dart';

/// One-time setup screen for first launch
/// Design: Single page with goal presets
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  String? _selectedGoal;
  bool _isSubmitting = false;

  final _goalOptions = [
    ('Build Muscle', 'Focus on hypertrophy and strength', Icons.fitness_center),
    ('Lose Weight', 'Burn calories and improve metabolism', Icons.local_fire_department),
    ('Stay Active', 'Maintain fitness and stay healthy', Icons.directions_run),
    ('Build Endurance', 'Improve stamina and cardio health', Icons.timer),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your name'),
          backgroundColor: AppTheme.darkSurfaceContainerHigh,
        ),
      );
      return;
    }
    
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    
    try {
      // Save user to database
      print('Setup: Saving user profile...');
      await ref.read(userSetupProvider.notifier).completeSetup(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text),
        heightCm: double.tryParse(_heightController.text),
        weightKg: double.tryParse(_weightController.text),
        goal: _selectedGoal,
      );
      print('Setup: Profile saved. Navigating to split-setup...');
      
      if (mounted) {
        // Use go() for cleaner navigation stack reset
        context.go('/split-setup');
      } else {
        print('Setup: Context not mounted!');
      }
    } catch (e, st) {
      if (mounted) {
        // Show clear error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Setup Error'),
            content: Text('Could not save profile: $e\n\n$st'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with wrench icon
              Row(
                children: [
                  Icon(
                    Icons.build_outlined,
                    color: AppTheme.tealPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SETUP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.tealPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Main title
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                  children: [
                    const TextSpan(text: 'Set Your\n'),
                    TextSpan(
                      text: 'Baseline',
                      style: TextStyle(
                        color: AppTheme.tealPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'To track your momentum, we need to know where you\'re starting.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Display Name field
              _buildLabel('DISPLAY NAME'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: 'How should we call you?',
                suffixIcon: Icons.person_outline,
              ),
              
              const SizedBox(height: 24),
              
              // Age field
              _buildLabel('AGE'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _ageController,
                hint: '00',
                keyboardType: TextInputType.number,
                suffixIcon: Icons.calendar_today_outlined,
              ),
              
              const SizedBox(height: 24),
              
              // Height and Weight row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('HEIGHT'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _heightController,
                          hint: '000',
                          keyboardType: TextInputType.number,
                          suffix: _buildUnitChip('CM'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('WEIGHT'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _weightController,
                          hint: '00.0',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffix: _buildUnitDropdown(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Primary Goal section
              Row(
                children: [
                  _buildLabel('PRIMARY GOAL'),
                  const SizedBox(width: 8),
                  Text(
                    '(Optional)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Goal options
              ...(_goalOptions.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildGoalOption(goal.$1, goal.$2, goal.$3),
              ))),
              
              const SizedBox(height: 32),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _completeSetup,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.tealPrimary,
                    foregroundColor: AppTheme.darkBackground,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.darkBackground,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppTheme.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    IconData? suffixIcon,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: suffix ?? (suffixIcon != null
              ? Icon(suffixIcon, color: AppTheme.textMuted, size: 20)
              : null),
        ),
      ),
    );
  }
  
  Widget _buildUnitChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.tealPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.darkBackground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildUnitDropdown() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.tealPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.tealPrimary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'KG',
            style: TextStyle(
              color: AppTheme.tealPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: AppTheme.tealPrimary, size: 16),
        ],
      ),
    );
  }
  
  Widget _buildGoalOption(String title, String subtitle, IconData icon) {
    final isSelected = _selectedGoal == title;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = isSelected ? null : title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.tealPrimary.withOpacity(0.1) : AppTheme.darkSurfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.tealPrimary : AppTheme.darkBorder.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.tealPrimary.withOpacity(0.2) : AppTheme.darkSurfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.tealPrimary : AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.tealPrimary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.tealPrimary : AppTheme.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: AppTheme.darkBackground, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
