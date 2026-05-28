import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String initials;
  const ProfileAvatar({super.key, required this.initials});

  @override
  Widget build(BuildContext context) => Container(
    width: 68,
    height: 68,
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFF2A2A2A), width: 2),
    ),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    ),
  );
}