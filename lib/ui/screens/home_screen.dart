import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/l10n.dart';
import '../../models/anime_record.dart';
import '../../models/app_constants.dart';
import '../../services/import_export_service.dart';
import '../../state/anime_filter_controller.dart';
import '../../state/anime_provider.dart';
import '../../state/anime_scope.dart';
import '../../state/locale_provider.dart';
import '../../state/theme_provider.dart';
import '../dialogs/anime_form_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../widgets/anime_card.dart';
import '../widgets/anime_cover_image.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/filter_toolbar.dart';
import '../widgets/stats_bar.dart';
import '../widgets/toast_overlay.dart';
import '../widgets/week_filter_bar.dart';

/// 主页界面（采用细粒度局部重绘隔离、Sliver 视口虚拟化网格、支持下拉刷新与响应式布局）
class HomeScreen extends StatefulWidget {
  final AnimeProvider? animeProvider;
  final ThemeProvider? themeProvider;
  final LocaleProvider? localeProvider;

  const HomeScreen({
    super.key,
    this.animeProvider,
    this.themeProvider,
    this.localeProvider,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollAreaKey = GlobalKey();

  bool _isReorderingMode = false;

  AnimeProvider get _animeProvider => widget.animeProvider ?? context.animeProvider;
  ThemeProvider get _themeProvider => widget.themeProvider ?? context.themeProvider;
  LocaleProvider? get _localeProvider => widget.localeProvider ?? AnimeScope.maybeOf(context)?.localeProvider;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openAddDialog() {
    AnimeFormDialog.show(
      context,
      onSave: (newRecord) async {
        final res = await _animeProvider.addRecord(newRecord);
        if (mounted && res != null) {
          final title = res.titleZh.isEmpty ? (context.l10nOrNull?.unnamedAnime ?? '未命名番剧') : res.titleZh;
          Toast.show(
            context,
            context.l10nOrNull?.animeAddedSuccess(title) ?? '「$title」已添加',
            type: ToastType.success,
          );
        }
      },
    );
  }

  void _openEditDialog(AnimeRecord record) {
    AnimeFormDialog.show(
      context,
      initialRecord: record,
      onSave: (updated) async {
        final res = await _animeProvider.updateRecord(record.id, updated);
        if (mounted && res != null) {
          final title = res.titleZh.isEmpty ? (context.l10nOrNull?.unnamedAnime ?? '未命名番剧') : res.titleZh;
          Toast.show(
            context,
            context.l10nOrNull?.animeUpdatedSuccess(title) ?? '「$title」已更新',
            type: ToastType.success,
          );
        }
      },
      onDelete: () async {
        final ok = await _animeProvider.deleteRecord(record.id);
        if (mounted && ok) {
          final title = record.titleZh.isEmpty ? (context.l10nOrNull?.unnamedAnime ?? '未命名番剧') : record.titleZh;
          Toast.show(
            context,
            context.l10nOrNull?.animeDeletedSuccess(title) ?? '「$title」已删除',
            type: ToastType.success,
          );
        }
      },
    );
  }

  Future<void> _handleDeleteCard(AnimeRecord record) async {
    final title = record.titleZh.isEmpty ? (context.l10nOrNull?.unnamedAnime ?? '未命名番剧') : record.titleZh;
    final confirmed = await ConfirmDialog.show(
      context,
      title: context.l10nOrNull?.deleteAnime ?? '删除番剧',
      message: context.l10nOrNull?.deleteAnimeConfirm(title) ??
          '确定要删除「$title」吗？此操作不可撤销。',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final ok = await _animeProvider.deleteRecord(record.id);
      if (mounted && ok) {
        Toast.show(
          context,
          context.l10nOrNull?.animeDeletedSuccess(title) ?? '「$title」已删除',
          type: ToastType.success,
        );
      }
    }
  }

  Future<void> _handleEpisodePlusOne(AnimeRecord record) async {
    final result = await _animeProvider.episodePlusOne(record.id);
    if (!mounted) return;

    if (result.transitionedStatus != null) {
      final title = record.titleZh.isEmpty
          ? (context.l10nOrNull?.unnamedAnime ?? '未命名番剧')
          : record.titleZh;
      final msg = switch (result.transitionedStatus!) {
        WatchStatus.watched =>
          context.l10nOrNull?.statusChangedWatched(title) ?? '「$title」已追完',
        WatchStatus.watching =>
          context.l10nOrNull?.statusChangedWatching(title) ?? '「$title」状态已切换为「在看」',
        _ => result.statusChangedMessage,
      };
      if (msg != null) {
        Toast.show(context, msg, type: ToastType.info);
      }
    } else if (result.statusChangedMessage != null) {
      Toast.show(context, result.statusChangedMessage!, type: ToastType.info);
    }
  }

  Future<void> _handleSync() async {
    final res = await _animeProvider.performSync(silent: false);
    if (!mounted) return;

    if (res.isCliff) {
      final confirmForce = await ConfirmDialog.show(
        context,
        title: context.l10nOrNull?.cliffTitle ?? '同步数据保护提醒',
        message: context.l10nOrNull?.cliffMessage(res.baselineCount, res.mergedCount) ??
            '检测到云端与本地合并后数据量骤降（原基准为 ${res.baselineCount} 部，合并后仅剩 ${res.mergedCount} 部）。\n\n'
            '这通常发生在误清空或更换空 Gist 时。若这是您的预期删除操作，请选择「强制覆盖同步」。',
        confirmText: context.l10nOrNull?.cliffForceSync ?? '强制覆盖同步',
        cancelText: context.l10nOrNull?.cancel ?? '取消',
        isDestructive: true,
      );

      if (confirmForce == true && mounted) {
        final forceRes = await _animeProvider.performSync(silent: false, force: true);
        if (mounted) {
          Toast.show(
            context,
            forceRes.message,
            type: forceRes.success ? ToastType.success : ToastType.error,
          );
        }
      }
      return;
    }

    Toast.show(
      context,
      res.message,
      type: res.success ? ToastType.success : ToastType.error,
    );
  }

  Future<void> _handleExportShortcut() async {
    final jsonStr = await ImportExportService.exportToJsonAsync(_animeProvider.allRecords);
    final filename =
        'anime-record-backup-${DateTime.now().toIso8601String().split('T').first.replaceAll('-', '')}.json';
    final path = await ImportExportService.saveJsonFile(filename: filename, content: jsonStr);
    if (mounted && path != null) {
      final l10n = context.l10nOrNull;
      final count = _animeProvider.allRecords.length;
      Toast.show(
        context,
        l10n?.exportSuccess(count) ?? '已导出 $count 条记录',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10nOrNull;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _openAddDialog,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _handleExportShortcut,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: _buildHeader(context),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: RefreshIndicator(
                onRefresh: _handleSync,
                color: Theme.of(context).colorScheme.primary,
                child: Container(
                  key: _scrollAreaKey,
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    interactive: true,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      slivers: [
                        // 1. 顶部统计栏（细粒度隔离：仅在底层仓储数据增删改时重绘，不受搜索框输入或周几切换影响）
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: ListenableBuilder(
                              listenable: _animeProvider.repository,
                              builder: (context, _) {
                                final repo = _animeProvider.repository;
                                return StatsBar(
                                  totalRecords: repo.records.length,
                                  totalEpisodesWatched:
                                      repo.records.fold(0, (sum, r) => sum + r.episodesWatched),
                                  statusCounts:
                                      AnimeFilterController.computeStatusCounts(repo.records),
                                );
                              },
                            ),
                          ),
                        ),

                        // 2. 过滤与搜索工具栏区域
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          sliver: SliverToBoxAdapter(
                            child: ListenableBuilder(
                              listenable: Listenable.merge([
                                _animeProvider.filterController,
                                _animeProvider.repository,
                              ]),
                              builder: (context, _) {
                                final provider = _animeProvider;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    FilterToolbar(
                                      activeStatus: provider.activeStatus,
                                      statusCounts: provider.statusCounts,
                                      searchQuery: provider.searchQuery,
                                      sortBy: provider.sortBy,
                                      onSelectStatus: provider.setStatusFilter,
                                      onSearchChanged: provider.setSearchQuery,
                                      onSortChanged: (sort) {
                                        if (sort != SortOption.defaultSort && _isReorderingMode) {
                                          setState(() => _isReorderingMode = false);
                                        }
                                        provider.setSortBy(sort);
                                      },
                                      onAddAnime: _openAddDialog,
                                      onToggleReorderMode: () {
                                        setState(() => _isReorderingMode = !_isReorderingMode);
                                      },
                                      isReorderingMode: _isReorderingMode,
                                    ),
                                    const SizedBox(height: 14),
                                    WeekFilterBar(
                                      activeWeek: provider.activeWeek,
                                      weekCounts: provider.activeWeekCounts,
                                      onSelectWeek: provider.setWeekFilter,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),

                        // 3. 番剧卡片网格列表 / 调整顺序列表 / 空状态 / 分页加载
                        ListenableBuilder(
                          listenable: _animeProvider,
                          builder: (context, _) {
                            final provider = _animeProvider;
                            final isDefaultSort = provider.sortBy == SortOption.defaultSort;

                            return SliverMainAxisGroup(
                              slivers: [
                                if (provider.pagedRecords.isEmpty)
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    sliver: SliverToBoxAdapter(
                                      child: _buildEmptyState(context),
                                    ),
                                  )
                                else if (_isReorderingMode && isDefaultSort) ...[
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                    sliver: SliverToBoxAdapter(
                                      child: _buildReorderHeader(context),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    sliver: _buildSliverReorderList(context, provider),
                                  ),
                                ]
                                else
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    sliver: _buildVirtualizedCardsGrid(context, provider),
                                  ),

                                // 加载更多与底部留白
                                if (provider.hasMore && !_isReorderingMode)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 24, bottom: 36),
                                      child: Center(
                                        child: OutlinedButton(
                                          onPressed: provider.loadMore,
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 28, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: Text(l10n?.loadMore ?? '加载更多'),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  const SliverToBoxAdapter(
                                    child: SizedBox(height: 36),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC5F7A), Color(0xFFFF7E95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.smart_display_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            context.l10nOrNull?.appTitle ?? '看番记录',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      actions: [
        // 云端同步按钮
        ListenableBuilder(
          listenable: _animeProvider.repository,
          builder: (context, _) {
            final isSyncing = _animeProvider.repository.isSyncing;
            return OutlinedButton.icon(
              onPressed: isSyncing ? null : _handleSync,
              icon: isSyncing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded, size: 16),
              label: Text(context.l10nOrNull?.sync ?? '同步'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          },
        ),
        const SizedBox(width: 8),

        // 主题切换按钮
        IconButton(
          onPressed: () => _themeProvider.toggleTheme(context),
          tooltip: isDark
              ? (context.l10nOrNull?.switchToLightTheme ?? '切换浅色主题')
              : (context.l10nOrNull?.switchToDarkTheme ?? '切换深色主题'),
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 20,
          ),
        ),
        const SizedBox(width: 4),

        // 设置按钮
        IconButton(
          onPressed: () => SettingsDialog.show(
            context,
            _animeProvider,
            localeProvider: _localeProvider,
          ),
          tooltip: context.l10nOrNull?.settings ?? '打开设置',
          icon: const Icon(Icons.settings_outlined, size: 20),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTotalEmpty = _animeProvider.allRecords.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.movie_filter_outlined,
              size: 36,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isTotalEmpty ? (context.l10nOrNull?.emptyStateTitle ?? '还没有番剧记录') : (context.l10nOrNull?.noMatchingAnime ?? '没有找到符合条件的番剧'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isTotalEmpty
                ? (context.l10nOrNull?.emptyStateSubtitle ?? '点击「添加番剧」开始记录你的追番之旅吧！')
                : (context.l10nOrNull?.noMatchingAnimeSubtitle ?? '没有找到符合条件的番剧，试试调整筛选条件吧！'),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
            ),
          ),
          if (isTotalEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openAddDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(context.l10nOrNull?.emptyStateAction ?? '添加第一部番剧'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReorderHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222226) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.swap_vert_rounded, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10nOrNull?.reorderTip ?? '长按并拖动右侧手柄调整番剧排序',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _isReorderingMode = false),
            child: Text(context.l10nOrNull?.done ?? '完成'),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverReorderList(BuildContext context, AnimeProvider provider) {
    final records = provider.pagedRecords;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverReorderableList(
      itemCount: records.length,
      onReorderItem: (oldIndex, newIndex) {
        final targetIndex = oldIndex < newIndex ? newIndex + 1 : newIndex;
        provider.reorder(oldIndex, targetIndex);
      },
      itemBuilder: (context, index) {
        final record = records[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(record.id),
          index: index,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222226) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: record.coverUrl.trim().isNotEmpty
                  ? AnimeCoverImage(url: record.coverUrl.trim(), width: 40, height: 40)
                  : Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.movie_outlined,
                        size: 20,
                        color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                      ),
                    ),
              title: Text(
                record.titleZh.isEmpty ? (context.l10nOrNull?.unnamedAnime ?? '未命名番剧') : record.titleZh,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${AnimeStatus.getLabel(record.status)} · ${record.episodesWatched}/${record.episodesTotal > 0 ? record.episodesTotal : "?"} ${context.l10nOrNull?.episodes ?? "集"}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
                ),
              ),
              trailing: ReorderableDragStartListener(
                index: index,
                child: const MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.drag_handle_rounded, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVirtualizedCardsGrid(BuildContext context, AnimeProvider provider) {
    final records = provider.pagedRecords;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.crossAxisExtent >= 1050) {
          crossAxisCount = 3;
        } else if (constraints.crossAxisExtent >= 660) {
          crossAxisCount = 2;
        }

        final textScale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.45);
        final cardExtent = (226.0 * textScale).roundToDouble();

        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: cardExtent,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return AnimeCard(
              key: ValueKey(record.id),
              record: record,
              onEdit: () => _openEditDialog(record),
              onDelete: () => _handleDeleteCard(record),
              onEpisodePlusOne: () => _handleEpisodePlusOne(record),
            );
          },
        );
      },
    );
  }
}

