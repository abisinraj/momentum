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
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 20), // Reduced top spacing
                    
                    // Instruction or Result
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
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
                    ),
                    
                    const Spacer(),
                    
                    // Main Measurement Widget
                    if (_finalBpm == null)
                      _buildMeasurementUI()
                    else
                      _buildResultUI(_finalBpm!),
                      
                    const Spacer(),
                    
                    // Result Actions
                    if (_finalBpm != null)
                       Padding(
                         padding: const EdgeInsets.only(bottom: 40.0, left: 24, right: 24),
                         child: Column(
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
                         ),
                       ),
                       
                    // Spacer if measuring to keep layout balanced
                    if (_finalBpm == null)
                      const SizedBox(height: 40),
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
    
    setState(() {
      _isMeasuring = false;
      _finalBpm = average;
    });
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
