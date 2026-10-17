import 'package:flutter/material.dart';
import '../../../models/app_constants.dart';

/// 番剧观看状态徽标（圆点强调色 + 对应软底色）
class AnimeStatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final Color softColor;

  const AnimeStatusBadge({
    super.key,
    required this.status,
    required this.color,
    required this.softColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            AnimeStatus.getLabel(status),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
