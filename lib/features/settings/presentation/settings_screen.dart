import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/providers/health_connect_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  @override
  void initState() {
    super.initState();
    // No keys to load here anymore
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showWidgetThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
           final currentThemeAsync = ref.watch(widgetThemeProvider);
           final colorScheme = Theme.of(context).colorScheme;
           
           return Container(
             padding: const EdgeInsets.all(24),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('Widget Theme', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
                 const SizedBox(height: 16),
                 currentThemeAsync.when(
                   data: (current) => Column(
                     children: [
                       _buildThemeOption(context, ref, 'Classic', 'classic', current),
                       const SizedBox(height: 12),
                       _buildThemeOption(context, ref, 'Liquid Glass', 'liquid_glass', current),
                     ],
                   ),
                   loading: () => const Center(child: CircularProgressIndicator()),
                   error: (_, _) => Text('Error loading settings', style: TextStyle(color: colorScheme.error)),
                 ),
                 const SizedBox(height: 16),
               ],
             ),
           );
        },
      ),
    );
  }

  void _showAppThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
           final currentThemeAsync = ref.watch(appThemeModeProvider);
           final colorScheme = Theme.of(context).colorScheme;
           
           return Container(
             padding: const EdgeInsets.all(24),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('App Interface Theme', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
                 const SizedBox(height: 16),
                 currentThemeAsync.when(
                   data: (current) => Column(
                     children: [
                       _buildThemeOption(context, ref, 'Teal (Default)', 'teal', current, isAppTheme: true),
                       const SizedBox(height: 12),
                       _buildThemeOption(context, ref, 'Cyber Yellow', 'yellow', current, isAppTheme: true),
                       const SizedBox(height: 12),
                       _buildThemeOption(context, ref, 'Crimson Red', 'red', current, isAppTheme: true),
                       const SizedBox(height: 12),
                       _buildThemeOption(context, ref, 'OLED Black', 'black', current, isAppTheme: true),
                     ],
                   ),
                   loading: () => const Center(child: CircularProgressIndicator()),
                   error: (_, _) => Text('Error loading settings', style: TextStyle(color: colorScheme.error)),
                 ),
                 const SizedBox(height: 16),
               ],
             ),
           );
        },
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, WidgetRef ref, String label, String value, String current, {bool isAppTheme = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = value == current;
    
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        if (isAppTheme) {
          await ref.read(appThemeModeProvider.notifier).setTheme(value);
        } else {
          await ref.read(widgetThemeProvider.notifier).setTheme(value);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent, 
            width: 2
          ),
        ),
        child: Row(
          children: [
            Icon(
              value == 'liquid_glass' ? Icons.water_drop_outlined : Icons.dashboard_outlined,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected) 
              Icon(Icons.check_circle, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSectionHeader(context, 'General'),
                   const SizedBox(height: 16),
                   
                   _buildSettingsTile(
                     context: context,
                     icon: Icons.tune,
                     iconColor: colorScheme.primary,
                     title: 'Workout Settings',
                     subtitle: 'Timer, units, and preferences',
                     onTap: () => context.push(AppRoute.workoutPreferences.path),
                   ),
                   const SizedBox(height: 12),
                   _buildSettingsTile(
                     context: context,
                     icon: Icons.widgets_outlined,
                     iconColor: colorScheme.tertiary,
                     title: 'Widget Theme',
                     subtitle: 'Liquid Glass & More',
                     onTap: () => _showWidgetThemeSelector(context),
                   ),
                   const SizedBox(height: 12),
                   _buildSettingsTile(
                     context: context,
                     icon: Icons.notifications_outlined,
                     iconColor: colorScheme.secondary,
                     title: 'Notifications',
                     subtitle: 'On',
                     onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('Notification settings coming soon', style: TextStyle(color: colorScheme.onSurface))),
                       );
                     },
                   ),
                   const SizedBox(height: 12),
                   _buildSettingsTile(
                     context: context,
                     icon: Icons.monitor_heart_outlined,
                     iconColor: Colors.redAccent,
                     title: 'Health Connect',
                     subtitle: 'Sync Fit/Samsung Health',
                     onTap: () => ref.read(healthNotifierProvider.notifier).requestPermissions(),
                   ),
                   const SizedBox(height: 12),
                   // Duplicate "Home Screen Widget" removed from here
                   const SizedBox(height: 12),
                    _buildSettingsTile(
                      context: context,
                      icon: Icons.palette_outlined,
                      iconColor: colorScheme.primary,
                      title: 'Appearance',
                      subtitle: 'App Theme',
                      onTap: () => _showAppThemeSelector(context),
                    ),

                   const SizedBox(height: 32),

                   const SizedBox(height: 12),
                   _buildSettingsTile(
                     context: context,
                     icon: Icons.api_rounded,
                     iconColor: colorScheme.error,
                     title: 'API Settings',
                     subtitle: 'Gemini, Pexels, OpenAI',
                     onTap: () => context.push(AppRoute.apiSettings.path),
                   ),
                ],
              ),
            ),
    );
  }


  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
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
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null ? Text(
          subtitle,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ) : null,
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
  

}

