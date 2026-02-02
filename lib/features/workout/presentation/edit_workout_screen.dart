import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/services/thumbnail_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  String? _thumbnailUrl;
  
  final List<({int? id, String name, int sets, int reps})> _exercises = [];
  
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
      _thumbnailUrl = w.thumbnailUrl;
      
      final db = ref.read(appDatabaseProvider);
      final exercises = await db.getExercisesForWorkout(w.id);
      
      if (mounted) {
        setState(() {
          for (var e in exercises) {
            _exercises.add((id: e.id, name: e.name, sets: e.sets, reps: e.reps));
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.existingWorkout != null ? 'Edit Workout' : 'New Workout'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving 
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))
              : Text('SAVE', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 0: Thumbnail Picker
                    _buildThumbnailPicker(context),
                    const SizedBox(height: 24),

                    // Section 1: Details
                    _buildSectionTitle(context, 'Details'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: const InputDecoration(
                        labelText: 'Workout Name',
                        hintText: 'e.g. Upper Body Power',
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    // Day Selection (if adding new, or maybe editing too?)
                    // Let's allow editing the day assignment
                    Text('Assigned Day', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                    const SizedBox(height: 8),
                    _buildDaySelector(),
                    
                    const SizedBox(height: 32),
                    
                    // Section 2: Exercises
                    _buildSectionTitle(context, 'Exercises'),
                    const SizedBox(height: 16),
                    _buildExerciseList(),
                    const SizedBox(height: 16),
                    _buildAddExerciseForm(),
                    
                    const SizedBox(height: 32),
                    
                    // Section 3: Settings
                    _buildSectionTitle(context, 'Settings'),
                    const SizedBox(height: 16),
                    _buildClockSelector(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }
  
  Widget _buildDaySelector() {
    final colorScheme = Theme.of(context).colorScheme;
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
            selectedColor: colorScheme.primary,
            backgroundColor: colorScheme.surfaceContainer,
            labelStyle: TextStyle(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildExerciseList() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_exercises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            'No exercises added yet',
            style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
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
          key: ValueKey('ex_$index'), 
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Icon(Icons.drag_handle, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            title: Text(ex.name, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w500)),
            subtitle: Text('${ex.sets} sets × ${ex.reps} reps', style: TextStyle(color: colorScheme.onSurfaceVariant)),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Add', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _exNameController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Exercise',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: colorScheme.surface,
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
                  style: TextStyle(color: colorScheme.onSurface),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Sets',
                    filled: true,
                    fillColor: colorScheme.surface,
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
                  style: TextStyle(color: colorScheme.onSurface),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Reps',
                    filled: true,
                    fillColor: colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _addExercise(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addExercise,
                style: IconButton.styleFrom(backgroundColor: colorScheme.primary),
                icon: Icon(Icons.add, color: colorScheme.onPrimary),
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
      _exercises.add((id: null, name: name, sets: sets, reps: reps));
      _exNameController.clear();
      // Keep sets/reps for convenience
    });
  }

  Widget _buildThumbnailPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(context, 'Thumbnail'),
            TextButton.icon(
              onPressed: _showThumbnailSelection,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Change'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showThumbnailSelection,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
              image: _thumbnailUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(_thumbnailUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _thumbnailUrl == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 40, color: colorScheme.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      Text(
                        'Select Workout Cover',
                        style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  void _showThumbnailSelection() {
    debugPrint('Opening Thumbnail Selection Sheet...');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ThumbnailSelector(
        onSelected: (url) {
          debugPrint('Selected Thumbnail URL: $url');
          setState(() {
            _thumbnailUrl = url;
          });
          Navigator.pop(context);
        },
      ),
    ).then((_) => debugPrint('Thumbnail selection sheet closed. Current selection: $_thumbnailUrl'));
  }

  Widget _buildClockSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ClockType>(
          value: _selectedClock,
          dropdownColor: colorScheme.surfaceContainer,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
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
                  Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(label, style: TextStyle(color: colorScheme.onSurface)),
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
        // SMART UPDATE Strategy: Diffing
        final w = widget.existingWorkout!;
        
        // 1. Update Workout Details
        await db.updateWorkout(w.toCompanion(true).copyWith(
          name: drift.Value(name),
          shortCode: drift.Value(shortCode),
          orderIndex: drift.Value(_selectedDayIndex),
          clockType: drift.Value(_selectedClock),
          thumbnailUrl: drift.Value(_thumbnailUrl),
        ));
        
        // 2. Identify Changes
        final existingExercises = await db.getExercisesForWorkout(w.id);
        final existingIds = existingExercises.map((e) => e.id).toSet();
        final currentIds = _exercises.map((e) => e.id).whereType<int>().toSet();
        
        // A. Delete Removed Exercises
        final toDeleteIds = existingIds.difference(currentIds);
        for (final id in toDeleteIds) {
          await db.deleteExercise(id);
        }
        
        // B. Update or Insert
        for (int i = 0; i < _exercises.length; i++) {
          final e = _exercises[i];
          if (e.id != null && existingIds.contains(e.id)) {
            // Update
            await db.updateExercise(ExercisesCompanion(
              id: drift.Value(e.id!),
              workoutId: drift.Value(w.id),
              name: drift.Value(e.name),
              sets: drift.Value(e.sets),
              reps: drift.Value(e.reps),
              orderIndex: drift.Value(i),
            ));
          } else {
            // Insert
            await db.addExercise(ExercisesCompanion(
              workoutId: drift.Value(w.id),
              name: drift.Value(e.name),
              sets: drift.Value(e.sets),
              reps: drift.Value(e.reps),
              orderIndex: drift.Value(i),
            ));
          }
        }
      } else {
        // CREATE (New Workout - Insert All)
        final workoutId = await db.addWorkout(
          WorkoutsCompanion(
            name: drift.Value(name),
            shortCode: drift.Value(shortCode),
            orderIndex: drift.Value(_selectedDayIndex),
            clockType: drift.Value(_selectedClock),
            thumbnailUrl: drift.Value(_thumbnailUrl),
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

class _ThumbnailSelector extends ConsumerStatefulWidget {
  final ValueChanged<String> onSelected;

  const _ThumbnailSelector({required this.onSelected});

  @override
  ConsumerState<_ThumbnailSelector> createState() => _ThumbnailSelectorState();
}

class _ThumbnailSelectorState extends ConsumerState<_ThumbnailSelector> {
  final _searchController = TextEditingController();
  List<String> _images = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final service = ref.read(thumbnailServiceProvider);
      final featured = service.getFeaturedImages();
      setState(() {
        _images = featured;
        _isLoading = false;
      });
      debugPrint('Loaded ${featured.length} featured images.');
    } catch (e) {
      debugPrint('Error loading featured images: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      _loadImages();
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final service = ref.read(thumbnailServiceProvider);
      final results = await service.searchImages(query);
      setState(() {
        _images = results;
        _isLoading = false;
      });
      debugPrint('Search for "$query" returned ${results.length} images.');
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final padding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75 + padding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + padding),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Select Thumbnail',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(onPressed: _loadImages, icon: const Icon(Icons.refresh, size: 20)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search (e.g. Chest, Yoga, Run)...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onSubmitted: _search,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      final url = _images[index];
                      return GestureDetector(
                        onTap: () => widget.onSelected(url),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                            color: colorScheme.surfaceContainerHigh,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary.withValues(alpha: 0.3)),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                               child: Icon(Icons.broken_image, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
