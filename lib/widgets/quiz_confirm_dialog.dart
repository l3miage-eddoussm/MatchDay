import 'package:flutter/material.dart';

class QuizConfirmDialog extends StatelessWidget {
  const QuizConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF141414),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Quiz Trivia',
        style: TextStyle(
            color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
      ),
      content: const Text(
        "Tu ne pourras passer ce quiz qu'une seule fois.\n\nSelon ton score, tu débloques des Throphés du film.\n\nBonne chance !",
        style: TextStyle(
            color: Color(0xFF888888), fontSize: 13, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler',
              style: TextStyle(color: Color(0xFF666666))),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Commencer',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}