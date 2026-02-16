import 'dart:async';
import 'package:flutter/material.dart';

/// Parking Timer Widget
/// Displays a countdown timer, extend options, and a cancel button
class ParkingTimer extends StatefulWidget {
  final VoidCallback? onSessionEnd;
  final Function(Duration)? onExtend;

  const ParkingTimer({
    super.key,
    this.onSessionEnd,
    this.onExtend,
  });

  @override
  State<ParkingTimer> createState() => _ParkingTimerState();
}

class _ParkingTimerState extends State<ParkingTimer> {
  Duration _remainingTime = Duration.zero;
  Timer? _timer;
  bool _isActive = false;

  void _startTimer() {
    _timer?.cancel();
    // Only start countdown if there's time remaining
    if (_remainingTime.inSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingTime.inSeconds > 0) {
          setState(() {
            _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
          });
        } else {
          _timer?.cancel();
          setState(() {
            _isActive = false;
          });
          widget.onSessionEnd?.call();
        }
      });
    }
  }

  void _extendSession(int minutes) {
    setState(() {
      final extension = Duration(minutes: minutes);
      _remainingTime = Duration(seconds: _remainingTime.inSeconds + extension.inSeconds);
      widget.onExtend?.call(extension);
      
      // Start the timer if it's not already running and we're active
      if (_isActive && (_timer == null || !_timer!.isActive)) {
        _startTimer();
      }
    });
  }

  void _stopSession() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _remainingTime = Duration.zero;
    });
    widget.onSessionEnd?.call();
  }

  void _startNewSession() {
    _timer?.cancel();
    setState(() {
      _isActive = true;
      _remainingTime = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              _isActive ? 'Active Parking Session' : 'Parking Session',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),

            // Countdown Timer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: _isActive ? Colors.blue.shade50 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _isActive 
                        ? (_remainingTime.inSeconds == 0 ? 'Add Time to Start' : 'Time Remaining')
                        : 'Session Ended',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_remainingTime),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isActive ? Colors.blue.shade900 : Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Extend/Add Time Buttons
            if (_isActive) ...[
              Text(
                _remainingTime.inSeconds == 0 ? 'Add Time for Your Stay' : 'Extend Session',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _extendSession(30),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('+30 mins'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _extendSession(60),
                      icon: const Icon(Icons.add_circle),
                      label: const Text('+60 mins'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Stop Stay Button
            if (_isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('End Session?'),
                          content: const Text(
                            'Are you sure you want to end your parking session early?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _stopSession();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('End Session'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Stop Stay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

            // Start New Session Button
            if (!_isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startNewSession,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Start New Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
