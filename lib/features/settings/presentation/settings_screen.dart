import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/settings_service.dart';

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
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
           final currentThemeAsync = ref.watch(widgetThemeProvider);
           
           return Container(
             padding: const EdgeInsets.all(24),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('Widget Theme', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
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
                   error: (_, _) => const Text('Error loading settings', style: TextStyle(color: Colors.red)),
                 ),
                 const SizedBox(height: 16),
               ],
             ),
           );
        },
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, WidgetRef ref, String label, String value, String current) {
    final isSelected = value == current;
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        await ref.read(widgetThemeProvider.notifier).setTheme(value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.tealPrimary.withValues(alpha: 0.1) : AppTheme.darkSurfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.tealPrimary : Colors.transparent, 
            width: 2
          ),
        ),
        child: Row(
          children: [
            Icon(
              value == 'liquid_glass' ? Icons.water_drop_outlined : Icons.dashboard_outlined,
              color: isSelected ? AppTheme.tealPrimary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.tealPrimary : AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            if (isSelected) 
              Icon(Icons.check_circle, color: AppTheme.tealPrimary),
          ],
        ),
      ),
    );
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
      body: SingleChildScrollView(
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
                     title: 'Widget Theme',
                     subtitle: 'Liquid Glass & More',
                     onTap: () => _showWidgetThemeSelector(context),
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
                   // Duplicate "Home Screen Widget" removed from here
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

                   const SizedBox(height: 12),
                   _buildSettingsTile(
                     icon: Icons.api_rounded,
                     iconColor: Colors.orangeAccent,
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
  

}

