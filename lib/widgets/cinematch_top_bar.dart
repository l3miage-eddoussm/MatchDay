import 'package:flutter/material.dart';

class CineMatchTopBar extends StatelessWidget {
  final bool showBack;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  static const _card = Color(0xFF1A1A1A);

  const CineMatchTopBar({
    super.key,
    required this.showBack,
    required this.isLoading,
    required this.onBack,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Icon(
                showBack
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.close_rounded,
                color: Colors.white70,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'CineMatch',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (!isLoading)
            GestureDetector(
              onTap: onRestart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Text(
                  'Recommencer',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}