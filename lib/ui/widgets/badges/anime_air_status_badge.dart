import 'package:flutter/material.dart';
import '../../../models/app_constants.dart';

/// 番剧播放状态徽标（正在更新/完结）
class AnimeAirStatusBadge extends StatelessWidget {
  final String airStatus;

  const AnimeAirStatusBadge({
    super.key,
    required this.airStatus,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AirStatus.getColors(airStatus);
    final isFinished = airStatus == AirStatus.finished;

    return Tooltip(
      message: '播放状态：${AirStatus.getLabel(airStatus)}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFinished ? Icons.check_circle_outline_rounded : Icons.sensors_rounded,
              size: 11,
              color: fg,
            ),
            const SizedBox(width: 4),
            Text(
              AirStatus.getLabel(airStatus),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
