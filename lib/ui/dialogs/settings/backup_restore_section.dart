import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';

/// 设置弹窗 - 本地数据备份与恢复部分
class BackupRestoreSection extends StatelessWidget {
  final VoidCallback onExportData;
  final VoidCallback onImportData;
  final VoidCallback onExportTemplate;
  final Color borderColor;

  const BackupRestoreSection({
    super.key,
    required this.onExportData,
    required this.onImportData,
    required this.onExportTemplate,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              l10n?.localDataManagement ?? '本地数据管理',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final exportLabel = l10n?.exportData ?? '导出数据';
            final importLabel = l10n?.importData ?? '导入数据';
            final templateLabel = l10n?.downloadTemplate ?? '下载模板';

            if (constraints.maxWidth < 420) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: onExportData,
                    icon: const Icon(Icons.file_upload_outlined, size: 16),
                    label: Text(exportLabel),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onImportData,
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: Text(importLabel),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onExportTemplate,
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: Text(templateLabel),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExportData,
                    icon: const Icon(Icons.file_upload_outlined, size: 16),
                    label: Text(exportLabel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onImportData,
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: Text(importLabel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExportTemplate,
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: Text(templateLabel),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          l10n?.localDataHint ?? '可导出本地 JSON 文件离线存档，或通过下载模板按格式整理番剧批量导入。',
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? const Color(0xFF6E7688) : const Color(0xFF98A0B3),
          ),
        ),
      ],
    );
  }
}
