import 'package:flutter/material.dart';
import '../../models/app_constants.dart';

/// 统计概览栏组件（共收录、已观看集数、各状态数量）
class StatsBar extends StatelessWidget {
  final int totalRecords;
  final int totalEpisodesWatched;
  final Map<String, int> statusCounts;

  const StatsBar({
    super.key,
    required this.totalRecords,
    required this.totalEpisodesWatched,
    required this.statusCounts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isDark ? const Color(0xFF262B37) : const Color(0xFFE9EAF0);
    final cardBg = isDark ? const Color(0xFF171A22) : const Color(0xFFFFFFFF);
    final pillBg = isDark ? const Color(0xFF232733) : const Color(0xFFF1F5F9);
    final pillText = isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430);
    final labelColor = isDark ? const Color(0xFFA8B0C0) : const Color(0xFF59617A);

    final statuses = [
      (AnimeStatus.wantToWatch, '想看'),
      (AnimeStatus.watching, '在看'),
      (AnimeStatus.watched, '看过'),
      (AnimeStatus.onHold, '搁置'),
      (AnimeStatus.dropped, '抛弃'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 共收录
            _buildSummaryPill(
              pillBg: pillBg,
              pillText: pillText,
              labelColor: labelColor,
              value: '$totalRecords',
              label: '共收录',
            ),
            _buildDivider(borderColor),
            // 已观看集数
            _buildSummaryPill(
              pillBg: pillBg,
              pillText: pillText,
              labelColor: labelColor,
              value: '$totalEpisodesWatched',
              label: '集已观看',
            ),
            _buildDivider(borderColor),
            // 各状态数据
            ...statuses.map((item) {
              final status = item.$1;
              final label = item.$2;
              final count = statusCounts[status] ?? 0;
              final color = AnimeStatus.getColor(status, isDark: isDark);

              return Padding(
                padding: const EdgeInsets.only(right: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: labelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPill({
    required Color pillBg,
    required Color pillText,
    required Color labelColor,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: pillText,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: labelColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(Color color) {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: color,
    );
  }
}
