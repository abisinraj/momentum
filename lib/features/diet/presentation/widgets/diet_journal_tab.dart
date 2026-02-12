import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_providers.dart';

class DietJournalTab extends ConsumerStatefulWidget {
  const DietJournalTab({super.key});

  @override
  ConsumerState<DietJournalTab> createState() => _DietJournalTabState();
}

class _DietJournalTabState extends ConsumerState<DietJournalTab> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final db = ref.watch(appDatabaseProvider);
    final theme = Theme.of(context);
    
    return StreamBuilder<List<FoodLog>>(
      stream: db.watchFoodLogsForDate(DateTime.now()),
      builder: (context, snapshot) {
         if (!snapshot.hasData) {
           return const Center(child: CircularProgressIndicator());
         }
         
         final logs = snapshot.data!;
         final totalCal = logs.fold<int>(0, (sum, item) => sum + item.calories);
         final totalP = logs.fold<double>(0, (sum, item) => sum + item.protein);
         final totalC = logs.fold<double>(0, (sum, item) => sum + item.carbs);
         final totalF = logs.fold<double>(0, (sum, item) => sum + item.fats);
         
         return ListView(
           padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
           children: [
             // Summary Card
             Card(
               color: theme.colorScheme.primaryContainer,
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                   children: [
                      _buildMacroSummary('Calories', '$totalCal', 'kcal', theme),
                      _buildMacroSummary('Protein', totalP.toStringAsFixed(1), 'g', theme),
                      _buildMacroSummary('Carbs', totalC.toStringAsFixed(1), 'g', theme),
                      _buildMacroSummary('Fats', totalF.toStringAsFixed(1), 'g', theme),
                   ],
                 ),
               ),
             ),
             const SizedBox(height: 16),
             const Text('Today\'s Meals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
             const SizedBox(height: 8),
             if (logs.isEmpty)
               const Center(child: Padding(
                 padding: EdgeInsets.all(32.0),
                 child: Text('No meals logged today.\nUse the AI Assistant to add one!'),
               )),
             ...logs.map((log) => Card(
               margin: const EdgeInsets.only(bottom: 8),
               child: ListTile(
                 leading: log.imageUrl != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(log.imageUrl!), width: 50, height: 50, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.fastfood),
                        ),
                      ) 
                    : const Icon(Icons.fastfood),
                 title: Text(log.description),
                 subtitle: Text('${log.calories} kcal • P:${log.protein} C:${log.carbs} F:${log.fats}'),
                 trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await db.deleteFoodLog(log.id);
                      // Stream updates automatically
                    },
                 ),
               ),
             )),
           ],
         );
      },
    );
  }

  Widget _buildMacroSummary(String label, String value, String unit, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
        Text('$unit $label', style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8))),
      ],
    );
  }
}
