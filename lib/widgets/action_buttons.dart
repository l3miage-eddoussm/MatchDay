import 'package:flutter/material.dart';
import '../models/user_movie_action.dart';

class ActionButtons extends StatelessWidget {
  final UserMovieAction? userAction;
  final VoidCallback onRatingTap;
  final VoidCallback onWatchLaterTap;

  const ActionButtons({
    super.key,
    required this.userAction,
    required this.onRatingTap,
    required this.onWatchLaterTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRated = userAction?.rating != null;
    final isWatchLater = userAction?.watchLater ?? false;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onRatingTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: isRated ? Colors.white : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isRated ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isRated ? Colors.black : Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRated
                        ? '${userAction!.rating!.toInt()} / 10'
                        : 'Noter',
                    style: TextStyle(
                      color: isRated ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onWatchLaterTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: isWatchLater ? Colors.white : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isWatchLater
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    color: isWatchLater ? Colors.black : Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isWatchLater ? 'Sauvegardé' : 'Voir plus tard',
                    style: TextStyle(
                      color: isWatchLater ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}