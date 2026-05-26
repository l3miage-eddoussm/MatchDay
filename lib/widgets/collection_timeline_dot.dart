import 'package:flutter/material.dart';

class CollectionTimelineDot extends StatelessWidget {
  final int index;
  final bool isCurrent;
  final bool isLast;

  const CollectionTimelineDot({
    super.key,
    required this.index,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? Colors.white : const Color(0xFF2A2A2A),
              border: Border.all(
                color: isCurrent ? Colors.white : const Color(0xFF3A3A3A),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: isCurrent ? Colors.black : Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: const Color(0xFF2A2A2A),
              ),
            ),
        ],
      ),
    );
  }
}