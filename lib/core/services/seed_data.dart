import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Seed data service for populating the database with demo data
class SeedDataService {
  final AppDatabase db;
  
  SeedDataService(this.db);
  
  /// Seeds the database with demo data for "Abisin Raj"
  /// Includes user profile, 3-day Push/Pull/Legs split, and session history
  Future<void> seedAll() async {
    await seedUser();
    await seedWorkouts();
    await seedSessionHistory();
  }
  
  /// Seed user profile
  Future<void> seedUser() async {
    final existingUser = await db.getUser();
    if (existingUser != null) return; // Don't overwrite
    
    await db.saveUser(UsersCompanion.insert(
      name: 'Abisin Raj',
      age: const Value(24),
      heightCm: const Value(175.0),
      weightKg: const Value(72.0),
      goal: const Value('Build Muscle'),
      splitDays: const Value(3),
      currentSplitIndex: const Value(0),
    ));
  }
  
  /// Seed workouts with exercises
  Future<void> seedWorkouts() async {
    final existing = await db.getAllWorkouts();
    if (existing.isNotEmpty) return; // Don't overwrite
    
    // Push Day
    final pushId = await db.addWorkout(WorkoutsCompanion.insert(
      name: 'Push Day',
      shortCode: 'P',
      orderIndex: 0,
      description: const Value('Chest, Shoulders & Triceps'),
      thumbnailUrl: const Value('https://images.pexels.com/photos/3837757/pexels-photo-3837757.jpeg?auto=compress&cs=tinysrgb&w=400'),
      clockType: const Value(ClockType.none),
    ));
    
    await _addExercises(pushId, [
      ('Bench Press', 4, 10),
      ('Incline Dumbbell Press', 3, 12),
      ('Overhead Press', 3, 10),
      ('Lateral Raises', 3, 15),
      ('Tricep Pushdowns', 3, 12),
      ('Dips', 3, 10),
    ]);
    
    // Pull Day
    final pullId = await db.addWorkout(WorkoutsCompanion.insert(
      name: 'Pull Day',
      shortCode: 'L',
      orderIndex: 1,
      description: const Value('Back & Biceps'),
      thumbnailUrl: const Value('https://images.pexels.com/photos/4164761/pexels-photo-4164761.jpeg?auto=compress&cs=tinysrgb&w=400'),
      clockType: const Value(ClockType.none),
    ));
    
    await _addExercises(pullId, [
      ('Pull-ups', 4, 8),
      ('Barbell Rows', 4, 10),
      ('Lat Pulldowns', 3, 12),
      ('Face Pulls', 3, 15),
      ('Barbell Curls', 3, 12),
      ('Hammer Curls', 3, 12),
    ]);
    
    // Leg Day
    final legId = await db.addWorkout(WorkoutsCompanion.insert(
      name: 'Leg Day',
      shortCode: 'G',
      orderIndex: 2,
      description: const Value('Quads, Hamstrings & Calves'),
      thumbnailUrl: const Value('https://images.pexels.com/photos/1552242/pexels-photo-1552242.jpeg?auto=compress&cs=tinysrgb&w=400'),
      clockType: const Value(ClockType.none),
    ));
    
    await _addExercises(legId, [
      ('Squats', 4, 10),
      ('Romanian Deadlifts', 4, 10),
      ('Leg Press', 3, 12),
      ('Leg Curls', 3, 12),
      ('Calf Raises', 4, 15),
      ('Lunges', 3, 12),
    ]);
  }
  
  Future<void> _addExercises(int workoutId, List<(String, int, int)> exercises) async {
    for (int i = 0; i < exercises.length; i++) {
      final (name, sets, reps) = exercises[i];
      await db.addExercise(ExercisesCompanion.insert(
        workoutId: workoutId,
        name: name,
        sets: Value(sets),
        reps: Value(reps),
        orderIndex: i,
      ));
    }
  }
  
  /// Seed session history for the past 14 days
  Future<void> seedSessionHistory() async {
    final workouts = await db.getAllWorkouts();
    if (workouts.isEmpty) return;
    
    // Check if we already have sessions
    final existingSessions = await db.getActivityGrid(30);
    if (existingSessions.isNotEmpty) return;
    
    final now = DateTime.now();
    
    // Create sessions for the past 14 days (alternating workouts)
    for (int i = 14; i >= 1; i--) {
      // Skip some days to simulate rest days
      if (i % 4 == 0) continue; // Skip every 4th day
      
      final sessionDate = now.subtract(Duration(days: i));
      final workoutIndex = i % workouts.length;
      final workout = workouts[workoutIndex];
      
      // Create session
      final sessionId = await db.into(db.sessions).insert(SessionsCompanion.insert(
        workoutId: workout.id,
        startedAt: sessionDate,
        completedAt: Value(sessionDate.add(Duration(minutes: 45 + (i % 20)))),
        durationSeconds: Value((45 + (i % 20)) * 60),
      ));
      
      // Add exercise completion data
      final exercises = await db.getExercisesForWorkout(workout.id);
      for (final ex in exercises) {
        await db.saveSessionExercise(SessionExercisesCompanion.insert(
          sessionId: sessionId,
          exerciseId: ex.id,
          completedSets: Value(ex.sets),
          completedReps: Value(ex.sets * ex.reps),
        ));
      }
    }
  }
}
