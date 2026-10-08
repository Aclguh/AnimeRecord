import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reorderables/reorderables.dart';
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

/// 主页界面
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

class _HomeScreenState extends State<HomeScreen> {
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.animeProvider.addListener(_onProviderUpdate);
  }

  @override
  void dispose() {
    widget.animeProvider.removeListener(_onProviderUpdate);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onProviderUpdate() {
    if (mounted) setState(() {});
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
    if (mounted) {
      Toast.show(
        context,
        res.message,
        type: res.success ? ToastType.success : ToastType.error,
      );
    }
  }

  Future<void> _handleExportShortcut() async {
    final jsonStr = ImportExportService.exportToJson(widget.animeProvider.allRecords);
    final filename =
        'anime-record-backup-${DateTime.now().toIso8601String().split('T').first.replaceAll('-', '')}.json';
    final path = await ImportExportService.saveJsonFile(filename: filename, content: jsonStr);
    if (mounted && path != null) {
      Toast.show(context, '已导出 ${widget.animeProvider.allRecords.length} 条记录', type: ToastType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.animeProvider;

    final isDefaultSort = provider.sortBy == SortOption.defaultSort;

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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  // 1. 统计概览栏
                  StatsBar(
                    totalRecords: provider.totalRecordsCount,
                    totalEpisodesWatched: provider.totalEpisodesWatched,
                    statusCounts: provider.statusCounts,
                  ),
                  const SizedBox(height: 16),

                  // 2. 工具栏 (状态 Tab, 搜索框, 排序下拉, 添加按钮)
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

                  // 3. 更新日筛选
                  WeekFilterBar(
                    activeWeek: provider.activeWeek,
                    weekCounts: provider.activeWeekCounts,
                    onSelectWeek: provider.setWeekFilter,
                  ),
                  const SizedBox(height: 18),

                  // 4. 番剧卡片网格列表 / 空状态
                  if (provider.pagedRecords.isEmpty)
                    _buildEmptyState(context)
                  else
                    _buildCardsGrid(context, isDefaultSort),

                  // 5. 加载更多
                  if (provider.hasMore) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: OutlinedButton(
                        onPressed: provider.loadMore,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('加载更多'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 36),
                ],
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
    final provider = widget.animeProvider;

    return AppBar(
      titleSpacing: 20,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF78CA0), Color(0xFFE6456A)],
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
            '看番记录',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      actions: [
        // 云端同步按钮
        OutlinedButton.icon(
          onPressed: provider.isSyncing ? null : _handleSync,
          icon: provider.isSyncing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync_rounded, size: 16),
          label: const Text('同步'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
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
          tooltip: '打开设置',
          icon: const Icon(Icons.settings_outlined, size: 20),
        ),
        const SizedBox(width: 14),
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
              color: isDark ? const Color(0xFF1C2029) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.movie_filter_outlined,
              size: 36,
              color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isTotalEmpty ? '还没有番剧记录' : '没有找到符合条件的番剧',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isTotalEmpty
                ? '点击「添加番剧」开始记录你的追番之旅吧！'
                : '没有找到符合条件的番剧，试试调整筛选条件吧！',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
            ),
          ),
          if (isTotalEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openAddDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('添加第一部番剧'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardsGrid(BuildContext context, bool isDefaultSort) {
    final records = widget.animeProvider.pagedRecords;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth >= 1050) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 680) {
          crossAxisCount = 2;
        }

        final double itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;

        // 如果在默认排序模式下，支持拖拽排序！
        if (isDefaultSort) {
          return ReorderableWrap(
            spacing: 16,
            runSpacing: 16,
            onReorder: (oldIndex, newIndex) {
              widget.animeProvider.reorder(oldIndex, newIndex);
            },
            children: records.map((record) {
              return SizedBox(
                key: ValueKey(record.id),
                width: itemWidth,
                height: 196,
                child: AnimeCard(
                  record: record,
                  onEdit: () => _openEditDialog(record),
                  onDelete: () => _handleDeleteCard(record),
                  onEpisodePlusOne: () => _handleEpisodePlusOne(record),
                ),
              );
            }).toList(),
          );
        }

        // 普通布局展示
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: records.map((record) {
            return SizedBox(
              key: ValueKey(record.id),
              width: itemWidth,
              height: 196,
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
}
