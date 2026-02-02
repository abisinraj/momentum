
/// Standardized Muscle Definitions matching the 3D Model
/// These keys must match the `name` property in the 3D Viewer's `muscleDefs` array EXACTLY.
class MuscleData {
  static const Map<String, List<String>> groups = {
    'Chest': ['Chest'],
    'Back': ['Traps', 'Lats', 'Upper Back', 'Lower Back'],
    'Shoulders': ['Front Shoulders', 'Side Shoulders', 'Rear Shoulders'],
    'Arms': ['Biceps', 'Triceps', 'Forearms'],
    'Core': ['Upper Abs', 'Lower Abs', 'Obliques'],
    'Legs': ['Quads', 'Hamstrings', 'Glutes', 'Calves', 'Inner Thighs', 'Outer Thighs', 'Shins'],
    'Other': ['Neck', 'Cardio', 'Full Body'],
  };

  /// Flattened list of all valid muscle names for validation/dropdowns
  static List<String> get allMuscles => groups.values.expand((x) => x).toList();

  /// Helper to convert "Front Delts" -> "Front Shoulders" if needed for backward compatibility
  static String normalize(String input) {
    // Strip (Left) suffix for normalization if present (from 3D model tap)
    if (input.endsWith(' (Left)')) {
      input = input.replaceAll(' (Left)', '');
    }

    switch (input.toLowerCase()) {
      case 'front delts': return 'Front Shoulders';
      case 'side delts': return 'Side Shoulders';
      case 'rear delts': return 'Rear Shoulders';
      case 'abs': return 'Upper Abs'; // Default to upper if generic
      case 'legs': return 'Quads'; // Default to quads if generic
      case 'back': return 'Lats'; // Default
      case 'shoulders': return 'Side Shoulders'; // Default
      case 'arms': return 'Biceps';
      default: return input; // Return as-is (e.g. Chest, Triceps)
    }
  }

  /// Reverse mapping for DB queries (e.g. "Front Shoulders" -> ["Front Shoulders", "Front Delts"])
  static List<String> getAliases(String standardName) {
    final variations = [standardName];
    
    switch (standardName) {
      case 'Front Shoulders': variations.add('Front Delts'); break;
      case 'Side Shoulders': variations.addAll(['Side Delts', 'Lateral Delts', 'Shoulders']); break;
      case 'Rear Shoulders': variations.add('Rear Delts'); break;
      case 'Quads': variations.add('Legs'); break;
      case 'Upper Abs': variations.add('Abs'); break;
      case 'Lats': variations.add('Back'); break;
      case 'Biceps': variations.add('Arms'); break;
    }
    return variations;
  }

  /// Complete definition of 3D spots logic - Source of Truth
  static const List<Map<String, dynamic>> definitions = [
    // UPPER BODY
    {'name': 'Neck', 'bone': 'Neck', 'radius': 0.10},
    {'name': 'Traps', 'bone': 'Spine2', 'radius': 0.18, 'offset': [0.0, 0.2, -0.1]},
    {'name': 'Chest', 'bone': 'Spine2', 'radius': 0.20, 'offset': [0.0, -0.05, 0.15]},
    {'name': 'Upper Back', 'bone': 'Spine2', 'radius': 0.20, 'offset': [0.0, 0.1, -0.1]},
    {'name': 'Lats', 'bone': 'Spine1', 'radius': 0.22, 'offset': [0.0, 0.15, -0.1]},
    {'name': 'Lower Back', 'bone': 'Spine', 'radius': 0.20, 'offset': [0.0, 0.05, -0.12]},

    // SHOULDERS
    {'name': 'Front Shoulders', 'bone': 'RightArm', 'radius': 0.14, 'offset': [0.0, 0.05, 0.12]}, // Mirrored by logic
    {'name': 'Side Shoulders', 'bone': 'RightArm', 'radius': 0.12, 'offset': [0.08, 0.05, 0.0]},
    {'name': 'Rear Shoulders', 'bone': 'RightArm', 'radius': 0.12, 'offset': [0.0, 0.05, -0.08]},

    // ARMS
    {'name': 'Biceps', 'start': 'RightArm', 'end': 'RightForeArm', 'radius': 0.12, 'offset': [0.0, 0.0, 0.06]},
    {'name': 'Triceps', 'start': 'RightArm', 'end': 'RightForeArm', 'radius': 0.12, 'offset': [0.0, 0.0, -0.06]},
    {'name': 'Forearms', 'start': 'RightForeArm', 'end': 'RightHand', 'radius': 0.10},

    // CORE
    {'name': 'Upper Abs', 'bone': 'Spine2', 'radius': 0.16, 'offset': [0.0, -0.15, 0.14]},
    {'name': 'Lower Abs', 'bone': 'Spine1', 'radius': 0.16, 'offset': [0.0, -0.05, 0.14]},
    {'name': 'Obliques', 'bone': 'Spine1', 'radius': 0.14, 'offset': [0.12, -0.05, 0.08]},

    // LOWER BODY
    {'name': 'Glutes', 'bone': 'Hips', 'radius': 0.22, 'offset': [0.0, -0.05, -0.15]},
    {'name': 'Quads', 'start': 'RightUpLeg', 'end': 'RightLeg', 'radius': 0.16, 'offset': [0.0, 0.0, 0.08]},
    {'name': 'Hamstrings', 'start': 'RightUpLeg', 'end': 'RightLeg', 'radius': 0.16, 'offset': [0.0, 0.0, -0.08]},
    {'name': 'Inner Thighs', 'start': 'RightUpLeg', 'end': 'RightLeg', 'radius': 0.16, 'offset': [-0.06, 0.05, 0.0]},
    {'name': 'Outer Thighs', 'start': 'RightUpLeg', 'end': 'RightLeg', 'radius': 0.14, 'offset': [0.08, 0.0, 0.0]},
    {'name': 'Calves', 'start': 'RightLeg', 'end': 'RightFoot', 'radius': 0.10, 'offset': [0.0, 0.0, -0.06]},
    {'name': 'Shins', 'start': 'RightLeg', 'end': 'RightFoot', 'radius': 0.08, 'offset': [0.0, 0.0, 0.06]},
  ];
  
  /// Get mirror configuration for symmetry (Left side)
  static final List<String> mirroredMuscles = [
    'Front Shoulders', 'Side Shoulders', 'Rear Shoulders',
    'Biceps', 'Triceps', 'Forearms', 'Obliques',
    'Quads', 'Hamstrings', 'Inner Thighs', 'Outer Thighs', 'Calves', 'Shins'
  ];
}
