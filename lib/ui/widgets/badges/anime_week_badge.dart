import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../models/app_constants.dart';

/// 番剧更新日徽标（含日历图标与完整标签 Tooltip）
class AnimeWeekBadge extends StatelessWidget {
  final String week;

  const AnimeWeekBadge({
    super.key,
    required this.week,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = WeekDay.getColors(week);
    final fullLabel = WeekDay.getFullLabel(week);
    return Tooltip(
      message: context.l10nOrNull?.weekBadgeTooltip(fullLabel) ?? '更新频率：$fullLabel',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 11, color: fg),
            const SizedBox(width: 4),
            Text(
              WeekDay.getLabel(week),
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
