import 'package:drift/drift.dart';
import 'app_database.dart';

Future<void> seedDatabase(AppDatabase db) async {
  // 1. Create User
  await db.saveUser(UsersCompanion(
    name: const Value('ABISIN RAJ'),
    heightCm: const Value(174.0),
    weightKg: const Value(65.0),
    goal: const Value('Be fit'),
    splitDays: const Value(7),
  ));

  // 2. Clear existing workouts (optional, but safe for a clean seed)
  // We assume the db is empty or we are ok appending. 
  // Given the "clear data" command, it should be empty.

  // 3. Define Workouts and Exercises
  final workouts = [
    _WorkoutData(
      name: 'Upper Body Push',
      shortCode: 'M',
      description: 'Monday - Push focus',
      thumbnailUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=1000&q=80',
      clockType: ClockType.none,
      exercises: [
        _ExerciseData('Push-ups', 3, 12, '8-12 reps'),
        _ExerciseData('Pike push-ups', 3, 10, '6-10 reps'),
        _ExerciseData('Tricep dips (chair/bench)', 3, 12, '8-12 reps'),
        _ExerciseData('Plank hold (45s)', 3, 1, '45 seconds'),
      ],
    ),
    _WorkoutData(
      name: 'Boxing Basics',
      shortCode: 'T',
      description: 'Tuesday - Boxing drills',
      thumbnailUrl: 'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff?auto=format&fit=crop&w=1000&q=80', // Core/Home
      clockType: ClockType.none,
      exercises: [
        _ExerciseData('Jump rope (2 mins)', 3, 1, '2 mins'),
        _ExerciseData('Shadow boxing (3 mins)', 3, 1, 'Jab, Cross, Hook'),
        _ExerciseData('Stance & Footwork', 1, 10, '10 minutes'), // 1 set of 10 "reps" (minutes)
        _ExerciseData('Combo: Jab-Cross', 3, 1, '2 mins'),
      ],
    ),
    _WorkoutData(
      name: 'Lower Body',
      shortCode: 'W',
      description: 'Wednesday - Legs',
      thumbnailUrl: 'https://images.unsplash.com/photo-1434608519344-49d77a699ded?auto=format&fit=crop&w=1000&q=80',
      clockType: ClockType.none,
      exercises: [
        _ExerciseData('Bodyweight squats', 3, 15, '12-15 reps'),
        _ExerciseData('Lunges', 3, 10, 'Per leg'),
        _ExerciseData('Glute bridges', 3, 15, '12-15 reps'),
        _ExerciseData('Calf raises', 3, 20, '15-20 reps'),
      ],
    ),
    _WorkoutData(
      name: 'Upper Body Pull',
      shortCode: 'T',
      description: 'Thursday - Pull focus',
      thumbnailUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=1000&q=80',
      clockType: ClockType.none,
      exercises: [
        _ExerciseData('Australian pull-ups', 3, 12, '8-12 reps'),
        _ExerciseData('Inverted rows', 3, 10, '6-10 reps'),
        _ExerciseData('Superman holds (30s)', 3, 1, '20-30 seconds'),
        _ExerciseData('Dead hangs (30s)', 3, 1, '20-30 seconds'),
      ],
    ),
    _WorkoutData(
      name: 'Boxing Basics',
      shortCode: 'F',
      description: 'Friday - Boxing drills',
      thumbnailUrl: 'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff?auto=format&fit=crop&w=1000&q=80',
      clockType: ClockType.none,
      exercises: [
        _ExerciseData('Jump rope (2 mins)', 3, 1, '2 mins'),
        _ExerciseData('Heavy bag/Shadow (3 mins)', 4, 1, '3 mins'),
        _ExerciseData('Slip and roll drills', 1, 10, '10 minutes'),
        _ExerciseData('Sit-ups', 3, 20, 'Core'),
        _ExerciseData('Russian twists', 3, 20, 'Core'),
      ],
    ),
    _WorkoutData(
      name: 'Full Body',
      shortCode: 'S',
      description: 'Saturday - HIIT style',
      thumbnailUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=1000&q=80',
      clockType: ClockType.none,
      exercises: [
        _ExerciseData('Burpees', 3, 10, '8-10 reps'),
        _ExerciseData('Mountain climbers', 3, 20, 'Reps'),
        _ExerciseData('Bodyweight squats', 3, 12, 'Reps'),
        _ExerciseData('Push-ups', 3, 10, 'Reps'),
        _ExerciseData('Plank (45s)', 3, 1, '45 seconds'),
      ],
    ),
    _WorkoutData(
      name: 'Conditioning & Core',
      shortCode: 'S',
      description: 'Sunday - Active recovery',
      thumbnailUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=1000&q=80',
      clockType: ClockType.none,
      exercises: [
        _ExerciseData('Jump rope (3 mins)', 4, 1, '1 min rest'),
        _ExerciseData('Burpees', 3, 12, '10-12 reps'),
        _ExerciseData('Mountain climbers (30s)', 3, 1, '30 seconds'),
        _ExerciseData('Plank to Down Dog', 3, 10, 'Reps'),
        _ExerciseData('Bicycle crunches', 3, 20, 'Reps'),
        _ExerciseData('Leg raises', 3, 12, '10-12 reps'),
        _ExerciseData('Flutter kicks (30s)', 3, 1, '30 seconds'),
      ],
    ),
  ];

  for (var i = 0; i < workouts.length; i++) {
    final w = workouts[i];
    final workoutId = await db.addWorkout(WorkoutsCompanion(
      name: Value(w.name),
      shortCode: Value(w.shortCode),
      description: Value(w.description),
      thumbnailUrl: Value(w.thumbnailUrl),
      orderIndex: Value(i),
      clockType: Value(w.clockType),
    ));
    
    for (var j = 0; j < w.exercises.length; j++) {
      final e = w.exercises[j];
      final displayName = e.note != null ? '${e.name} (${e.note})' : e.name;
      
      await db.addExercise(ExercisesCompanion(
        workoutId: Value(workoutId),
        name: Value(displayName),
        sets: Value(e.sets),
        reps: Value(e.reps),
        orderIndex: Value(j),
      ));
    }
  }
}

class _WorkoutData {
  final String name;
  final String shortCode;
  final String description;
  final String thumbnailUrl;
  final ClockType clockType;
  final List<_ExerciseData> exercises;

  _WorkoutData({
    required this.name,
    required this.shortCode,
    required this.description,
    required this.thumbnailUrl,
    required this.clockType,
    required this.exercises,
  });
}

class _ExerciseData {
  final String name;
  final int sets;
  final int reps;
  final String? note;

  _ExerciseData(this.name, this.sets, this.reps, [this.note]);
}
