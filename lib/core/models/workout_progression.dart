import 'package:momentum/core/database/app_database.dart';

class WorkoutProgression {
  final int splitIndex;
  final List<Workout> todayWorkouts;
  final List<Workout> tomorrowWorkouts;
  final bool isCompletedToday;
  final DateTime? lastCompletionDate;

  WorkoutProgression({
    required this.splitIndex,
    required this.todayWorkouts,
    required this.tomorrowWorkouts,
    required this.isCompletedToday,
    this.lastCompletionDate,
  });
}
