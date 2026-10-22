import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// 统一风格的确认操作弹窗
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final Widget? customContent;
  final String cancelText;
  final String confirmText;
  final bool isDestructive;
  final List<Widget>? extraActions;

  const ConfirmDialog({
    super.key,
    required this.title,
    this.message = '',
    this.customContent,
    this.cancelText = '取消',
    this.confirmText = '确认',
    this.isDestructive = false,
    this.extraActions,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String message = '',
    Widget? customContent,
    String cancelText = '取消',
    String confirmText = '确认',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        customContent: customContent,
        cancelText: cancelText,
        confirmText: confirmText,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 14),
              if (customContent != null)
                customContent!
              else
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? const Color(0xFFA8B0C0) : const Color(0xFF59617A),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancelText == '取消' ? (context.l10nOrNull?.cancel ?? cancelText) : cancelText),
                  ),
                  if (extraActions != null) ...[
                    const SizedBox(width: 8),
                    ...extraActions!,
                  ],
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: isDestructive
                        ? ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dangerRed,
                            foregroundColor: Colors.white,
                          )
                        : null,
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(confirmText == '确认' ? (context.l10nOrNull?.confirm ?? confirmText) : confirmText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
