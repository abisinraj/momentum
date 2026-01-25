import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/user_providers.dart';


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
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
      );
      return;
    }
    
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    
    try {
      // Save user to database
      debugPrint('Setup: Saving user profile...');
      await ref.read(userSetupProvider.notifier).completeSetup(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text),
        heightCm: double.tryParse(_heightController.text),
        weightKg: double.tryParse(_weightController.text),
        goal: _selectedGoal,
      );
      debugPrint('Setup: Profile saved. Navigating to split-setup...');
      
      if (mounted) {
        // Use go() for cleaner navigation stack reset
        context.go('/split-setup');
      } else {
        debugPrint('Setup: Context not mounted!');
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SETUP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
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
                    color: colorScheme.onSurface,
                    height: 1.2,
                  ),
                  children: [
                    const TextSpan(text: 'Set Your\n'),
                    TextSpan(
                      text: 'Baseline',
                      style: TextStyle(
                        color: colorScheme.primary,
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
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              
              const SizedBox(height: 32),
              
              // Display Name field
              _buildLabel(context, 'DISPLAY NAME'),
              const SizedBox(height: 8),
              _buildTextField(
                context,
                controller: _nameController,
                hint: 'How should we call you?',
                suffixIcon: Icons.person_outline,
              ),

              
              const SizedBox(height: 24),
              
              // Age field
              _buildLabel(context, 'AGE'),
              const SizedBox(height: 8),
              _buildTextField(
                context,
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
                        _buildLabel(context, 'HEIGHT'),
                        const SizedBox(height: 8),

                        _buildTextField(
                          context,
                          controller: _heightController,
                          hint: '000',
                          keyboardType: TextInputType.number,
                          suffix: _buildUnitChip(context, 'CM'),
                        ),

                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, 'WEIGHT'),
                        const SizedBox(height: 8),

                        _buildTextField(
                          context,
                          controller: _weightController,
                          hint: '00.0',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffix: _buildUnitDropdown(context),
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
                  _buildLabel(context, 'PRIMARY GOAL'),
                  const SizedBox(width: 8),

                  Text(
                    '(Optional)',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),

                ],
              ),
              const SizedBox(height: 12),
              
              // Goal options
              ...(_goalOptions.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildGoalOption(context, goal.$1, goal.$2, goal.$3),
              ))),

              
              const SizedBox(height: 32),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _completeSetup,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
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
                            color: colorScheme.onPrimary,
                          ),

                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
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
  
  Widget _buildLabel(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        letterSpacing: 1.0,
      ),
    );
  }
  
  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    IconData? suffixIcon,
    Widget? suffix,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: suffix ?? (suffixIcon != null
              ? Icon(suffixIcon, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6), size: 20)
              : null),
        ),
      ),
    );
  }

  
  Widget _buildUnitChip(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  
  Widget _buildUnitDropdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'KG',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: colorScheme.primary, size: 16),
        ],
      ),
    );
  }

  
  Widget _buildGoalOption(BuildContext context, String title, String subtitle, IconData icon) {
    final isSelected = _selectedGoal == title;
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = isSelected ? null : title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary.withValues(alpha: 0.2) : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
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
                color: isSelected ? colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: colorScheme.onPrimary, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

}
