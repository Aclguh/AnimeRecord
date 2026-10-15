import 'package:flutter/material.dart';
import '../../../models/app_constants.dart';

/// 设置弹窗 - 通用设置部分（默认打开状态与屏幕旋转偏好）
class GeneralSettingsSection extends StatelessWidget {
  final String defaultStatus;
  final ValueChanged<String> onDefaultStatusChanged;
  final bool followScreenRotation;
  final ValueChanged<bool> onFollowScreenRotationChanged;
  final Color borderColor;

  const GeneralSettingsSection({
    super.key,
    required this.defaultStatus,
    required this.onDefaultStatusChanged,
    required this.followScreenRotation,
    required this.onFollowScreenRotationChanged,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statusOptions = [
      ('all', '全部'),
      (AnimeStatus.wantToWatch, '想看'),
      (AnimeStatus.watching, '在看'),
      (AnimeStatus.watched, '看过'),
      (AnimeStatus.onHold, '搁置'),
      (AnimeStatus.dropped, '抛弃'),
    ];

    final currentOption = statusOptions.firstWhere(
      (e) => e.$1 == defaultStatus,
      orElse: () => ('watching', '在看'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. 默认打开的页面
        _buildSectionHeader(context, '默认打开的页面'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statusOptions.map((opt) {
            final val = opt.$1;
            final label = opt.$2;
            final isSelected = defaultStatus == val;

            return InkWell(
              onTap: () => onDefaultStatusChanged(val),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? const Color(0xFF1C2029) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          '打开应用时默认展示「${currentOption.$2}」分类',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
          ),
        ),
        const SizedBox(height: 18),
        Divider(color: borderColor, height: 1),
        const SizedBox(height: 18),

        // 2. 界面与显示设置（跟随屏幕选择）
        _buildSectionHeader(context, '界面与显示'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14171E) : const Color(0xFFFBFBFD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '跟随屏幕选择',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '允许应用跟随屏幕方向旋转至横屏（默认关闭，保持竖屏锁定）',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: followScreenRotation,
                activeThumbColor: theme.colorScheme.primary,
                onChanged: onFollowScreenRotationChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430),
      ),
    );
  }
}
