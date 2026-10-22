import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:reorderables/reorderables.dart';
import '../../l10n/l10n.dart';
import '../../models/anime_record.dart';
import '../../models/app_constants.dart';
import '../../services/import_export_service.dart';
import '../../state/anime_provider.dart';
import '../../state/theme_provider.dart';
import '../dialogs/anime_form_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../widgets/anime_card.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/filter_toolbar.dart';
import '../widgets/stats_bar.dart';
import '../widgets/toast_overlay.dart';
import '../widgets/week_filter_bar.dart';

/// 主页界面（采用细粒度局部重绘隔离、Sliver 视口虚拟化网格、支持下拉刷新与响应式布局）
class HomeScreen extends StatefulWidget {
  final AnimeProvider animeProvider;
  final ThemeProvider themeProvider;

  const HomeScreen({
    super.key,
    required this.animeProvider,
    required this.themeProvider,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollAreaKey = GlobalKey();

  bool _isDragging = false;
  double _lastPointerY = 0;
  Ticker? _autoScrollTicker;
  DateTime _lastLoadMoreTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _autoScrollTicker = createTicker(_onAutoScrollTick);
  }

  @override
  void dispose() {
    _autoScrollTicker?.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onAutoScrollTick(Duration elapsed) {
    if (!_isDragging || !_scrollController.hasClients) return;

    final renderBox = _scrollAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final globalOffset = renderBox.localToGlobal(Offset.zero);
    final topBound = globalOffset.dy;
    final bottomBound = globalOffset.dy + renderBox.size.height;

    const double edgeZone = 140.0; // 边缘感应区域大小（像素）
    double velocity = 0.0; // 滚动速度（像素/秒，负数往上滚，正数往下滚）

    if (_lastPointerY < topBound + edgeZone) {
      // 靠近上边界：上翻/往上滚动
      final distance = (_lastPointerY - topBound).clamp(0.0, edgeZone);
      final ratio = (edgeZone - distance) / edgeZone; // 越靠近边缘越接近 1.0
      velocity = -(120.0 + ratio * ratio * 880.0); // 120 ~ 1000 px/s
    } else if (_lastPointerY > bottomBound - edgeZone) {
      // 靠近下边界：下翻/往下滚动
      final distance = (bottomBound - _lastPointerY).clamp(0.0, edgeZone);
      final ratio = (edgeZone - distance) / edgeZone; // 越靠近边缘越接近 1.0
      velocity = 120.0 + ratio * ratio * 880.0; // 120 ~ 1000 px/s
    }

    if (velocity != 0.0) {
      final double delta = velocity * 0.016; // 16ms 步长
      final currentOffset = _scrollController.offset;
      final maxOffset = _scrollController.position.maxScrollExtent;
      final newOffset = (currentOffset + delta).clamp(0.0, maxOffset);

      if (newOffset != currentOffset) {
        _scrollController.jumpTo(newOffset);
      }

      // 如果往下滚动且接近底部，并且还有更多数据，自动触发 loadMore 下翻页
      if (velocity > 0 && currentOffset >= maxOffset - 180) {
        final now = DateTime.now();
        if (now.difference(_lastLoadMoreTime).inMilliseconds > 450) {
          _lastLoadMoreTime = now;
          if (widget.animeProvider.hasMore) {
            widget.animeProvider.loadMore();
          }
        }
      }
    }
  }

  void _startAutoScroll() {
    _isDragging = true;
    if (_autoScrollTicker != null && !_autoScrollTicker!.isActive) {
      _autoScrollTicker!.start();
    }
  }

  void _stopAutoScroll() {
    _isDragging = false;
    if (_autoScrollTicker != null && _autoScrollTicker!.isActive) {
      _autoScrollTicker!.stop();
    }
  }

  void _openAddDialog() {
    AnimeFormDialog.show(
      context,
      onSave: (newRecord) async {
        final res = await widget.animeProvider.addRecord(newRecord);
        if (mounted && res != null) {
          Toast.show(context, '「${res.titleZh}」已添加', type: ToastType.success);
        }
      },
    );
  }

  void _openEditDialog(AnimeRecord record) {
    AnimeFormDialog.show(
      context,
      initialRecord: record,
      onSave: (updated) async {
        final res = await widget.animeProvider.updateRecord(record.id, updated);
        if (mounted && res != null) {
          Toast.show(context, '「${res.titleZh}」已更新', type: ToastType.success);
        }
      },
      onDelete: () async {
        final ok = await widget.animeProvider.deleteRecord(record.id);
        if (mounted && ok) {
          Toast.show(context, '「${record.titleZh}」已删除', type: ToastType.success);
        }
      },
    );
  }

  Future<void> _handleDeleteCard(AnimeRecord record) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '删除番剧',
      message: '确定要删除「${record.titleZh.isEmpty ? "未命名番剧" : record.titleZh}」吗？此操作不可撤销。',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final ok = await widget.animeProvider.deleteRecord(record.id);
      if (mounted && ok) {
        Toast.show(context, '「${record.titleZh}」已删除', type: ToastType.success);
      }
    }
  }

