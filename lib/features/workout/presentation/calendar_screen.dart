
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/database_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final offset = firstDayOfMonth.weekday - 1; // 0 for Mon, 6 for Sun

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => setState(() => _focusedDay = DateTime.now()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedDay),
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Days of Week
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day, 
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.8,
              ),
              itemCount: daysInMonth + offset,
              itemBuilder: (context, index) {
                if (index < offset) return const SizedBox.shrink();
                
                final dayNum = index - offset + 1;
                final date = DateTime(_focusedDay.year, _focusedDay.month, dayNum);
                return _buildDayCell(date, theme);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDayCell(DateTime date, ThemeData theme) {
    // Determine state: Past (History), Today, Future (Projection)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cellDate = DateTime(date.year, date.month, date.day);
    
    final isToday = cellDate == today;
    final isPast = cellDate.isBefore(today);
    
    return FutureBuilder(
      future: _getDataForDate(cellDate, isPast),
      builder: (context, snapshot) {
        final data = snapshot.data;
        // Data format: { 'type': 'history'|'projected', 'label': 'A', 'color': Color }
        
        Color bgColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
        Color textColor = theme.colorScheme.onSurface;
        String? label;
        
        if (isToday) {
           bgColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.5);
        }

        if (snapshot.hasData && data != null) {
           if (data['type'] == 'history') {
             bgColor = Colors.green.withValues(alpha: 0.2);
             textColor = Colors.green;
             label = data['label'];
           } else if (data['type'] == 'projected') {
             label = data['label'];
             bgColor = theme.colorScheme.secondaryContainer.withValues(alpha: 0.2);
             textColor = theme.colorScheme.secondary;
           }
        }

        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: isToday ? Border.all(color: theme.colorScheme.primary) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${date.day}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              if (label != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: textColor.withValues(alpha: 0.2),
                  ),
                  child: Text(
                     label, 
                     style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)
                  ),
                ),
              ]
            ],
          ),
        );
      },
    );
  }
  
  get day => null; // Wait, used 'day' variable in build but it's not defined in _buildDayCell's simple scope properly if reused. Fixed below.
  
  // ignore: unused_element
  Future<Map<String, dynamic>?> _getDataForDate(DateTime date, bool isPast) async {
     final db = ref.read(appDatabaseProvider);
     
     if (isPast || DateUtils.isSameDay(date, DateTime.now())) {
        // Check history
        final sessions = await db.getSessionsForDate(date);
        final completed = sessions.where((s) => s.completedAt != null).toList();
        if (completed.isNotEmpty) {
           // Get workout short code
           final workout = await db.getWorkout(completed.first.workoutId);
           return {
             'type': 'history',
             'label': workout?.shortCode ?? '?',
           };
        }
     }
     
     if (!isPast) {
        // Future: Check Projection (Only for next 7-14 days to avoid expensive calc loop?)
        // Or cleaner: Check if this date matches a projected date for any workout.
        // Actually, current `getProjectedDate` gives the *next* date for a workout.
        // A full calendar projection requires iterating the cycle day-by-day.
        // Simplified Logic: 
        // 1. Get current cycle index.
        // 2. Get days diff between Now and Date.
        // 3. (Current + Diff) % SplitDays = Index for that day.
        // 4. Find workout with that index.
        
        final user = await ref.read(currentUserProvider.future);
        if (user != null) {
           final now = DateTime.now();
           final today = DateTime(now.year, now.month, now.day);
           final diff = date.difference(today).inDays;
           if (diff > 0 && diff < 30) { // Limit projection to 30 days
              final splitDays = user.splitDays ?? 7;
              final projectedIndex = (user.currentSplitIndex + diff) % splitDays;
              
              final workouts = await db.getAllWorkouts();
              try {
                final workout = workouts.firstWhere((w) => w.orderIndex == projectedIndex);
                if (workout.isRestDay) {
                   return {'type': 'projected', 'label': 'R'};
                }
                return {'type': 'projected', 'label': workout.shortCode};
              } catch (_) {
                 return null; // Empty day
              }
           }
        }
     }
     
     return null;
  }
}
