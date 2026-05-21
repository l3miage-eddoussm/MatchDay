import 'package:flutter/material.dart';

class RatingBottomSheet extends StatefulWidget {
  final double? initialRating;
  final String? initialReview;
  final void Function(double rating, String? review) onRate;
  final VoidCallback? onRemove;

  const RatingBottomSheet({
    super.key,
    this.initialRating,
    this.initialReview,
    required this.onRate,
    this.onRemove,
  });

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  late double _selected;
  late TextEditingController _reviewController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selected = widget.initialRating ?? 0;
    _reviewController =
        TextEditingController(text: widget.initialReview ?? '');
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
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
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: filled
                            ? Colors.white
                            : const Color(0xFF444444),
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
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: TextField(
                  controller: _reviewController,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 3,
                  maxLength: 1000,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Écrire une critique personnelle... (optionnel)',
                    hintStyle: TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 14,
                    ),
                    contentPadding: EdgeInsets.all(14),
                    border: InputBorder.none,
                    counterStyle: TextStyle(
                      color: Color(0xFF444444),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _selected > 0
                      ? () {
                    final review = _reviewController.text.trim();
                    widget.onRate(
                      _selected,
                      review.isNotEmpty ? review : null,
                    );
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
                      color: _selected > 0
                          ? Colors.black
                          : const Color(0xFF555555),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              if (widget.initialRating != null &&
                  widget.onRemove != null) ...[
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
        ),
      ),
    );
  }
}