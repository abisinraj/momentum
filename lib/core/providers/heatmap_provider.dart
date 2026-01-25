import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momentum/core/providers/dashboard_providers.dart';

/// Provider that returns normalized muscle intensity (0.0 to 1.0)
/// based on recent workload.
/// 
/// Mapped as: MuscleName -> Intensity
final muscleHeatmapProvider = FutureProvider<Map<String, double>>((ref) async {
  final workload = await ref.watch(muscleWorkloadProvider.future);
  
  final heatmap = <String, double>{};
  const maxSetsForIntensity = 12.0; // Sets to reach 100% redness/intensity
  
  workload.forEach((muscle, sets) {
    // Normalize to 0.0 - 1.0
    double intensity = sets / maxSetsForIntensity;
    if (intensity > 1.0) intensity = 1.0;
    
    // Map to 3D Model Keys
    final key = _mapMuscleToKey(muscle);
    if (key != null) {
      // Accumulate if multiple muscles map to same key (e.g. Quads + Hamstrings -> Legs)
      // Use max or average? Let's use max intensity.
      final existing = heatmap[key] ?? 0.0;
      if (intensity > existing) heatmap[key] = intensity;
    }
  });
  
  return heatmap;
});

String? _mapMuscleToKey(String muscle) {
  final m = muscle.toLowerCase();
  if (m.contains('chest') || m.contains('pectoral')) return 'Chest';
  if (m.contains('back') || m.contains('lat') || m.contains('trap')) return 'Back';
  if (m.contains('leg') || m.contains('quad') || m.contains('hamstring') || m.contains('glute')) return 'Legs';
  if (m.contains('calf') || m.contains('calves')) return 'Calves';
  if (m.contains('arm') || m.contains('bicep') || m.contains('tricep') || m.contains('forearm')) return 'Arms';
  if (m.contains('shoulder') || m.contains('delt')) return 'Shoulders';
  if (m.contains('abs') || m.contains('core') || m.contains('abdominal')) return 'Abs';
  return null;
}