  Future<void> _handleEpisodePlusOne(AnimeRecord record) async {
    final result = await widget.animeProvider.episodePlusOne(record.id);
    if (mounted && result.statusChangedMessage != null) {
      Toast.show(context, result.statusChangedMessage!, type: ToastType.info);
    }
  }

  Future<void> _handleSync() async {
    final res = await widget.animeProvider.performSync(silent: false);
    if (!mounted) return;

    if (res.isCliff) {
      final confirmForce = await ConfirmDialog.show(
        context,
        title: '同步数据保护提醒',
        message: '检测到云端与本地合并后数据量骤降（原基准为 ${res.baselineCount} 部，合并后仅剩 ${res.mergedCount} 部）。\n\n'
            '这通常发生在误清空或更换空 Gist 时。若这是您的预期删除操作，请选择「强制覆盖同步」。',
        confirmText: '强制覆盖同步',
        cancelText: '取消',
        isDestructive: true,
      );

      if (confirmForce == true && mounted) {
        final forceRes = await widget.animeProvider.performSync(silent: false, force: true);
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
    final jsonStr = await ImportExportService.exportToJsonAsync(widget.animeProvider.allRecords);
    final filename =
        'anime-record-backup-${DateTime.now().toIso8601String().split('T').first.replaceAll('-', '')}.json';
    final path = await ImportExportService.saveJsonFile(filename: filename, content: jsonStr);
    if (mounted && path != null) {
      Toast.show(context, '已导出 ${widget.animeProvider.allRecords.length} 条记录', type: ToastType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _openAddDialog,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _handleExportShortcut,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: _buildHeader(context),
          body: Listener(
            onPointerDown: (e) => _lastPointerY = e.position.dy,
            onPointerMove: (e) => _lastPointerY = e.position.dy,
            onPointerUp: (_) => _stopAutoScroll(),
            onPointerCancel: (_) => _stopAutoScroll(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: RefreshIndicator(
                  onRefresh: _handleSync,
                  color: Theme.of(context).colorScheme.primary,
                  child: ListenableBuilder(
                    listenable: widget.animeProvider,
                    builder: (context, _) {
                      final provider = widget.animeProvider;
                      final isDefaultSort = provider.sortBy == SortOption.defaultSort;

                      return Container(
                        key: _scrollAreaKey,
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          interactive: true,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            slivers: [
                              // 1. 顶部控制栏区域（统计栏带防抖缓存隔离、工具栏与周几过滤）
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _HomeScreenStatsBar(animeProvider: provider),
                                      const SizedBox(height: 14),
                                      FilterToolbar(
                                        activeStatus: provider.activeStatus,
                                        statusCounts: provider.statusCounts,
                                        searchQuery: provider.searchQuery,
                                        sortBy: provider.sortBy,
                                        onSelectStatus: provider.setStatusFilter,
                                        onSearchChanged: provider.setSearchQuery,
                                        onSortChanged: provider.setSortBy,
                                        onAddAnime: _openAddDialog,
                                      ),
                                      const SizedBox(height: 14),
                                      WeekFilterBar(
                                        activeWeek: provider.activeWeek,
                                        weekCounts: provider.activeWeekCounts,
                                        onSelectWeek: provider.setWeekFilter,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // 2. 番剧卡片网格列表 / 空状态
                              if (provider.pagedRecords.isEmpty)
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  sliver: SliverToBoxAdapter(
                                    child: _buildEmptyState(context),
                                  ),
                                )
                              else if (isDefaultSort)
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  sliver: SliverToBoxAdapter(
                                    child: _buildReorderableCards(context, provider),
                                  ),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  sliver: _buildVirtualizedCardsGrid(context, provider),
                                ),

                              // 3. 加载更多与底部留白
                              if (provider.hasMore)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 24, bottom: 36),
                                    child: Center(
                                      child: OutlinedButton(
                                        onPressed: provider.loadMore,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: const Text('加载更多'),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 36),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
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
          listenable: widget.animeProvider,
          builder: (context, _) {
            final isSyncing = widget.animeProvider.isSyncing;
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
          onPressed: () => widget.themeProvider.toggleTheme(context),
          tooltip: isDark ? '切换浅色主题' : '切换深色主题',
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 20,
          ),
        ),
        const SizedBox(width: 4),

        // 设置按钮
        IconButton(
          onPressed: () => SettingsDialog.show(context, widget.animeProvider),
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
    final isTotalEmpty = widget.animeProvider.allRecords.isEmpty;

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
            isTotalEmpty ? (context.l10nOrNull?.emptyStateTitle ?? '还没有番剧记录') : '没有找到符合条件的番剧',
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
                : '没有找到符合条件的番剧，试试调整筛选条件吧！',
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

  Widget _buildReorderableCards(BuildContext context, AnimeProvider provider) {
    final records = provider.pagedRecords;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth >= 1050) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 660) {
          crossAxisCount = 2;
        }

        final double itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 14) / crossAxisCount;

        return ReorderableWrap(
          spacing: 14,
          runSpacing: 14,
          onReorderStarted: (_) => _startAutoScroll(),
          onReorder: (oldIndex, newIndex) {
            _stopAutoScroll();
            provider.reorder(oldIndex, newIndex);
          },
          onNoReorder: (_) => _stopAutoScroll(),
          children: records.map((record) {
            final double cardHeight = record.coverUrl.trim().isNotEmpty ? 212 : 210;
            return SizedBox(
              key: ValueKey(record.id),
              width: itemWidth,
              height: cardHeight,
              child: AnimeCard(
                record: record,
                onEdit: () => _openEditDialog(record),
                onDelete: () => _handleDeleteCard(record),
                onEpisodePlusOne: () => _handleEpisodePlusOne(record),
              ),
            );
          }).toList(),
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

        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 212,
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

/// 具备值变化比对与 Widget 实例缓存的统计栏，避免在搜索框输入或切换周几时触发非必要重绘
class _HomeScreenStatsBar extends StatefulWidget {
  final AnimeProvider animeProvider;

  const _HomeScreenStatsBar({required this.animeProvider});

  @override
  State<_HomeScreenStatsBar> createState() => _HomeScreenStatsBarState();
}

class _HomeScreenStatsBarState extends State<_HomeScreenStatsBar> {
  int _lastTotal = -1;
  int _lastEpisodes = -1;
  Map<String, int> _lastCounts = const {};
  Widget? _cachedWidget;

  @override
  Widget build(BuildContext context) {
    final total = widget.animeProvider.totalRecordsCount;
    final episodes = widget.animeProvider.totalEpisodesWatched;
    final counts = widget.animeProvider.statusCounts;

    if (_cachedWidget != null &&
        _lastTotal == total &&
        _lastEpisodes == episodes &&
        mapEquals(_lastCounts, counts)) {
      return _cachedWidget!;
    }

    _lastTotal = total;
    _lastEpisodes = episodes;
    _lastCounts = Map.of(counts);
    _cachedWidget = StatsBar(
      totalRecords: total,
      totalEpisodesWatched: episodes,
      statusCounts: _lastCounts,
    );
    return _cachedWidget!;
  }
}

