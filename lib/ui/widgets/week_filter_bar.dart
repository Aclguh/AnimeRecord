import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../models/app_constants.dart';

/// 更新日（周几）筛选栏组件
class WeekFilterBar extends StatelessWidget {
  final String activeWeek;
  final Map<String, int> weekCounts;
  final ValueChanged<String> onSelectWeek;

  const WeekFilterBar({
    super.key,
    required this.activeWeek,
    required this.weekCounts,
    required this.onSelectWeek,
  });

  @override
  Widget build(BuildContext context) {
    // 如果没有任何记录设置了周几，则隐藏
    final hasAnyWeek = WeekDay.order.any((k) => (weekCounts[k] ?? 0) > 0);
    if (!hasAnyWeek) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined, size: 16, color: labelColor),
            const SizedBox(width: 6),
            Text(
              context.l10nOrNull?.weekLabel ?? '更新日',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(width: 12),
            // 全部
            _buildChip(
              context,
              label: context.l10nOrNull?.statusAll ?? '全部',
              isSelected: activeWeek.isEmpty,
              onTap: () => onSelectWeek(''),
            ),
            const SizedBox(width: 8),
            // 各周几（仅显示数量 > 0 的项）
            ...WeekDay.order.where((k) => (weekCounts[k] ?? 0) > 0).map((key) {
              final count = weekCounts[key] ?? 0;
              final isSelected = activeWeek == key;
              final (bg, fg) = WeekDay.getColors(key);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildChip(
                  context,
                  label: WeekDay.getLabel(key),
                  count: count,
                  isSelected: isSelected,
                  customBg: bg,
                  customFg: fg,
                  onTap: () => onSelectWeek(isSelected ? '' : key),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    int? count,
    required bool isSelected,
    Color? customBg,
    Color? customFg,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    Color border;

    if (isSelected) {
      bg = customBg ?? theme.colorScheme.primary;
      fg = customFg ?? Colors.white;
      border = customFg ?? theme.colorScheme.primary;
    } else {
      bg = isDark ? const Color(0xFF27272A) : const Color(0xFFFFFFFF);
      fg = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);
      border = isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: isSelected ? 1.5 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: border.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (customFg != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: customFg,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: fg,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
