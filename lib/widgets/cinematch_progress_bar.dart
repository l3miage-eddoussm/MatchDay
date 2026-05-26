import 'package:flutter/material.dart';

class CineMatchProgressBar extends StatelessWidget {
  final int step;
  final int total;

  static const _red  = Color(0xFFFF0000);
  static const _card = Color(0xFF1A1A1A);

  const CineMatchProgressBar({
    super.key,
    required this.step,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (step + 1) / total,
          backgroundColor: _card,
          valueColor: const AlwaysStoppedAnimation<Color>(_red),
          minHeight: 3,
        ),
      ),
    );
  }
}