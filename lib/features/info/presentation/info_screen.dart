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
class InfoScreen extends ConsumerWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final activityAsync = ref.watch(activityGridProvider(365));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
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
    
    final activeDays = switch (activityAsync) {
      AsyncData(:final value) => value.length,
      _ => 0,
    };
    
    final joinDate = user?.createdAt ?? DateTime.now();
    final joinYear = joinDate.year;
    
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
              // Joined date only (Badge removed per request)
              Text(
                'Joined $joinYear',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Stats row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn(context, '$activeDays', 'WORKOUTS'),
              _buildDivider(context),
              _buildStatColumn(context, '${(activeDays * 0.75).toInt()}h', 'ACTIVE'),
              _buildDivider(context),
              _buildStatColumn(context, '${activeDays * 85}', 'CALORIES'),
            ],
          ),
        ),
        
        // 3D Muscle Status (Particle Man) - Fixed Layout
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final workloadAsync = ref.watch(muscleWorkloadProvider);
              return workloadAsync.when(
                data: (_) => const ThreeDManWidget(),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(child: Text("Error loading status")),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatColumn(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
