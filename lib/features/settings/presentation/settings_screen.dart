import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/widget_service.dart';
import '../../../core/providers/health_connect_provider.dart';
import '../../../core/providers/database_providers.dart';

import 'dart:convert';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';


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
           final currentThemeAsync = ref.read(widgetThemeProvider); // Read once for init
           final initialTheme = currentThemeAsync.valueOrNull ?? 'classic';
           
           return _WidgetThemeSelectorDialog(initialTheme: initialTheme);
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
                       _buildThemeOption(context, ref, 'OLED Black (Default)', 'black', current, isAppTheme: true),
                       const SizedBox(height: 12),
                       _buildThemeOption(context, ref, 'Teal', 'teal', current, isAppTheme: true),
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
                   _buildSectionHeader(context, 'Preferences'),
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
                   
                   const SizedBox(height: 32),
                   _buildSectionHeader(context, 'Appearance'),
                   const SizedBox(height: 16),
                     _buildSettingsTile(
                        context: context,
                        icon: Icons.palette_outlined,
                        iconColor: Colors.purpleAccent,
                        title: 'App Theme',
                        subtitle: 'Colors & Dark Mode',
                        onTap: () => _showAppThemeSelector(context),
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
                      icon: Icons.view_in_ar_rounded,
                      iconColor: Colors.blueAccent,
                      title: '3D Model Rotation',
                      subtitle: 'Restrict movement',
                      onTap: () => _showModelRotationSelector(context),
                    ),

                   const SizedBox(height: 32),
                   _buildSectionHeader(context, 'Integrations'),
                   const SizedBox(height: 16),
                   _buildSettingsTile(
                     context: context,
                     icon: Icons.monitor_heart_outlined,
                     iconColor: Colors.redAccent,
                     title: 'Health Connect',
                     subtitle: 'Sync Fit/Samsung Health',
                     onTap: () => ref.read(healthNotifierProvider.notifier).requestPermissions(),
                   ),
                   const SizedBox(height: 12),
                   _buildSettingsTile(
                     context: context,
                     icon: Icons.api_rounded,
                     iconColor: Colors.indigoAccent,
                     title: 'API Settings',
                     subtitle: 'Gemini, Pexels, OpenAI',
                     onTap: () => context.push(AppRoute.apiSettings.path),
                   ),

                   const SizedBox(height: 32),
                   _buildSectionHeader(context, 'Data Management'),
                   const SizedBox(height: 16),
                   
                   // Google Drive Sync card (Moved from Profile)
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: colorScheme.surfaceContainer,
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
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
                                           color: Colors.green,
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
                             label: const Text('Manual Backup Now'),
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
                   
                   const SizedBox(height: 16),
                   _buildSettingsTile(
                     context: context,
                     icon: Icons.upload_file,
                     iconColor: Colors.blue,
                     title: 'Export to JSON',
                     subtitle: 'Local backup file',
                     onTap: _exportData,
                   ),
                   const SizedBox(height: 12),
                   _buildSettingsTile(
                     context: context,
                     icon: Icons.download,
                     iconColor: Colors.green,
                     title: 'Restore from JSON',
                     subtitle: 'Import backup file',
                     onTap: _restoreData,
                   ),

                   const SizedBox(height: 32),
                   _buildSectionHeader(context, 'Advanced'),
                   const SizedBox(height: 16),
                   _buildSettingsTile(
                     context: context,
                     icon: Icons.sync_problem,
                     iconColor: Colors.orange,
                     title: 'Force Widget Sync',
                     subtitle: 'Update home screen widget now',
                     onTap: () async {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Syncing widget...')),
                       );
                        ref.invalidate(widgetSyncProvider);
                     },
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
  
  Future<void> _exportData() async {
    try {
      final db = ref.read(appDatabaseProvider);
      
      final workoutsList = await db.select(db.workouts).get();
      final workoutMaps = workoutsList.map((w) => w.toJson()).toList();
      
      final foodList = await db.select(db.foodLogs).get();
      final foodMaps = foodList.map((f) => f.toJson()).toList();
      
      final dump = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'workouts': workoutMaps,
        'foodLogs': foodMaps,
      };
      
      final jsonString = jsonEncode(dump);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/momentum_backup_${DateFormat('yyyyMMdd').format(DateTime.now())}.json');
      await file.writeAsString(jsonString);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Momentum Backup');
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e')));
      }
    }
  }

  Future<void> _restoreData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonString);
        
        final workoutCount = (data['workouts'] as List?)?.length ?? 0;
        final foodCount = (data['foodLogs'] as List?)?.length ?? 0;
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Backup Verified: Found $workoutCount workouts, $foodCount food logs. (Import not active in Demo)')),
           );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore Failed: $e')));
      }
    }
  }

  void _showModelRotationSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
           final rotationModeAsync = ref.watch(modelRotationModeProvider);
           final colorScheme = Theme.of(context).colorScheme;
           
           return Container(
             padding: const EdgeInsets.all(24),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('3D Model Rotation', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
                 const SizedBox(height: 16),
                 rotationModeAsync.when(
                   data: (current) => Column(
                     children: [
                       _buildRotationOption(context, ref, 'Horizontal Only', 'horizontal', current),
                       const SizedBox(height: 12),
                       _buildRotationOption(context, ref, '360 Degree', 'full', current),
                     ],
                   ),
                   loading: () => const Center(child: CircularProgressIndicator()),
                   error: (_, _) => Text('Error loading mode', style: TextStyle(color: colorScheme.error)),
                 ),
                 const SizedBox(height: 16),
               ],
             ),
           );
        },
      ),
    );
  }

  Widget _buildRotationOption(BuildContext context, WidgetRef ref, String label, String value, String current) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = value == current;
    
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        await ref.read(modelRotationModeProvider.notifier).setMode(value);
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
              value == 'horizontal' ? Icons.sync_alt_rounded : Icons.sync_rounded,
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

}

class _WidgetThemeSelectorDialog extends StatefulWidget {
  final String initialTheme;
 
  const _WidgetThemeSelectorDialog({required this.initialTheme});

  @override
  State<_WidgetThemeSelectorDialog> createState() => _WidgetThemeSelectorDialogState();
}

class _WidgetThemeSelectorDialogState extends State<_WidgetThemeSelectorDialog> {
  late String _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.initialTheme;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Widget Theme', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
          const SizedBox(height: 16),
          _buildOption('Classic', 'classic'),
          const SizedBox(height: 12),
          _buildOption('Liquid Glass', 'liquid_glass'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: () async {
                    await ref.read(widgetThemeProvider.notifier).setTheme(_selectedTheme);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                );
              }
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = value == _selectedTheme;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTheme = value;
        });
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
}

