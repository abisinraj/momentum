import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_providers.dart';

class EditWorkoutScreen extends ConsumerStatefulWidget {
  final int? splitIndex; // For adding new: which day index?
  final Workout? existingWorkout; // For editing

  const EditWorkoutScreen({
    super.key,
    this.splitIndex,
    this.existingWorkout,
  });

  @override
  ConsumerState<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends ConsumerState<EditWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  ClockType _selectedClock = ClockType.stopwatch;
  int _selectedDayIndex = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  
  final List<({String name, int sets, int reps})> _exercises = [];
  
  // Exercise inputs
  final _exNameController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = widget.splitIndex ?? 0;
    
    if (widget.existingWorkout != null) {
      _loadExistingData();
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _exNameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    try {
      final w = widget.existingWorkout!;
      _nameController.text = w.name;
      _selectedClock = w.clockType;
      _selectedDayIndex = w.orderIndex;
      
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
      debugPrint('Error loading workout: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(widget.existingWorkout != null ? 'Edit Workout' : 'New Workout'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.tealPrimary))
              : const Text('SAVE', style: TextStyle(color: AppTheme.tealPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.tealPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Details
                    _buildSectionTitle('Details'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Workout Name',
                        hintText: 'e.g. Upper Body Power',
                        filled: true,
                        fillColor: AppTheme.darkSurfaceContainer,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    // Day Selection (if adding new, or maybe editing too?)
                    // Let's allow editing the day assignment
                    const Text('Assigned Day', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    const SizedBox(height: 8),
                    _buildDaySelector(),
                    
                    const SizedBox(height: 32),
                    
                    // Section 2: Exercises
                    _buildSectionTitle('Exercises'),
                    const SizedBox(height: 16),
                    _buildExerciseList(),
                    const SizedBox(height: 16),
                    _buildAddExerciseForm(),
                    
                    const SizedBox(height: 32),
                    
                    // Section 3: Settings
                    _buildSectionTitle('Settings'),
                    const SizedBox(height: 16),
                    _buildClockSelector(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.tealPrimary,
        letterSpacing: 0.5,
      ),
    );
  }
  
  Widget _buildDaySelector() {
    final userAsync = ref.watch(currentUserProvider);
    final splitDays = userAsync.value?.splitDays ?? 3; // Default fallback
    
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: splitDays,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedDayIndex == index;
          return ChoiceChip(
            label: Text('Day ${index + 1}'),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) setState(() => _selectedDayIndex = index);
            },
            selectedColor: AppTheme.tealPrimary,
            backgroundColor: AppTheme.darkSurfaceContainer,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildExerciseList() {
    if (_exercises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkSurfaceContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),

          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: const Center(
          child: Text(
            'No exercises added yet',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }
    
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _exercises.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _exercises.removeAt(oldIndex);
          _exercises.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final ex = _exercises[index];
        return Container(
          key: ValueKey('ex_$index'), // Unique key issue for reordering? Ideally stable ID, but index ok for local list? No, needs stable key. ValueKey(ex) ok if distinct.
          // Using UniqueKey() for list items constructed on fly is safer for ReorderableListView in simple cases
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const Icon(Icons.drag_handle, color: AppTheme.textMuted),
            title: Text(ex.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
            subtitle: Text('${ex.sets} sets × ${ex.reps} reps', style: const TextStyle(color: AppTheme.textSecondary)),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
              onPressed: () => setState(() => _exercises.removeAt(index)),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAddExerciseForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.tealPrimary.withValues(alpha: 0.3)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Add', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _exNameController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Exercise',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.darkBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _setsController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Sets',
                    filled: true,
                    fillColor: AppTheme.darkBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _repsController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Reps',
                    filled: true,
                    fillColor: AppTheme.darkBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _addExercise(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addExercise,
                style: IconButton.styleFrom(backgroundColor: AppTheme.tealPrimary),
                icon: const Icon(Icons.add, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _addExercise() {
    final name = _exNameController.text.trim();
    final sets = int.tryParse(_setsController.text) ?? 3;
    final reps = int.tryParse(_repsController.text) ?? 10;
    
    if (name.isEmpty) return;
    
    setState(() {
      _exercises.add((name: name, sets: sets, reps: reps));
      _exNameController.clear();
      // Keep sets/reps for convenience
    });
  }

  Widget _buildClockSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ClockType>(
          value: _selectedClock,
          dropdownColor: AppTheme.darkSurfaceContainer,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.tealPrimary),
          items: ClockType.values.map((type) {
            final (label, icon) = switch (type) {
              ClockType.none => ('None', Icons.check_circle_outline),
              ClockType.stopwatch => ('Stopwatch (Track Duration)', Icons.timer_outlined),
              ClockType.timer => ('Timer (Countdown)', Icons.hourglass_bottom),
              ClockType.alarm => ('Alarm', Icons.alarm),
            };
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(icon, size: 20, color: AppTheme.textSecondary),
                  const SizedBox(width: 12),
                  Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedClock = val);
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final db = ref.read(appDatabaseProvider);
      final name = _nameController.text.trim();
      final shortCode = name.isNotEmpty ? name[0].toUpperCase() : 'W';
      
      if (widget.existingWorkout != null) {
        // UPDATE
        final w = widget.existingWorkout!;
        await db.updateWorkout(w.toCompanion(true).copyWith(
          name: drift.Value(name),
          shortCode: drift.Value(shortCode),
          orderIndex: drift.Value(_selectedDayIndex),
          clockType: drift.Value(_selectedClock),
          // Keep existing thumbnail
        ));
        
        await db.deleteExercisesForWorkout(w.id);
        
        for (int i = 0; i < _exercises.length; i++) {
          // Using loop index 'i'
          final e = _exercises[i];
          await db.addExercise(ExercisesCompanion(

            workoutId: drift.Value(w.id),
            name: drift.Value(e.name),
            sets: drift.Value(e.sets),
            reps: drift.Value(e.reps),
            orderIndex: drift.Value(i),
          ));
        }
      } else {
        // CREATE
        final workoutId = await db.addWorkout(
          WorkoutsCompanion(
            name: drift.Value(name),
            shortCode: drift.Value(shortCode),
            orderIndex: drift.Value(_selectedDayIndex),
            clockType: drift.Value(_selectedClock),
            thumbnailUrl: const drift.Value(null), // No thumbnail for quick add
          ),
        );
        
        for (int i = 0; i < _exercises.length; i++) {
          final e = _exercises[i];
          await db.addExercise(ExercisesCompanion(
            workoutId: drift.Value(workoutId),
            name: drift.Value(e.name),
            sets: drift.Value(e.sets),
            reps: drift.Value(e.reps),
            orderIndex: drift.Value(i),
          ));
        }
      }
      
      ref.invalidate(workoutsStreamProvider);
      if (mounted) context.pop();
      
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
