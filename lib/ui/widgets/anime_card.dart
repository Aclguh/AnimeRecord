import 'package:flutter/material.dart';
import '../../models/anime_record.dart';
import '../../models/app_constants.dart';
import '../theme/app_theme.dart';
import 'anime_cover_image.dart';
import 'badges/anime_air_status_badge.dart';
import 'badges/anime_rating_badge.dart';
import 'badges/anime_status_badge.dart';
import 'badges/anime_week_badge.dart';

/// 单张番剧卡片组件（未设置海报时无缝恢复原生卡片布局与原生高度，设置海报时自适应图文混排）
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

    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final cardBg = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;

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
            // 内容主体：有海报链接时展示图文混排，无海报时完全采用原生卡片结构（无海报占位）
            if (hasCover)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCoverImage(context, record.coverUrl.trim()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCardContent(
                        context,
                        isDark: isDark,
                        statusColor: statusColor,
                        statusSoftColor: statusSoftColor,
                        isCompleted: isCompleted,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildCardContent(
                  context,
                  isDark: isDark,
                  statusColor: statusColor,
                  statusSoftColor: statusSoftColor,
                  isCompleted: isCompleted,
                  compact: false,
                ),
              ),
            const Spacer(),
            // 卡片底部操作栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 15,
                            color: isDark ? AppTheme.textSubDark : AppTheme.textSubLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '编辑',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppTheme.textSubDark : AppTheme.textSubLight,
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
                      color: isDark ? AppTheme.textSubDark : AppTheme.textMutedLight,
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
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textSubDark,
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

  Widget _buildCardContent(
    BuildContext context, {
    required bool isDark,
    required Color statusColor,
    required Color statusSoftColor,
    required bool isCompleted,
    required bool compact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 徽标区（状态、更新日、播放状态、评分）
        Wrap(
          spacing: 6,
          runSpacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // 状态徽标
            AnimeStatusBadge(
              status: record.status,
              color: statusColor,
              softColor: statusSoftColor,
            ),
            // 更新日徽标
            if (record.week.isNotEmpty && WeekDay.order.contains(record.week))
              AnimeWeekBadge(week: record.week),
            // 播放状态徽标
            if (record.airStatus.isNotEmpty && AirStatus.allValues.contains(record.airStatus))
              AnimeAirStatusBadge(airStatus: record.airStatus),
            // 评分徽标
            if (record.rating > 0)
              AnimeRatingBadge(rating: record.rating, isDark: isDark),
          ],
        ),
        SizedBox(height: compact ? 8 : 12),
        // 中文名称
        Tooltip(
          message: record.titleZh,
          child: Text(
            record.titleZh.isEmpty ? '未命名番剧' : record.titleZh,
            style: TextStyle(
              fontSize: compact ? 16 : 16.5,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
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
                fontSize: compact ? 12 : 12.5,
                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        SizedBox(height: compact ? 8 : 12),
        // 集数信息与进度条
        _buildEpisodeSection(context, isCompleted),
      ],
    );
  }

  Widget _buildCoverImage(BuildContext context, String url) {
    return AnimeCoverImage(
      url: url,
      width: 68,
      height: 94,
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
                  color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
                ),
              ),
              Text(
                ' / ${record.episodesTotal}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                ),
              ),
              const Spacer(),
              Text(
                '剩 $remaining 集',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
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
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
        ),
      );
    }

    return Text(
      '尚未开始观看',
      style: TextStyle(
        fontSize: 12.5,
        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
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
