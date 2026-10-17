import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/import_export_service.dart';
import '../../state/anime_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/toast_overlay.dart';
import 'settings/backup_restore_section.dart';
import 'settings/general_settings_section.dart';
import 'settings/sync_settings_section.dart';

/// 设置弹窗（采用子模块分治架构：通用偏好、GitHub Gist 云同步、本地导入导出）
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
      final jsonStr = await ImportExportService.exportToJsonAsync(records);
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

      final incoming = await ImportExportService.parseImportJsonAsync(jsonStr);
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

              // 主内容滚动区
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
                          // 1. 通用偏好设置部分
                          GeneralSettingsSection(
                            defaultStatus: _defaultStatus,
                            onDefaultStatusChanged: (val) {
                              setState(() => _defaultStatus = val);
                              widget.animeProvider.setDefaultStatus(val);
                            },
                            followScreenRotation: _followScreenSelection,
                            onFollowScreenRotationChanged: (val) async {
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
                            borderColor: borderColor,
                          ),
                          const SizedBox(height: 20),
                          Divider(color: borderColor, height: 1),
                          const SizedBox(height: 20),

                          // 2. 云端同步部分
                          ListenableBuilder(
                            listenable: widget.animeProvider,
                            builder: (context, _) {
                              final provider = widget.animeProvider;
                              return SyncSettingsSection(
                                tokenController: _tokenController,
                                gistIdController: _gistIdController,
                                autoSync: _autoSync,
                                onAutoSyncChanged: (val) {
                                  setState(() => _autoSync = val);
                                },
                                isConfigured: provider.syncConfig.isConfigured,
                                isSyncing: provider.isSyncing,
                                isTestingSync: _isTestingSync,
                                isCreatingGist: _isCreatingGist,
                                lastSyncTime: provider.syncConfig.lastSyncTime,
                                onTestSync: _testSync,
                                onCreateGist: _createGist,
                                onSaveSyncSettings: () => _saveSyncSettings(showToastMessage: true),
                                onSyncNow: _syncNow,
                                borderColor: borderColor,
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Divider(color: borderColor, height: 1),
                          const SizedBox(height: 20),

                          // 3. 本地备份与恢复部分
                          BackupRestoreSection(
                            onExportData: _handleExportData,
                            onImportData: _handleImportData,
                            onExportTemplate: _handleExportTemplate,
                            borderColor: borderColor,
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
}
