import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'themed_card.dart';
import '../../../../core/providers/dashboard_providers.dart';
import '../../../../core/providers/database_providers.dart'; // For AppDatabase access if needed, though providers handle it
import '../../../../core/services/diet_service.dart';
import '../../../../core/database/app_database.dart'; // For FoodLogsCompanion
import 'package:drift/drift.dart' hide Column;

class NutritionCard extends ConsumerStatefulWidget {
  const NutritionCard({super.key});

  @override
  ConsumerState<NutritionCard> createState() => _NutritionCardState();
}

class _NutritionCardState extends ConsumerState<NutritionCard> {
  bool _isAdding = false;
  final TextEditingController _foodController = TextEditingController();

  Future<void> _addFood() async {
    final input = _foodController.text.trim();
    if (input.isEmpty) return;

    setState(() => _isAdding = true);
    
    // Clear keyboard
    FocusScope.of(context).unfocus();

    try {
      final dietService = ref.read(dietServiceProvider);
      final analysis = await dietService.analyzeFoodText(input);

      // Save to DB
      final db = ref.read(appDatabaseProvider);
      
      final companion = FoodLogsCompanion.insert(
        description: analysis['description'] ?? input,
        calories: (analysis['calories'] as num).toInt(),
        protein: Value((analysis['protein'] as num).toDouble()),
        carbs: Value((analysis['carbs'] as num).toDouble()),
        fats: Value((analysis['fats'] as num).toDouble()),
        date: Value(DateTime.now()), // explicit date
      );
      
      await db.addFoodLog(companion);
      
      if (mounted) {
        _foodController.clear();
        setState(() => _isAdding = false);
        // Refresh providers
        // ignore: unused_result
        ref.refresh(dailyNutritionProvider);
        // ignore: unused_result
        ref.refresh(dailyFoodLogsProvider);
      }
      
    } catch (e) {
      if (mounted) {
        setState(() => _isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showAddFoodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Food'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _foodController,
              decoration: const InputDecoration(
                hintText: 'e.g., "Grilled Chicken & Rice"',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (_) {
                Navigator.pop(context);
                _addFood();
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'AI will estimate calories & macros.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addFood();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final netAsync = ref.watch(netCaloriesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return ThemedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant_rounded, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'NUTRITION',
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.2,
                      color: colorScheme.onSurfaceVariant
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _isAdding ? null : _showAddFoodDialog,
                color: colorScheme.primary,
                tooltip: 'Log Food',
              ),
            ],
          ),
          
          if (_isAdding)
             const LinearProgressIndicator(),

          const SizedBox(height: 16),

          // Main Stats
          netAsync.when(
            data: (data) {
              final eaten = data['eaten']!;
              final burned = data['burned']!;
              final net = data['net']!;
              
              // Target net calories usually ~0 (maintenance) or +/- 500
              // Let's visualize relative to 2000 base for gauge context?
              // Or visualize simple: Eaten vs Burned? 
              // Usually: Gauge = Eaten / Target. But we don't have a target.
              // Let's just show the numbers clearly.
              
              return Row(
                children: [
                  // Net Gauge
                  CircularPercentIndicator(
                    radius: 40.0,
                    lineWidth: 8.0,
                    percent: (eaten > 2500 ? 1.0 : (eaten / 2500)).clamp(0.0, 1.0), // Arbitrary 2500 cap for visual
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$net',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: net > 0 ? colorScheme.error : colorScheme.primary),
                        ),
                        Text('NET', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    progressColor: net > 0 ? Colors.orange : colorScheme.primary, // Positive net means surplus (maybe bad if cutting needed, but neutral for now)
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(width: 24),
                  
                  // Detail Columns
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(context, 'EATEN', '$eaten', Icons.add_circle, Colors.orange),
                        Container(width: 1, height: 40, color: colorScheme.outlineVariant),
                        _buildStat(context, 'BURNED', '$burned', Icons.local_fire_department, Colors.redAccent),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading data', style: TextStyle(color: colorScheme.error)),
          ),
          
          const SizedBox(height: 16),
          
          // Recent Logs Mini-List (Last 3 items)
          Consumer(
            builder: (context, ref, _) {
              final logsAsync = ref.watch(dailyFoodLogsProvider);
              return logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return Text(
                      'No food logged today.',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
                    );
                  }
                  // Take last 3 items
                  final recent = logs.take(3).toList();
                  return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: recent.map((log) => Padding(
                       padding: const EdgeInsets.only(bottom: 4.0),
                       child: Row(
                         children: [
                           Text('• ${log.description}', style: const TextStyle(fontSize: 12)),
                           const Spacer(),
                           Text('${log.calories} kcal', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                         ],
                       ),
                     )).toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
             Icon(icon, size: 12, color: color),
             const SizedBox(width: 4),
             Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
