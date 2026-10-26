import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/l10n.dart';
import '../../services/import_export_service.dart';
import '../../services/sync_service.dart';
import '../../state/anime_provider.dart';
import '../../state/locale_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/toast_overlay.dart';
import 'settings/backup_restore_section.dart';
import 'settings/general_settings_section.dart';
import 'settings/sync_settings_section.dart';

/// 设置弹窗（采用子模块分治架构：通用偏好、GitHub Gist 云同步、本地导入导出）
class SettingsDialog extends StatefulWidget {
  final AnimeProvider animeProvider;
  final LocaleProvider? localeProvider;

  const SettingsDialog({
    super.key,
    required this.animeProvider,
    this.localeProvider,
  });

  static Future<void> show(
    BuildContext context,
    AnimeProvider provider, {
    LocaleProvider? localeProvider,
  }) {
    return showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        animeProvider: provider,
        localeProvider: localeProvider,
      ),
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
      final l10n = AppLocalizations.of(context);
      Toast.show(context, l10n?.syncConfigSaved ?? '云同步配置已保存', type: ToastType.success);
    }
  }

  Future<void> _testSync() async {
    final token = _tokenController.text.trim();
    final gistId = _gistIdController.text.trim();
    final l10n = AppLocalizations.of(context);

    if (token.isEmpty) {
      Toast.show(context, l10n?.syncTokenRequired ?? '请先输入 GitHub Token', type: ToastType.info);
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
          l10n?.syncConnectSuccess(username, gistInfo) ?? '连接成功！GitHub 账号：$username$gistInfo',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e is SyncException ? e.message : e.toString().replaceFirst('Exception: ', '');
        Toast.show(
          context,
          l10n?.syncConnectFailed(msg) ?? '测试失败：$msg',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingSync = false);
    }
  }

  Future<void> _createGist() async {
    final token = _tokenController.text.trim();
    final l10n = AppLocalizations.of(context);
    if (token.isEmpty) {
      Toast.show(context, l10n?.syncTokenRequired ?? '请先输入 GitHub Token', type: ToastType.error);
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
          l10n?.gistCreatedSuccess ?? '已成功在 GitHub 创建私有 Gist 并完成绑定！',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e is SyncException ? e.message : e.toString().replaceFirst('Exception: ', '');
        Toast.show(
          context,
          l10n?.gistCreateFailed(msg) ?? '创建 Gist 失败：$msg',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingGist = false);
    }
  }

  Future<void> _syncNow() async {
    _saveSyncSettings(showToastMessage: false);
    final l10n = AppLocalizations.of(context);
    final res = await widget.animeProvider.performSync(silent: false);
    if (!mounted) return;

    if (res.isCliff) {
      final confirmForce = await ConfirmDialog.show(
        context,
        title: l10n?.cliffTitle ?? '同步数据保护提醒',
        message: l10n?.cliffMessage(res.baselineCount, res.mergedCount) ??
            '检测到云端与本地合并后数据量骤降（原基准为 ${res.baselineCount} 部，合并后仅剩 ${res.mergedCount} 部）。\n\n'
            '这通常发生在误清空或更换空 Gist 时。若这是您的预期删除操作，请选择「强制覆盖同步」。',
        confirmText: l10n?.cliffForceSync ?? '强制覆盖同步',
        cancelText: l10n?.cancel ?? '取消',
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

  Future<void> _handleExportData() async {
    final l10n = AppLocalizations.of(context);
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
        Toast.show(
          context,
          l10n?.exportSuccess(records.length) ?? '已导出 ${records.length} 条记录',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          l10n?.exportFailed(e.toString()) ?? '导出失败：$e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _handleExportTemplate() async {
    final l10n = AppLocalizations.of(context);
    try {
      final jsonStr = ImportExportService.exportTemplateJson();
      final path = await ImportExportService.saveJsonFile(
        filename: 'anime-record-template.json',
        content: jsonStr,
      );
      if (mounted && path != null) {
        Toast.show(
          context,
          l10n?.templateExportSuccess ?? '导入模板已下载保存',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          l10n?.templateExportFailed(e.toString()) ?? '导出模板失败：$e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _handleImportData() async {
    final l10n = AppLocalizations.of(context);
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
            title: l10n?.importDialogTitle ?? '导入数据',
            customContent: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n?.importDialogFound(incoming.length) ?? '发现 ${incoming.length} 条待导入记录。'),
                const SizedBox(height: 4),
                Text(l10n?.importDialogCurrent(current.length) ?? '当前已有 ${current.length} 条记录。'),
                const SizedBox(height: 10),
                Text(l10n?.importDialogSelectMode ?? '请选择导入方式：'),
              ],
            ),
            cancelText: l10n?.cancel ?? '取消',
            confirmText: l10n?.importMerge ?? '合并导入',
            extraActions: [
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop('replace'),
                child: Text(l10n?.importReplace ?? '替换全部'),
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
            replaceMode
                ? (l10n?.importReplaceSuccess(incoming.length) ?? '已替换导入 ${incoming.length} 条记录')
                : (l10n?.importMergeSuccess ?? '已成功合并导入记录'),
            type: ToastType.success,
          );
        } else {
          Toast.show(context, l10n?.importSaveFailed ?? '导入保存失败', type: ToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        final errText = e.toString().replaceFirst('Exception: ', '');
        Toast.show(
          context,
          l10n?.importFailed(errText) ?? '导入失败：$errText',
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
                    AppLocalizations.of(context)?.settings ?? '设置',
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
                            currentLocale: widget.localeProvider?.currentLocaleCode,
                            onLocaleChanged: widget.localeProvider != null
                                ? (val) {
                                    setState(() {});
                                    widget.localeProvider!.setLocale(val);
                                  }
                                : null,
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
                                  _saveSyncSettings(showToastMessage: false);
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
