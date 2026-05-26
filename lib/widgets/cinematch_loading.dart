import 'package:flutter/material.dart';

class CineMatchLoading extends StatelessWidget {
  static const _red  = Color(0xFFFF0000);
  static const _card = Color(0xFF1A1A1A);

  const CineMatchLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LoadingIcon(),
          SizedBox(height: 24),
          Text(
            'On cherche ton film parfait...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Un instant',
            style: TextStyle(color: Color(0xFF555555), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _LoadingIcon extends StatelessWidget {
  static const _red  = Color(0xFFFF0000);
  static const _card = Color(0xFF1A1A1A);

  const _LoadingIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: _red, strokeWidth: 2.5),
      ),
    );
  }
}