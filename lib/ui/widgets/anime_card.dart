import 'package:flutter/material.dart';
import '../../models/anime_record.dart';
import '../../models/app_constants.dart';

/// 单张番剧卡片组件（支持封面缩略图、评分徽章、标签芯片与高对比无障碍排版）
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

    final borderColor = isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7);
    final cardBg = isDark ? const Color(0xFF27272A) : Colors.white;

    final isCompleted = record.status == AnimeStatus.watched ||
        (record.episodesTotal > 0 && record.episodesWatched >= record.episodesTotal);

    final hasCover = record.coverUrl.trim().isNotEmpty;

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
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 可选海报封面缩略图
                  if (hasCover) ...[
                    _buildCoverImage(context, record.coverUrl.trim()),
                    const SizedBox(width: 12),
                  ],
                  // 卡片核心信息区
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 徽标区（状态、更新日、播放状态、评分）
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
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
                            // 评分徽标
                            if (record.rating > 0)
                              _buildRatingBadge(record.rating, isDark),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 中文名称
                        Tooltip(
                          message: record.titleZh,
                          child: Text(
                            record.titleZh.isEmpty ? '未命名番剧' : record.titleZh,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 日文名称
                        if (record.titleJa.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Tooltip(
                            message: record.titleJa,
                            child: Text(
                              record.titleJa,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        // 标签预览 (前2个)
                        if (record.tags.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: record.tags.take(2).map((t) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#$t',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 10),
                        // 集数进度条
                        _buildEpisodeSection(context, isCompleted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // 卡片底部操作栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222226) : const Color(0xFFFAFAF9),
                border: Border(
                  top: BorderSide(color: borderColor, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  // 编辑按钮
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 15,
                            color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '编辑',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 删除按钮（扩大触控尺寸）
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 17,
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                    ),
                    splashRadius: 18,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
                          color: isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
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

  Widget _buildCoverImage(BuildContext context, String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 68,
        height: 94,
        color: const Color(0xFF1E2025),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 24,
                color: Color(0xFF71717A),
              ),
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
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

  Widget _buildRatingBadge(double rating, bool isDark) {
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
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
                ),
              ),
              Text(
                ' / ${record.episodesTotal}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                ),
              ),
              const Spacer(),
              Text(
                '剩 $remaining 集',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
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
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
        ),
      );
    }

    return Text(
      '尚未开始观看',
      style: TextStyle(
        fontSize: 12,
        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
      ),
    );
  }

  Widget _buildEpisodeButton(BuildContext context, bool isCompleted) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 13, color: Color(0xFF10B981)),
            SizedBox(width: 3),
            Text(
              '已追完',
              style: TextStyle(
                fontSize: 11.5,
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
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
