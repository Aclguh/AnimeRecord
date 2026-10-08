import 'package:flutter/material.dart';

enum ToastType { info, success, error, warning }

/// 优雅的 Toast 提示系统（支持安全区自适应、单例防堆叠排队与平滑动画）
class Toast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // 移除已存在的 Toast，避免坐标堆叠遮挡
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (Color bg, Color fg, IconData icon) _getStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (widget.type) {
      case ToastType.success:
        return (
          isDark ? const Color(0xFF10251D) : const Color(0xFFE6F8F1),
          isDark ? const Color(0xFF34D399) : const Color(0xFF10B981),
          Icons.check_circle_outline_rounded,
        );
      case ToastType.error:
        return (
          isDark ? const Color(0xFF2A1517) : const Color(0xFFFFECEC),
          isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
          Icons.error_outline_rounded,
        );
      case ToastType.warning:
        return (
          isDark ? const Color(0xFF2A2110) : const Color(0xFFFFF5E3),
          isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B),
          Icons.warning_amber_rounded,
        );
      case ToastType.info:
        return (
          isDark ? const Color(0xFF27272A) : const Color(0xFFFFFFFF),
          isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
          Icons.info_outline_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _getStyle(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding > 0 ? topPadding + 10 : 36,
      left: 0,
      right: 0,
      child: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: fg.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20, color: fg),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
