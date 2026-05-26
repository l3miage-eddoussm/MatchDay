import 'package:flutter/material.dart';
import '../models/cinematch_question.dart';
import 'cinematch_progress_bar.dart';

class CineMatchQuestionCard extends StatelessWidget {
  final CineMatchQuestion question;
  final int step;
  final int total;
  final ValueChanged<String> onPick;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  static const _red  = Color(0xFFFF0000);
  static const _card = Color(0xFF1A1A1A);

  const CineMatchQuestionCard({
    super.key,
    required this.question,
    required this.step,
    required this.total,
    required this.onPick,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CineMatchProgressBar(step: step, total: total),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
              child: Text(
                question.subtitle.toUpperCase(),
                style: const TextStyle(
                  color: _red,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Text(
                question.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: question.choices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _ChoiceTile(
                  choice: question.choices[i],
                  onTap: onPick,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final CineMatchChoice choice;
  final ValueChanged<String> onTap;

  static const _card = Color(0xFF1A1A1A);

  const _ChoiceTile({required this.choice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(choice.value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                choice.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF444444),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}