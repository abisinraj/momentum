import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/providers/workout_providers.dart';
import '../../../core/services/thumbnail_service.dart';

/// Screen to create a workout as part of a split
/// Flow: Name -> Thumbnail -> Exercises -> Clock
class CreateWorkoutScreen extends ConsumerStatefulWidget {
  final int index; // 1-based index
  final int totalDays;
  final Workout? existingWorkout; // NEW: Optional workout to edit
  final bool isStandalone;

  const CreateWorkoutScreen({
    super.key,
    required this.index,
    required this.totalDays,
    this.existingWorkout,
    this.isStandalone = false,
  });

  @override
  ConsumerState<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends ConsumerState<CreateWorkoutScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  
  late int _selectedSplitIndex; // 0-based index
  int _currentStep = 0;
  String? _selectedThumbnail;
  String _searchQuery = '';
  ClockType _selectedClock = ClockType.stopwatch;
  bool _isSaving = false;
  bool _isLoading = false; // To show loading spinner during exercise fetch
  bool _isRestDay = false; // New toggle
  final List<({String name, int sets, int reps})> _exercises = [];

  
  // Exercise inputs
  final _exNameController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _selectedSplitIndex = widget.index - 1; // Default to passed index (0-based)
    if (widget.existingWorkout != null) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    
    try {
      final w = widget.existingWorkout!;
      _nameController.text = w.name;
      _selectedThumbnail = w.thumbnailUrl;
      _selectedClock = w.clockType;
      _isRestDay = w.isRestDay;

      
      // Fetch exercises
      final db = ref.read(appDatabaseProvider);
      final exercises = await db.getExercisesForWorkout(w.id);
      
      if (mounted) {
        setState(() {
          for (var e in exercises) {
            _exercises.add((name: e.name, sets: e.sets, reps: e.reps));
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading workout data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }


    return Scaffold(
      backgroundColor: colorScheme.surface,

      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.existingWorkout != null ? 'Edit Workout' : 'Workout ${widget.index} of ${widget.totalDays}'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / (_isRestDay ? 1 : 4),
            backgroundColor: colorScheme.surfaceContainerHighest,

            color: colorScheme.primary,
          ),

          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildNameStep(),
                _buildThumbnailStep(),
                _buildExercisesStep(),
                _buildNameStep(),
                if (!_isRestDay) _buildThumbnailStep(),
                if (!_isRestDay) _buildExercisesStep(),
                if (!_isRestDay) _buildClockStep(),
              ],
            ),

          ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentStep == 0)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ),
                  
                if (_currentStep > 0)
                  TextButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                    child: Text('Back', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ),


                const Spacer(),
                FilledButton(
                  onPressed: (_canProceed() && !_isSaving) ? _nextStep : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    disabledBackgroundColor: colorScheme.surfaceContainer,
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )

