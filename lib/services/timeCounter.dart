import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime expirationDate;

  const CountdownTimer({super.key, required this.expirationDate});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateDuration();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateDuration();
    });
  }

  void _calculateDuration() {
    final now = DateTime.now();
    final difference = widget.expirationDate.difference(now);

    if (!mounted) return;

    setState(() {
      _duration = difference.isNegative ? Duration.zero : difference;

      if (_duration == Duration.zero) {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    return '$days يوم ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_duration == Duration.zero) {
      return const Text(
        'انتهى',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    }

    return Text(
      'ينتهي خلال: ${_formatDuration(_duration)}',
      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
    );
  }
}
