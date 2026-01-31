import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/workout_progression.dart';
import 'database_providers.dart';

part 'workout_progression_provider.g.dart';

@riverpod
Future<WorkoutProgression> workoutProgression(Ref ref) async {
  final user = await ref.watch(currentUserProvider.future);
  final allWorkouts = await ref.watch(workoutsStreamProvider.future);
  final todayCompletedIds = await ref.watch(todayCompletedWorkoutIdsProvider.future);

  if (user == null || allWorkouts.isEmpty) {
    return WorkoutProgression(
      splitIndex: 0,
      todayWorkouts: [],
      tomorrowWorkouts: [],
      isCompletedToday: false,
    );
  }

  final splitDays = user.splitDays ?? allWorkouts.length;
  final currentIndex = user.currentSplitIndex;

  // 1. Check if we advanced TODAY
  // We check if we completed any workout from the "previous" split index today
  final previousIndex = (currentIndex - 1 + splitDays) % splitDays;
  final completedPreviousToday = allWorkouts.where((w) => 
    w.orderIndex == previousIndex && todayCompletedIds.contains(w.id)
  ).isNotEmpty;

  // 2. Determine Effective State
  int effectiveIndex;
  bool isCompletedToday;

  if (completedPreviousToday) {
    // We stay "stuck" on the previous day to show it as completed
    effectiveIndex = previousIndex;
    isCompletedToday = true;
  } else {
    effectiveIndex = currentIndex;
    // Even if we haven't advanced yet, maybe we finished some of today's workouts?
    // "isCompletedToday" specifically means "Did we finish the split day's requirements?"
    final todaysWorkouts = allWorkouts.where((w) => w.orderIndex == effectiveIndex).toList();
    isCompletedToday = todaysWorkouts.isNotEmpty && 
                     todaysWorkouts.every((w) => todayCompletedIds.contains(w.id));
  }

  final todayWorkouts = allWorkouts.where((w) => w.orderIndex == effectiveIndex).toList();
  final nextIndex = (effectiveIndex + 1) % splitDays;
  final tomorrowWorkouts = allWorkouts.where((w) => w.orderIndex == nextIndex).toList();

  return WorkoutProgression(
    splitIndex: effectiveIndex,
    todayWorkouts: todayWorkouts,
    tomorrowWorkouts: tomorrowWorkouts,
    isCompletedToday: isCompletedToday,
  );
}
