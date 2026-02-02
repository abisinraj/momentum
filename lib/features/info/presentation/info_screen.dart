import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/dashboard_providers.dart';
import '../../home/presentation/widgets/three_d_man_widget.dart';

/// Info screen - profile, settings, and data management
/// Design: Profile avatar, stats row, Google Drive backup, preferences
class InfoScreen extends ConsumerStatefulWidget {
  const InfoScreen({super.key});

  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> {
  String? _focusedMuscle;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final activityAsync = ref.watch(activityGridProvider(365));
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile & Status',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoute.settings.path),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.settings_outlined, color: theme.colorScheme.primary, size: 20),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Profile section
              Expanded(
                child: switch (userAsync) {
                  AsyncData(:final value) => _buildProfileSection(context, value, activityAsync),
                  AsyncError(:final error) => Text('Error: $error', style: TextStyle(color: theme.colorScheme.error)),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileSection(BuildContext context, User? user, AsyncValue<Map<DateTime, String>> activityAsync) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile card
        Center(
          child: Column(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorScheme.primary, colorScheme.primaryContainer],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 3),
                      ),
                      child: Icon(Icons.edit, color: colorScheme.onPrimary, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                user?.name ?? 'Athlete',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Analytics Button
        Center(
          child: TextButton.icon(
            onPressed: () => context.push(AppRoute.userAnalytics.path),
            icon: Icon(Icons.analytics_outlined, size: 20, color: colorScheme.primary),
            label: Text(
              'VIEW ANALYTICS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 1.0,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final workloadAsync = ref.watch(muscleWorkloadProvider);
              return workloadAsync.when(
                data: (_) => ThreeDManWidget(
                  heroTag: 'profile-model',
                  focusMuscle: _focusedMuscle,
                  onMuscleTap: (muscle) {
                    setState(() {
                      if (_focusedMuscle == muscle) {
                        _focusedMuscle = null;
                      } else {
                        _focusedMuscle = muscle;
                      }
                    });
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(child: Text("Error loading status")),
              );
            },
          ),
        ),
      ],
    );
  }
  
}
