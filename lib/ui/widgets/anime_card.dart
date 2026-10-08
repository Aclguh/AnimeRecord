import 'package:flutter/material.dart';
import '../../models/anime_record.dart';
import '../../models/app_constants.dart';

/// 单张番剧卡片组件
class AnimeCard extends StatelessWidget {
  final AnimeRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onEpisodePlusOne;

  const AnimeCard({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
    required this.onEpisodePlusOne,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statusColor = AnimeStatus.getColor(record.status, isDark: isDark);
    final statusSoftColor = AnimeStatus.getSoftColor(record.status, isDark: isDark);

    final borderColor = isDark ? const Color(0xFF262B37) : const Color(0xFFE9EAF0);
    final cardBg = isDark ? const Color(0xFF171A22) : Colors.white;

    final isCompleted = record.status == AnimeStatus.watched ||
        (record.episodesTotal > 0 && record.episodesWatched >= record.episodesTotal);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部状态强调色线条
            Container(
              height: 3.5,
              color: statusColor,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 徽标区（状态、更新日、播放状态）
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // 状态徽标
                      _buildStatusBadge(record.status, statusColor, statusSoftColor),
                      // 更新日徽标
                      if (record.week.isNotEmpty && WeekDay.order.contains(record.week))
                        _buildWeekBadge(record.week),
                      // 播放状态徽标
                      if (record.airStatus.isNotEmpty && AirStatus.allValues.contains(record.airStatus))
                        _buildAirStatusBadge(record.airStatus),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 中文名称
                  Tooltip(
                    message: record.titleZh,
                    child: Text(
                      record.titleZh.isEmpty ? '未命名番剧' : record.titleZh,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430),
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 日文名称
                  if (record.titleJa.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Tooltip(
                      message: record.titleJa,
                      child: Text(
                        record.titleJa,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // 集数信息与进度条
                  _buildEpisodeSection(context, isCompleted),
                ],
              ),
            ),
            const Spacer(),
            // 卡片底部操作栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14171E) : const Color(0xFFFBFBFD),
                border: Border(
                  top: BorderSide(color: borderColor, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  // 编辑按钮
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 15,
                            color: isDark ? const Color(0xFFA8B0C0) : const Color(0xFF59617A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '编辑',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFFA8B0C0) : const Color(0xFF59617A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 删除按钮
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFF9AA4B8) : const Color(0xFF98A0B3),
                    ),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: '删除记录',
                  ),
                  const Spacer(),
                  // 最后修改时间
                  if (record.formatRelativeUpdatedAt().isNotEmpty)
                    Tooltip(
                      message: '最后修改：${record.formatFullUpdatedAt()}',
                      child: Text(
                        record.formatRelativeUpdatedAt(),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  // +1 集 按钮 / 已追完 状态
                  _buildEpisodeButton(context, isCompleted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color, Color softColor) {
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

  Widget _buildWeekBadge(String week) {
    final (bg, fg) = WeekDay.getColors(week);
    return Tooltip(
      message: '更新频率：${WeekDay.getFullLabel(week)}',
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

  Widget _buildAirStatusBadge(String airStatus) {
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

  Widget _buildEpisodeSection(BuildContext context, bool isCompleted) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (record.episodesTotal > 0) {
      final remaining = (record.episodesTotal - record.episodesWatched).clamp(0, record.episodesTotal);
      final progress = (record.episodesWatched / record.episodesTotal).clamp(0.0, 1.0);

      if (isCompleted || remaining <= 0) {
        return Row(
          children: [
            const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
            const SizedBox(width: 5),
            Text(
              '已完成 ${record.episodesTotal} 集',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${record.episodesWatched}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430),
                ),
              ),
              Text(
                ' / ${record.episodesTotal}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
                ),
              ),
              const Spacer(),
              Text(
                '剩 $remaining 集',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFA8B0C0) : const Color(0xFF59617A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isDark ? const Color(0xFF262B37) : const Color(0xFFE9EAF0),
              valueColor: AlwaysStoppedAnimation(
                AnimeStatus.getColor(record.status, isDark: isDark),
              ),
            ),
          ),
        ],
      );
    }

    if (record.episodesWatched > 0) {
      return Text(
        '已看 ${record.episodesWatched} 集',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430),
        ),
      );
    }

    return Text(
      '尚未开始观看',
      style: TextStyle(
        fontSize: 12.5,
        color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
      ),
    );
  }

  Widget _buildEpisodeButton(BuildContext context, bool isCompleted) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 14, color: Color(0xFF10B981)),
            SizedBox(width: 4),
            Text(
              '已追完',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);

    return InkWell(
      onTap: onEpisodePlusOne,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Text(
          '+1 集',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
