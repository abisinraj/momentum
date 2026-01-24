import 'package:flutter/material.dart';
import 'package:heart_bpm/heart_bpm.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:momentum/app/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HeartRateMeasureScreen extends ConsumerStatefulWidget {
  const HeartRateMeasureScreen({super.key});

  @override
  ConsumerState<HeartRateMeasureScreen> createState() => _HeartRateMeasureScreenState();
}

class _HeartRateMeasureScreenState extends ConsumerState<HeartRateMeasureScreen> {
  // BPM values for smoothing
  List<int> _recentReadings = [];
  int? _finalBpm;
  bool _isMeasuring = true;
  int _progress = 0; // 0 to 100
  
  @override
  void initState() {
    super.initState();
    _checkPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInstructions());
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission required for Heart Rate')),
        );
      }
    }
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('How to Measure', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Place your index finger gently on the back camera lens.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              '2. Make sure the lens is completely covered.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              '3. Hold still and do not press too hard.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              '4. Ensure you are in a well-lit environment (flash may turn on).',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('GOT IT', style: TextStyle(color: AppTheme.tealPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Heart Rate Monitor'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // TOP SECTION: Instructions
                    Column(
                      children: [
                        Text(
                          _finalBpm == null 
                              ? "Place finger on camera"
                              : "Measurement Complete",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _finalBpm == null 
                              ? "Cover the back camera lens completely with your index finger. Keep still."
                              : "Great job! Recording your heart rate.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // MIDDLE SECTION: Measurement or Result
                    if (_finalBpm == null)
                      _buildMeasurementUI()
                    else
                      _buildResultUI(_finalBpm!),
                      
                    const SizedBox(height: 20),
                    
                    // BOTTOM SECTION: Actions (placehold if empty to maintain spacing)
                    if (_finalBpm != null)
                       Column(
                         children: [
                           SizedBox(
                             width: double.infinity,
                             child: FilledButton(
                               onPressed: _saveMeasurement,
                               style: FilledButton.styleFrom(
                                 backgroundColor: AppTheme.tealPrimary,
                                 foregroundColor: Colors.black,
                                 padding: const EdgeInsets.symmetric(vertical: 20),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                               ),
                               child: const Text(
                                 'SAVE MEASUREMENT',
                                 style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                               ),
                             ),
                           ),
                           const SizedBox(height: 16),
                           TextButton(
                             onPressed: _retry,
                             child: const Text('RETAKE', style: TextStyle(color: Colors.white70)),
                           ),
                         ],
                       )
                    else
                       // Empty placeholder to balance the space if needed, or just let spaceBetween handle it
                       const SizedBox(height: 50),
                       
                    // Bottom padding
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeasurementUI() {
    return Column(
      children: [
        // The Camera/BPM Widget
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.tealPrimary.withValues(alpha: 0.3),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.tealPrimary.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: HeartBPMDialog(
              context: context,
              cameraWidgetWidth: 200,
              cameraWidgetHeight: 200,
              // Typically this package handles the camera preview inside
              // We just listen to data
              onBPM: (bpm) {
                if (_isMeasuring && bpm > 40 && bpm < 200) {
                  setState(() {
                    _recentReadings.add(bpm);
                    // Simple logic: wait for 30 good readings (approx 5-10 sec)
                    if (_recentReadings.length > 30) {
                       _recentReadings.removeAt(0);
                    }
                    _progress += 2; // Increment progress
                    if (_progress >= 100) {
                      _finishMeasurement();
                    }
                  });
                }
              },
              onRawData: (_) {},
            ),
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Progress Info
        if (_recentReadings.isNotEmpty)
          Column(
            children: [
              Text(
                "${_recentReadings.last}",
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                "BPM",
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.tealPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          )
        else
          const Text(
            "Detecting Pulse...",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Colors.white54,
            ),
          ),
          
        const SizedBox(height: 20),
        
        // Progress Bar
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: _progress / 100,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tealPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildResultUI(int bpm) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.monitor_heart, color: AppTheme.tealPrimary, size: 80),
        const SizedBox(height: 24),
        Text(
          "$bpm",
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.0,
          ),
        ),
        const Text(
          "BPM",
          style: TextStyle(
            fontSize: 24,
            color: Colors.white54,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  void _finishMeasurement() {
    if (_recentReadings.isEmpty) return;
    
    // Calculate average of last 10 readings for stability
    final sublist = _recentReadings.skip(_recentReadings.length - 10).toList();
    if (sublist.isEmpty) return;
    
    final average = sublist.reduce((a, b) => a + b) ~/ sublist.length;
    
    // Validation: Check for realistic Human Heart Rate bounds (e.g., 40 to 180)
    if (average < 40 || average > 180) {
      _showInvalidReadingDialog(average);
      return;
    }

    setState(() {
      _isMeasuring = false;
      _finalBpm = average;
    });
  }

  void _showInvalidReadingDialog(int value) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Invalid Reading', style: TextStyle(color: Colors.redAccent)),
        content: Text(
          'We detected a heart rate of $value BPM, which seems physically unlikely.\n\nPlease ensure your finger completely covers the lens and you are holding still.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retry();
            },
            child: Text('RETAKE', style: TextStyle(color: AppTheme.tealPrimary)),
          ),
        ],
      ),
    );
  }

  void _retry() {
    setState(() {
      _recentReadings = [];
      _finalBpm = null;
      _isMeasuring = true;
      _progress = 0;
    });
  }

  void _saveMeasurement() {
    // TODO: Integrate with Health Connect Provider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Heart Rate ($_finalBpm BPM) Saved'),
        backgroundColor: AppTheme.tealPrimary,
      ),
    );
    context.pop();
  }
}
