import 'dart:async';
import 'package:flutter/material.dart';

class DiscountCountdownBanner extends StatefulWidget {
  final DateTime expirationDate;
  final String message;
  final String discountCode;
  final int discountPercentage;
  final VoidCallback? onExpired;  // <-- فقط هذا الحدث

  const DiscountCountdownBanner({
    super.key,
    required this.expirationDate,
    required this.message,
    required this.discountCode,
    required this.discountPercentage,
    this.onExpired,
  });

  @override
  State<DiscountCountdownBanner> createState() => _DiscountCountdownBannerState();
}

class _DiscountCountdownBannerState extends State<DiscountCountdownBanner> {
  late Duration _remaining;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final newRemaining = widget.expirationDate.difference(now);

    if (newRemaining.isNegative && _remaining != Duration.zero) {
      _timer.cancel();
      if (widget.onExpired != null) {
        widget.onExpired!();  // Notify parent that time expired
      }
    }

    setState(() {
      _remaining = newRemaining.isNegative ? Duration.zero : newRemaining;
    });
  }

  Widget _buildTimeUnit(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: const [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 3,
                color: Colors.black45,
              ),
            ],
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFD81B60),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.local_offer, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'انتهى العرض!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 4,
                    color: Colors.black54,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF5350), Color(0xFFFFCDD2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // سطر كود الخصم ونسبة الخصم
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: [
              const Text(
                'كود الخصم: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
              Text(
                widget.discountCode,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.yellowAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 20),
              const Text(
                'نسبة الخصم: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
              Text(
                '${widget.discountPercentage}%',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.yellowAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // الرسالة والعد التنازلي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            textDirection: TextDirection.rtl,
            children: [
              Flexible(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 10),
              _buildTimeUnit('يوم', days, Colors.white),
              const SizedBox(width: 10),
              _buildTimeUnit('ساعة', hours, Colors.white),
              const SizedBox(width: 10),
              _buildTimeUnit('دقيقة', minutes, Colors.white),
              const SizedBox(width: 10),
              _buildTimeUnit('ثانية', seconds, Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}
