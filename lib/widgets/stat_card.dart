import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool accent;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF0F0F0F),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF1A1A1A)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: accent ? const Color(0xFFE53935) : const Color(0xFF333333)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: accent ? const Color(0xFFE53935) : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );
}