import 'package:flutter/material.dart';

/// 番剧评分徽标（金色星星与小数评分展示）
class AnimeRatingBadge extends StatelessWidget {
  final double rating;
  final bool isDark;

  const AnimeRatingBadge({
    super.key,
    required this.rating,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF332713) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }
}
