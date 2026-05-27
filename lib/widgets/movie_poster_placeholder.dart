import 'package:flutter/material.dart';
import '../constants.dart';

class MoviePosterPlaceholder extends StatelessWidget {
  const MoviePosterPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceDark,
      child: const Center(
        child: Icon(Icons.movie, color: Color(0xFF333333), size: 28),
      ),
    );
  }
}