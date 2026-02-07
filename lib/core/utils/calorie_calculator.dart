/// Utility class for calculating calorie expenditure
/// Uses MET (Metabolic Equivalent of Task) formula
class CalorieCalculator {
  /// Base MET value for moderate resistance training
  /// Reference: Compendium of Physical Activities
  static const double baseMet = 6.0;
  
  /// Estimate calories burned during a workout session
  /// 
  /// Formula: Calories = MET * weight_kg * duration_hours
  /// 
  /// Parameters:
  /// - [durationSeconds]: Duration of the workout in seconds
  /// - [weightKg]: User's body weight in kilograms
  /// - [intensity]: Workout intensity on a scale of 1-10 (default: 5)
  /// 
  /// Returns: Estimated calories burned (rounded to nearest integer)
  static int estimateCalories({
    required int durationSeconds,
    required double weightKg,
    int intensity = 5,
  }) {
    // Convert duration to hours
    final hours = durationSeconds / 3600.0;
    
    // Scale MET by intensity (1-10 scale, normalized to 5 as baseline)
    final intensityScale = intensity / 5.0;
    final adjustedMet = baseMet * intensityScale;
    
    // Calculate calories using MET formula
    final calories = adjustedMet * weightKg * hours;
    
    return calories.round();
  }
  
  /// Estimate calories for a session with optional pre-calculated values
  /// 
  /// If the session already has a caloriesBurned value, use it.
  /// Otherwise, calculate using the MET formula.
  static int estimateSessionCalories({
    int? caloriesBurned,
    int? durationSeconds,
    double? weightKg,
    int? intensity,
  }) {
    // Use pre-calculated value if available
    if (caloriesBurned != null) {
      return caloriesBurned;
    }
    
    // Fallback to MET calculation
    if (durationSeconds == null || weightKg == null) {
      return 0;
    }
    
    return estimateCalories(
      durationSeconds: durationSeconds,
      weightKg: weightKg,
      intensity: intensity ?? 5,
    );
  }
}
