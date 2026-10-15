import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/toast_overlay.dart';

/// 设置弹窗 - 云端同步部分 (GitHub Gist 配置与操作)
class SyncSettingsSection extends StatefulWidget {
  final TextEditingController tokenController;
  final TextEditingController gistIdController;
  final bool autoSync;
  final ValueChanged<bool> onAutoSyncChanged;
  final bool isConfigured;
  final bool isSyncing;
  final bool isTestingSync;
  final bool isCreatingGist;
  final String lastSyncTime;
  final VoidCallback onTestSync;
  final VoidCallback onCreateGist;
  final VoidCallback onSaveSyncSettings;
  final VoidCallback onSyncNow;
  final Color borderColor;

  const SyncSettingsSection({
    super.key,
    required this.tokenController,
    required this.gistIdController,
    required this.autoSync,
    required this.onAutoSyncChanged,
    required this.isConfigured,
    required this.isSyncing,
    required this.isTestingSync,
    required this.isCreatingGist,
    required this.lastSyncTime,
    required this.onTestSync,
    required this.onCreateGist,
    required this.onSaveSyncSettings,
    required this.onSyncNow,
    required this.borderColor,
  });

  @override
  State<SyncSettingsSection> createState() => _SyncSettingsSectionState();
}

class _SyncSettingsSectionState extends State<SyncSettingsSection> {
  bool _isTokenVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.cloud_sync_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '云端同步（GitHub Gist）',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: widget.isConfigured
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : (isDark ? const Color(0xFF232733) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.isConfigured ? '已连接' : '未配置',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: widget.isConfigured
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
            Text(
              'GitHub Token (PAT)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFA8B0C0) : const Color(0xFF59617A),
              ),
            ),
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
          controller: widget.tokenController,
          obscureText: !_isTokenVisible,
          decoration: InputDecoration(
            hintText: 'ghp_... 或 github_pat_...',
            suffixIcon: IconButton(
              icon: Icon(
                _isTokenVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
        Text(
          'Gist ID',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFA8B0C0) : const Color(0xFF59617A),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.gistIdController,
                decoration: const InputDecoration(
                  hintText: '如 32 位字符或 Gist 网址',
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: widget.isCreatingGist ? null : widget.onCreateGist,
              child: widget.isCreatingGist
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
              value: widget.autoSync,
              onChanged: (val) => widget.onAutoSyncChanged(val ?? false),
            ),
            const Text('打开应用时自动同步', style: TextStyle(fontSize: 13)),
            const Spacer(),
            OutlinedButton(
              onPressed: widget.isTestingSync ? null : widget.onTestSync,
              child: widget.isTestingSync
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

        // 同步信息操作卡片
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14171E) : const Color(0xFFFBFBFD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.borderColor),
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
                      widget.lastSyncTime.isNotEmpty
                          ? widget.lastSyncTime.replaceFirst('T', ' ').split('.').first
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
                      onPressed: widget.onSaveSyncSettings,
                      child: const Text('保存配置'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.isSyncing ? null : widget.onSyncNow,
                      icon: widget.isSyncing
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
      ],
    );
  }
}
