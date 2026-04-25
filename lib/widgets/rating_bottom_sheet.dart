import 'package:flutter/material.dart';

class RatingBottomSheet extends StatefulWidget {
  final double? initialRating;
  final void Function(double rating) onRate;
  final VoidCallback? onRemove;

  const RatingBottomSheet({
    super.key,
    this.initialRating,
    required this.onRate,
    this.onRemove,
  });

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  late double _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialRating ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Donner une note',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(10, (index) {
              final starValue = (index + 1).toDouble();
              final filled = starValue <= _selected;
              return GestureDetector(
                onTap: () => setState(() => _selected = starValue),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? Colors.white : const Color(0xFF444444),
                    size: 28,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _selected > 0 ? '${_selected.toInt()} / 10' : 'Aucune note',
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _selected > 0
                  ? () {
                widget.onRate(_selected);
                Navigator.of(context).pop();
              }
                  : null,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF222222),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Confirmer',
                style: TextStyle(
                  color: _selected > 0 ? Colors.black : const Color(0xFF555555),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (widget.initialRating != null && widget.onRemove != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  widget.onRemove!();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Supprimer la note',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}