                      : Text(
                          _currentStep == (_isRestDay ? 0 : 3) 
 
                              ? (widget.existingWorkout != null ? 'Save Changes' : (widget.isStandalone ? 'Create Workout' : (widget.index < widget.totalDays ? 'Next Workout' : 'Finish Split')))
                              : 'Continue',
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: return _nameController.text.trim().isNotEmpty && _nameController.text.length <= 50;
      case 1: return _selectedThumbnail != null;
      case 2: return _exercises.isNotEmpty;
      case 3: return true;
      default: return false;
    }
  }

  void _nextStep() async {
    // If rest day, we only have step 0 (Name), so we finish immediately if valid
    if (_isRestDay && _currentStep == 0) {
      // Proceed to save
    } else if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      // Save and proceed
      if (widget.existingWorkout != null) {
        await _updateWorkout();
      } else {
        await _saveWorkout();
      }
      
      if (!mounted) return;
      
      if (widget.existingWorkout != null) {
        // Just pop if editing
        Navigator.of(context).pop();
      } else if (!widget.isStandalone && widget.index < widget.totalDays) {
        // Go to next workout creation
        context.push('/create-workout/${widget.index + 1}/${widget.totalDays}');
      } else {
        // Finish split setup OR Standalone creation
        if (widget.isStandalone) {
            Navigator.of(context).pop();
            return;
        }

        // Update user split days
        final db = ref.read(appDatabaseProvider);
        final user = await db.getUser();
        if (user != null) {
          await db.saveUser(user.toCompanion(true).copyWith(
            splitDays: drift.Value(widget.totalDays),
          ));
        }
        
        // Invalidate setup check to allow router to redirect to Home
        ref.invalidate(isSetupCompleteProvider);
        
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e, st) {
      if (mounted) {
        // Check for drift InvalidDataException specifically
        final errorMessage = e.toString();
        String userMessage = 'Error saving workout';
        
        if (errorMessage.contains('InvalidDataException') && errorMessage.contains('name: Must at most be 100 characters')) {
          userMessage = 'Name is too long (max 50 characters)';
        } else {
            userMessage = 'Error saving: ${e.toString().split('\n').first}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.red,
          ),
        );
        debugPrint('Error saving workout: $e\n$st');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateWorkout() async {
    final db = ref.read(appDatabaseProvider);
    final w = widget.existingWorkout!;
    
    // Update workout details
    await db.updateWorkout(w.toCompanion(true).copyWith(
      name: drift.Value(_nameController.text.trim()),
      shortCode: drift.Value(_isRestDay ? 'R' : _nameController.text.trim()[0].toUpperCase()),
      thumbnailUrl: drift.Value(_isRestDay ? 'assets/images/rest_day.jpg' : _selectedThumbnail),
      clockType: drift.Value(_isRestDay ? ClockType.none : _selectedClock),
      isRestDay: drift.Value(_isRestDay),
    ));
    
    // Replace exercises (Delete all + Re-insert)
    await db.deleteExercisesForWorkout(w.id);
    
    if (!_isRestDay) {
      for (int i = 0; i < _exercises.length; i++) {
        final ex = _exercises[i];
        await db.addExercise(
          ExercisesCompanion(
            workoutId: drift.Value(w.id),
            name: drift.Value(ex.name),
            sets: drift.Value(ex.sets),
            reps: drift.Value(ex.reps),
            orderIndex: drift.Value(i),
          ),
        );
      }
    }
      
    // Refresh workout list
    ref.invalidate(workoutsStreamProvider);
  }

  Future<void> _saveWorkout() async {
    final db = ref.read(appDatabaseProvider);
    // Note: WorkoutManager provides a convenient wrapper but we use db directly for now
    final _ = ref.read(workoutManagerProvider.notifier);
    
    // Create workout
    final workoutId = await db.addWorkout(
      WorkoutsCompanion(
        name: drift.Value(_nameController.text.trim()),
        shortCode: drift.Value(_isRestDay ? 'R' : _nameController.text.trim()[0].toUpperCase()),
        thumbnailUrl: drift.Value(_isRestDay ? 'assets/images/rest_day.jpg' : _selectedThumbnail),
        orderIndex: drift.Value(_selectedSplitIndex), // Use selected index
        clockType: drift.Value(_isRestDay ? ClockType.none : _selectedClock),
        isRestDay: drift.Value(_isRestDay),
      ),
    );
    
    // Add exercises
    if (!_isRestDay) {
      for (int i = 0; i < _exercises.length; i++) {
        final ex = _exercises[i];
        await db.addExercise(
          ExercisesCompanion(
            workoutId: drift.Value(workoutId),
            name: drift.Value(ex.name),
            sets: drift.Value(ex.sets),
            reps: drift.Value(ex.reps),
            orderIndex: drift.Value(i),
          ),
        );
      }
    }
    
    // Refresh workout list
    ref.invalidate(workoutsStreamProvider);
  }

  // STEP 1: Name
  Widget _buildNameStep() {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(

      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'What\'s this workout called?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),
                
                // Toggle Type
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTypeToggle('Workout', false, colorScheme),
                      _buildTypeToggle('Rest Day', true, colorScheme),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                TextField(
                  controller: _nameController,
                  style: TextStyle(fontSize: 24, color: colorScheme.onSurface),
                  textAlign: TextAlign.center,
                  maxLength: 50, // Prevent database overflow (Drift limit is 100, we stay safer)
                  decoration: InputDecoration(
                    hintText: 'e.g., Pull Day',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                    border: InputBorder.none,
                    counterText: "", // Hide character counter for cleaner look
                  ),

                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                ),
                
                if (widget.isStandalone) ...[
                  const SizedBox(height: 48),
                  Text(
                    'ASSIGN TO DAY',
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      color: colorScheme.primary, 
                      letterSpacing: 1.2
                    ),
                  ),

                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: List.generate(widget.totalDays, (index) {
                      final isSelected = _selectedSplitIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSplitIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? colorScheme.primary : colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                              width: 1,
                            ),
                          ),

                          child: Text(
                            'Day ${index + 1}',
                            style: TextStyle(
                              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeToggle(String label, bool value, ColorScheme colorScheme) {
    final isSelected = _isRestDay == value;
    return GestureDetector(
      onTap: () => setState(() => _isRestDay = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // STEP 2: Thumbnail

  Widget _buildThumbnailStep() {
    final colorScheme = Theme.of(context).colorScheme;
    final thumbnailService = ref.watch(thumbnailServiceProvider);

    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a vibe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 16),
          // Search
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),

            child: TextField(
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                hintText: 'Search images',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                border: InputBorder.none,
              ),

              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(height: 24),
          // Grid
          Expanded(
            child: FutureBuilder<List<String>>(
              future: thumbnailService.searchImages(_searchQuery),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                }

                
                final images = snapshot.data!;
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final url = images[index];
                    final isSelected = _selectedThumbnail == url;
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedThumbnail = url),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border.all(color: colorScheme.primary, width: 3) : null,
                          color: colorScheme.surfaceContainerHighest,
                        ),

                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(Icons.broken_image, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                );

                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary));

                              },
                            ),
                            if (isSelected)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.check, color: colorScheme.onPrimary, size: 20),
                                ),

                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Exercises
  // STEP 3: Exercises
  Widget _buildExercisesStep() {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(

      padding: const EdgeInsets.all(24),
      // +1 for the "Add Exercise" form at the end
      itemCount: _exercises.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        // If it's the last item, render the Add Form
        if (index == _exercises.length) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Exercise',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _exNameController,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Exercise Name',
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),


                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _setsController,
                        style: TextStyle(color: colorScheme.onSurface),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Sets',
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),


                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _repsController,
                        style: TextStyle(color: colorScheme.onSurface),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addExercise(),
                        decoration: InputDecoration(
                          labelText: 'Reps',
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),


                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: _addExercise,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                    ),

                  ],
                ),
              ],
            ),
          );
        }
        
        // Otherwise render the exercise tile
        final ex = _exercises[index];
        return ListTile(
          tileColor: colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(ex.name, style: TextStyle(color: colorScheme.onSurface)),
          subtitle: Text('${ex.sets} sets x ${ex.reps} reps',
              style: TextStyle(color: colorScheme.onSurfaceVariant)),
          trailing: IconButton(
            icon: Icon(Icons.remove_circle_outline, color: colorScheme.error),
            onPressed: () => setState(() => _exercises.removeAt(index)),
          ),
        );

      },
    );
  }
  
  void _addExercise() {
    final name = _exNameController.text.trim();
    // Parse as double first to handle "12.0" or "12." gracefully, then round to int
    final setsDouble = double.tryParse(_setsController.text) ?? 3;
    final repsDouble = double.tryParse(_repsController.text) ?? 10;
    
    final sets = setsDouble.round();
    final reps = repsDouble.round();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter an exercise name', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _exercises.add((name: name, sets: sets, reps: reps));
      _exNameController.clear();
      // Keep sets/reps as is for quick entry of similar exercises
    });
  }

  // STEP 4: Clock
  Widget _buildClockStep() {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(

      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tracking Style',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 32),
          _buildClockOption(
            ClockType.stopwatch,
            'Stopwatch',
            'Track total duration',
            Icons.timer_outlined,
          ),
          const SizedBox(height: 16),
          _buildClockOption(
            ClockType.timer,
            'Timer',
            'Countdown for circuit training',
            Icons.hourglass_bottom,
          ),
          const SizedBox(height: 16),
          _buildClockOption(
            ClockType.none,
            'None',
            'Just mark as complete',
            Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }
  
  Widget _buildClockOption(ClockType type, String title, String subtitle, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedClock == type;

    
    return GestureDetector(
      onTap: () => setState(() => _selectedClock = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),

        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 28,
            ),

            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary),

          ],
        ),
      ),
    );
  }
}
