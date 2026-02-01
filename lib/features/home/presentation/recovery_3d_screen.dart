import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/database_providers.dart';
import 'widgets/three_d_man_widget.dart';

class Recovery3DScreen extends ConsumerStatefulWidget {
  const Recovery3DScreen({super.key});

  @override
  ConsumerState<Recovery3DScreen> createState() => _Recovery3DScreenState();
}

class _Recovery3DScreenState extends ConsumerState<Recovery3DScreen> {
  String? _selectedMuscle;
  Map<String, dynamic>? _currentMuscleStats;
  bool _isLoadingStats = false;

  void _handleMuscleTap(String muscle) {
    if (_selectedMuscle == muscle) {
      // Toggle off (Zoom out)
      setState(() {
        _selectedMuscle = null;
        _currentMuscleStats = null;
        _isLoadingStats = false;
      });
    } else {
      // New Body Part (Zoom in)
      setState(() {
        _selectedMuscle = muscle;
        _currentMuscleStats = null; // Loading state
        _isLoadingStats = true;
      });
      _fetchStats(muscle);
    }
  }

  Future<void> _fetchStats(String muscle) async {
    final db = ref.read(appDatabaseProvider);
    // Simulate slight delay for smooth animation if query is too fast? No, instant is better.
    final stats = await db.getLastSessionForMuscle(muscle);
    
    // Only update if selection hasn't changed during fetch
    if (mounted && _selectedMuscle == muscle) {
      setState(() {
        _currentMuscleStats = stats;
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
             child: ThreeDManWidget(
                height: MediaQuery.of(context).size.height,
                focusMuscle: _selectedMuscle,
                onMuscleTap: _handleMuscleTap,
                heroTag: 'muscle-model',
              ),
          ),
          
          // Custom Back Button Overlay
          Positioned(
            top: 16, // Reduced since we use SafeArea inside Stack or just let it float
            left: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back, color: colorScheme.onSurface, size: 24),
                ),
              ),
            ),
          ),
          
          // Header Overlay
          Positioned(
            top: 24,
            right: 24,
            child: AnimatedOpacity(
              opacity: _selectedMuscle == null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'MUSCLE STATUS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      'LIVE HEATMAP',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Persistent Stats Sheet Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: _selectedMuscle != null ? 0 : -MediaQuery.of(context).size.height * 0.4,
            child: _MuscleStatsSheet(
              muscleName: _selectedMuscle ?? '',
              stats: _currentMuscleStats,
              isLoading: _isLoadingStats,
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleStatsSheet extends StatelessWidget {
  final String muscleName;
  final Map<String, dynamic>? stats;
  final bool isLoading;

  const _MuscleStatsSheet({
    required this.muscleName, 
    this.stats, 
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formatter = NumberFormat.decimalPattern();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.fromBorderSide(BorderSide(color: colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                muscleName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'TARGETED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isLoading)
             Center(child: CircularProgressIndicator(color: colorScheme.primary))
          else if (stats == null)
            _buildEmptyState(context)
          else
            _buildStatsContent(context, formatter),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
         color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
         borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "No recorded workouts targeting $muscleName yet.",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context, NumberFormat formatter) {
    final date = stats!['date'] as DateTime;
    final volume = stats!['volume'] as double;
    final sets = stats!['sets'] as int;
    final timeAgo = DateTime.now().difference(date);
    
    String timeLabel;
    if (timeAgo.inDays == 0) {
      timeLabel = 'Today';
    } else if (timeAgo.inDays == 1) {
      timeLabel = 'Yesterday';
    } else {
      timeLabel = '${timeAgo.inDays} days ago';
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            context,
            'LAST TRAINED',
            timeLabel,
            DateFormat.MMMd().format(date),
            Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            context,
            'VOLUME',
            '${formatter.format(volume.toInt())} kg',
            '$sets Sets',
            Icons.fitness_center,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(BuildContext context, String label, String value, String subValue, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            subValue,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
