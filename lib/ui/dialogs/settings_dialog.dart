import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_constants.dart';
import '../../services/import_export_service.dart';
import '../../state/anime_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/toast_overlay.dart';

/// 设置弹窗（默认展示分类、GitHub Gist 云同步、本地数据导入导出）
class SettingsDialog extends StatefulWidget {
  final AnimeProvider animeProvider;

  const SettingsDialog({
    super.key,
    required this.animeProvider,
  });

  static Future<void> show(BuildContext context, AnimeProvider provider) {
    return showDialog(
      context: context,
      builder: (context) => SettingsDialog(animeProvider: provider),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late String _defaultStatus;
  late TextEditingController _tokenController;
  late TextEditingController _gistIdController;
  late bool _autoSync;
  late bool _followScreenSelection;

  final ScrollController _dialogScrollController = ScrollController();

  bool _isTokenVisible = false;
  bool _isTestingSync = false;
  bool _isCreatingGist = false;

  @override
  void initState() {
    super.initState();
    final p = widget.animeProvider;
    _defaultStatus = p.getDefaultStatus();
    _tokenController = TextEditingController(text: p.syncConfig.token);
    _gistIdController = TextEditingController(text: p.syncConfig.gistId);
    _autoSync = p.syncConfig.autoSync;
    _followScreenSelection = p.storage.loadFollowScreenRotation();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _gistIdController.dispose();
    _dialogScrollController.dispose();
    super.dispose();
  }

  void _saveSyncSettings({bool showToastMessage = true}) {
    final token = _tokenController.text.trim();
    final gistId = _gistIdController.text.trim();
    final updated = widget.animeProvider.syncConfig.copyWith(
      token: token,
      gistId: gistId,
      autoSync: _autoSync,
    );
    widget.animeProvider.setSyncConfig(updated);
    if (showToastMessage && mounted) {
      Toast.show(context, '云同步配置已保存', type: ToastType.success);
    }
  }

  Future<void> _testSync() async {
    final token = _tokenController.text.trim();
    final gistId = _gistIdController.text.trim();

    if (token.isEmpty) {
      Toast.show(context, '请先输入 GitHub Token', type: ToastType.info);
      return;
    }

    setState(() => _isTestingSync = true);
    try {
      final username = await widget.animeProvider.testToken(token);
      String gistInfo = '';
      if (gistId.isNotEmpty) {
        final count = await widget.animeProvider.checkGistCount(token, gistId);
        gistInfo = '，Gist 数据正常（云端含 $count 条记录）';
      }
      if (mounted) {
        Toast.show(
          context,
          '连接成功！GitHub 账号：$username$gistInfo',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          '测试失败：${e.toString().replaceFirst('Exception: ', '')}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingSync = false);
    }
  }

  Future<void> _createGist() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      Toast.show(context, '请先填写 GitHub Token', type: ToastType.error);
      return;
    }

    setState(() => _isCreatingGist = true);
    try {
      final gistId = await widget.animeProvider.autoCreateGist(token);
      _gistIdController.text = gistId;
      _saveSyncSettings(showToastMessage: false);

      if (mounted) {
        Toast.show(
          context,
          '已成功在 GitHub 创建私有 Gist 并完成绑定！',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          '创建 Gist 失败：${e.toString().replaceFirst('Exception: ', '')}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingGist = false);
    }
  }

  Future<void> _syncNow() async {
    _saveSyncSettings(showToastMessage: false);
    final res = await widget.animeProvider.performSync(silent: false);
    if (mounted) {
      Toast.show(
        context,
        res.message,
        type: res.success ? ToastType.success : ToastType.error,
      );
    }
  }

  Future<void> _handleExportData() async {
    try {
      final records = widget.animeProvider.allRecords;
      final jsonStr = ImportExportService.exportToJson(records);
      final filename =
          'anime-record-backup-${DateTime.now().toIso8601String().split('T').first.replaceAll('-', '')}.json';

      final path = await ImportExportService.saveJsonFile(
        filename: filename,
        content: jsonStr,
      );
      if (mounted && path != null) {
        Toast.show(context, '已导出 ${records.length} 条记录', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, '导出失败：$e', type: ToastType.error);
      }
    }
  }

  Future<void> _handleExportTemplate() async {
    try {
      final jsonStr = ImportExportService.exportTemplateJson();
      final path = await ImportExportService.saveJsonFile(
        filename: 'anime-record-template.json',
        content: jsonStr,
      );
      if (mounted && path != null) {
        Toast.show(context, '导入模板已下载保存', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        Toast.show(context, '导出模板失败：$e', type: ToastType.error);
      }
    }
  }

  Future<void> _handleImportData() async {
    try {
      final jsonStr = await ImportExportService.pickJsonFile();
      if (jsonStr == null || jsonStr.trim().isEmpty) return;

      final incoming = ImportExportService.parseImportJson(jsonStr);
      final current = widget.animeProvider.allRecords;

      bool replaceMode = false;
      if (current.isNotEmpty && mounted) {
        final choice = await showDialog<String>(
          context: context,
          builder: (ctx) => ConfirmDialog(
            title: '导入数据',
            customContent: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('发现 ${incoming.length} 条待导入记录。'),
                const SizedBox(height: 4),
                Text('当前已有 ${current.length} 条记录。'),
                const SizedBox(height: 10),
                const Text('请选择导入方式：'),
              ],
            ),
            cancelText: '取消',
            confirmText: '合并导入',
            extraActions: [
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop('replace'),
                child: const Text('替换全部'),
              ),
            ],
          ),
        );

        if (choice == null && mounted) return;
        replaceMode = choice == 'replace';
      }

      final ok = await widget.animeProvider.importRecords(incoming, replace: replaceMode);
      if (mounted) {
        if (ok) {
          Toast.show(
            context,
            replaceMode ? '已替换导入 ${incoming.length} 条记录' : '已成功合并导入记录',
            type: ToastType.success,
          );
        } else {
          Toast.show(context, '导入保存失败', type: ToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          '导入失败：${e.toString().replaceFirst('Exception: ', '')}',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isDark ? const Color(0xFF262B37) : const Color(0xFFE9EAF0);
    final isConfigured = widget.animeProvider.syncConfig.isConfigured;

    final statusOptions = [
      ('all', '全部'),
      (AnimeStatus.wantToWatch, '想看'),
      (AnimeStatus.watching, '在看'),
      (AnimeStatus.watched, '看过'),
      (AnimeStatus.onHold, '搁置'),
      (AnimeStatus.dropped, '抛弃'),
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 头部
              Row(
                children: [
                  Icon(Icons.settings_outlined, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '设置',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 主内容滚动区（带上下描边边界与滚动条显示）
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: borderColor, width: 1.0),
                      bottom: BorderSide(color: borderColor, width: 1.0),
                    ),
                  ),
                  child: Scrollbar(
                    controller: _dialogScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _dialogScrollController,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. 默认打开的页面
                          _buildSectionHeader('默认打开的页面'),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: statusOptions.map((opt) {
                              final val = opt.$1;
                              final label = opt.$2;
                              final isSelected = _defaultStatus == val;

                              return InkWell(
                                onTap: () {
                                  setState(() => _defaultStatus = val);
                                  widget.animeProvider.setDefaultStatus(val);
                                },
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
                            '打开应用时默认展示「${statusOptions.firstWhere((e) => e.$1 == _defaultStatus).$2}」分类',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Divider(color: borderColor, height: 1),
                          const SizedBox(height: 18),

                          // 2. 界面与显示设置（跟随屏幕选择）
                          _buildSectionHeader('界面与显示'),
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
                                  value: _followScreenSelection,
                                  activeThumbColor: theme.colorScheme.primary,
                                  onChanged: (val) async {
                                    setState(() => _followScreenSelection = val);
                                    await widget.animeProvider.storage.saveFollowScreenRotation(val);
                                    if (!val) {
                                      await SystemChrome.setPreferredOrientations([
                                        DeviceOrientation.portraitUp,
                                      ]);
                                    } else {
                                      await SystemChrome.setPreferredOrientations([
                                        DeviceOrientation.portraitUp,
                                        DeviceOrientation.portraitDown,
                                        DeviceOrientation.landscapeLeft,
                                        DeviceOrientation.landscapeRight,
                                      ]);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Divider(color: borderColor, height: 1),
                          const SizedBox(height: 18),

                      // 2. 云端同步 (GitHub Gist)
                      Row(
                        children: [
                          Icon(Icons.cloud_sync_outlined, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          _buildSectionHeader('云端同步（GitHub Gist）'),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isConfigured
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : (isDark ? const Color(0xFF232733) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isConfigured ? '已连接' : '未配置',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isConfigured
                                    ? const Color(0xFF10B981)
                                    : (isDark ? const Color(0xFFA8B0C0) : const Color(0xFF59617A)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Token 栏
                      Row(
                        children: [
                          _buildFieldLabel('GitHub Token (PAT)'),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(const ClipboardData(
                                text: 'https://github.com/settings/tokens/new?description=anime-record-sync&scopes=gist',
                              ));
                              Toast.show(context, 'Token 创建链接已复制到剪贴板', type: ToastType.info);
                            },
                            child: Text(
                              '复制 Token 创建链接 ↗',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _tokenController,
                        obscureText: !_isTokenVisible,
                        decoration: InputDecoration(
                          hintText: 'ghp_... 或 github_pat_...',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isTokenVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() => _isTokenVisible = !_isTokenVisible);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '仅需 gist 读写权限，安全保存在当前设备本地。',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Gist ID 栏
                      _buildFieldLabel('Gist ID'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _gistIdController,
                              decoration: const InputDecoration(
                                hintText: '如 32 位字符或 Gist 网址',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _isCreatingGist ? null : _createGist,
                            child: _isCreatingGist
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('自动新建 Gist'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '多台设备填写相同的 Gist ID 即可实现进度互通。',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 自动同步与测试按钮
                      Row(
                        children: [
                          Checkbox(
                            value: _autoSync,
                            onChanged: (val) {
                              setState(() => _autoSync = val ?? false);
                            },
                          ),
                          const Text('打开应用时自动同步', style: TextStyle(fontSize: 13)),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: _isTestingSync ? null : _testSync,
                            child: _isTestingSync
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('测试连接'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 同步信息操作卡片（换行展示，防止存在同步时间时按钮被挤出屏幕）
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF14171E) : const Color(0xFFFBFBFD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '上次同步：',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.animeProvider.syncConfig.lastSyncTime.isNotEmpty
                                        ? widget.animeProvider.syncConfig.lastSyncTime
                                            .replaceFirst('T', ' ')
                                            .split('.')
                                            .first
                                        : '从未同步',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _saveSyncSettings,
                                    child: const Text('保存配置'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: widget.animeProvider.isSyncing ? null : _syncNow,
                                    icon: widget.animeProvider.isSyncing
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.sync_rounded, size: 16),
                                    label: const Text('立即同步'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '🛡️ 安全保障：采用时间戳双向增量合并机制，新设备首次同步优先拉取云端，绝不覆盖已有记录。',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(color: borderColor, height: 1),
                      const SizedBox(height: 20),

                      // 3. 本地数据管理
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          _buildSectionHeader('本地数据管理'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 420) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _handleExportData,
                                  icon: const Icon(Icons.file_upload_outlined, size: 16),
                                  label: const Text('导出数据'),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _handleImportData,
                                  icon: const Icon(Icons.file_download_outlined, size: 16),
                                  label: const Text('导入数据'),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _handleExportTemplate,
                                  icon: const Icon(Icons.description_outlined, size: 16),
                                  label: const Text('下载模板'),
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _handleExportData,
                                  icon: const Icon(Icons.file_upload_outlined, size: 16),
                                  label: const Text('导出数据'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _handleImportData,
                                  icon: const Icon(Icons.file_download_outlined, size: 16),
                                  label: const Text('导入数据'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _handleExportTemplate,
                                  icon: const Icon(Icons.description_outlined, size: 16),
                                  label: const Text('下载模板'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '可导出本地 JSON 文件离线存档，或通过下载模板按格式整理番剧批量导入。',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    _saveSyncSettings(showToastMessage: false);
                    Navigator.of(context).pop();
                  },
                  child: const Text('完成'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430),
      ),
    );
  }
}
