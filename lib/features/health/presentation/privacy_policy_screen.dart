import 'package:flutter/material.dart';

/// Placeholder privacy policy screen required by Google Health Connect.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.privacy_tip_rounded,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Momentum Privacy Policy',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: January 2026',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              title: 'Health Data Collection',
              content:
                  'Momentum accesses health and fitness data through Google Health Connect to provide you with a comprehensive view of your fitness journey. This includes:\n\n'
                  '• Steps count\n'
                  '• Heart rate measurements\n'
                  '• Sleep duration and quality\n'
                  '• Weight records\n'
                  '• Workout sessions\n',
            ),

            _buildSection(
              context,
              title: 'How We Use Your Data',
              content:
                  'Your health data is used solely to:\n\n'
                  '• Display your fitness statistics within the app\n'
                  '• Track your progress over time\n'
                  '• Provide personalized insights\n\n'
                  'Your data is stored locally on your device and is never shared with third parties.',
            ),

            _buildSection(
              context,
              title: 'Data Storage',
              content:
                  'Momentum is an offline-first application. Your health data synced from Health Connect is stored locally on your device. We do not upload your health data to any external servers.',
            ),

            _buildSection(
              context,
              title: 'Your Control',
              content:
                  'You can revoke Momentum\'s access to your health data at any time through:\n\n'
                  '• Android Settings > Health Connect > Momentum > Permissions\n'
                  '• The Momentum app Settings screen\n\n'
                  'Revoking access will stop new data from being synced, but previously synced data will remain in the app until you clear app data.',
            ),

            _buildSection(
              context,
              title: 'Contact Us',
              content:
                  'If you have any questions about this privacy policy or our health data practices, please contact us at:\n\n'
                  'support@momentum-app.com',
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                '© 2026 Momentum. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required String content}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
