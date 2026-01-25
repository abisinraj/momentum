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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Account & Settings',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoute.settings.path),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.settings_outlined, color: colorScheme.primary, size: 20),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Profile section
              switch (userAsync) {
                AsyncData(:final value) => _buildProfileSection(context, value, activityAsync),
                AsyncError(:final error) => Text('Error: $error', style: TextStyle(color: colorScheme.error)),
                _ => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
              },
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
              const SizedBox(height: 4),
              // Badge and join date
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getMembershipBadge(activeDays),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '|',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Joined $joinYear',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
        
        const SizedBox(height: 24),
        
        // 3D Muscle Status (Particle Man)
        Consumer(
          builder: (context, ref, child) {
            final workloadAsync = ref.watch(muscleWorkloadProvider);
            // We load the workload to ensure data is fetched, 
            // but the 3D model is currently a standalone viewer.
            return workloadAsync.when(
              data: (_) => const Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: ThreeDManWidget(height: 500),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            );
          },
        ),
        
        // Data Management section
        _buildSectionLabel(context, 'DATA MANAGEMENT'),
        const SizedBox(height: 12),
        
        // Google Drive Sync card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.network(
                      'https://www.gstatic.com/images/branding/product/2x/drive_2020q4_48dp.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.cloud_outlined,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Drive Sync',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.green, // Keep semantic green for "Success/Secure"
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Data secure',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Last backup: Today, 08:00 AM',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Google Drive backup coming soon!'),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    );
                  },
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('Manual Backup'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Footer
        Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFooterLink(context, 'Privacy Policy'),
                  _buildFooterDot(context),
                  _buildFooterLink(context, 'Terms of Service'),
                  _buildFooterDot(context),
                  _buildFooterLink(context, 'Support'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'v2.4.0 (Build 002)',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildFooterLink(BuildContext context, String text) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
  
  Widget _buildFooterDot(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '•',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
  
  String _getMembershipBadge(int workouts) {
    if (workouts >= 100) return 'MOMENTUM LEGEND';
    if (workouts >= 50) return 'MOMENTUM ELITE';
    if (workouts >= 20) return 'MOMENTUM PRO';
    if (workouts >= 5) return 'MOMENTUM STARTER';
    return 'MOMENTUM MEMBER';
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.0,
      ),
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
