import 'package:flutter/material.dart';
import '../../models/anime_record.dart';
import '../../models/app_constants.dart';
import '../widgets/confirm_dialog.dart';

/// 添加 / 编辑番剧模态弹窗
class AnimeFormDialog extends StatefulWidget {
  final AnimeRecord? initialRecord;
  final ValueChanged<AnimeRecord> onSave;
  final VoidCallback? onDelete;

  const AnimeFormDialog({
    super.key,
    this.initialRecord,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    AnimeRecord? initialRecord,
    required ValueChanged<AnimeRecord> onSave,
    VoidCallback? onDelete,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnimeFormDialog(
        initialRecord: initialRecord,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<AnimeFormDialog> createState() => _AnimeFormDialogState();
}

class _AnimeFormDialogState extends State<AnimeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleZhController;
  late TextEditingController _titleJaController;
  late TextEditingController _epWatchedController;
  late TextEditingController _epTotalController;
  late TextEditingController _notesController;

  late String _status;
  late String _week;
  late String _airStatus;
  late double _rating;
  late List<String> _tags;

  bool _isAdvancedExpanded = false;

  @override
  void initState() {
    super.initState();
    final rec = widget.initialRecord;

    _titleZhController = TextEditingController(text: rec?.titleZh ?? '');
    _titleJaController = TextEditingController(text: rec?.titleJa ?? '');
    _epWatchedController = TextEditingController(
      text: rec != null ? '${rec.episodesWatched}' : '0',
    );
    _epTotalController = TextEditingController(
      text: rec != null ? '${rec.episodesTotal}' : '0',
    );
    _notesController = TextEditingController(text: rec?.notes ?? '');

    _status = rec?.status ?? AnimeStatus.wantToWatch;
    _week = rec?.week ?? '';
    _airStatus = rec?.airStatus ?? '';
    _rating = rec?.rating ?? 0.0;
    _tags = List.from(rec?.tags ?? []);

    if (rec != null && (rec.titleJa.isNotEmpty || rec.notes.isNotEmpty || rec.tags.isNotEmpty || rec.rating > 0)) {
      _isAdvancedExpanded = true;
    }
  }

  @override
  void dispose() {
    _titleZhController.dispose();
    _titleJaController.dispose();
    _epWatchedController.dispose();
    _epTotalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final titleZh = _titleZhController.text.trim();
    int watched = int.tryParse(_epWatchedController.text.trim()) ?? 0;
    int total = int.tryParse(_epTotalController.text.trim()) ?? 0;

    if (watched < 0) watched = 0;
    if (total < 0) total = 0;
    if (total > 0 && watched > total) {
      watched = total;
    }

    String currentStatus = _status;
    String endDate = widget.initialRecord?.endDate ?? '';

    // 状态自动联动：总集数大于 0 且已看完时，若为想看/在看自动标记为看过
    if (total > 0 && watched >= total) {
      if (currentStatus == AnimeStatus.watching || currentStatus == AnimeStatus.wantToWatch) {
        currentStatus = AnimeStatus.watched;
        if (endDate.isEmpty) {
          endDate = DateTime.now().toIso8601String().split('T').first;
        }
      }
    }

    final newOrUpdated = (widget.initialRecord ?? AnimeRecord.createEmpty()).copyWith(
      titleZh: titleZh,
      titleJa: _titleJaController.text.trim(),
      status: currentStatus,
      week: _week,
      airStatus: _airStatus,
      episodesWatched: watched,
      episodesTotal: total,
      rating: _rating,
      tags: _tags,
      notes: _notesController.text.trim(),
      endDate: endDate,
    );

    widget.onSave(newOrUpdated);
    Navigator.of(context).pop();
  }

  Future<void> _handleDelete() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '删除番剧',
      message: '确定要删除「${_titleZhController.text.trim()}」吗？此操作不可撤销。',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
      widget.onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.initialRecord != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 顶部标题
                Row(
                  children: [
                    Text(
                      isEditing ? '编辑番剧' : '添加番剧',
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
                const SizedBox(height: 16),
                // 表单主体内容（可滚动）
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 中文名称（必填）
                        _buildLabel('中文名称', required: true),
                        TextFormField(
                          controller: _titleZhController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: '例：葬送的芙莉莲',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return '请输入番剧名称';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // 观看状态 & 更新频率
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('观看状态'),
                                  DropdownButtonFormField<String>(
                                    initialValue: _status,
                                    decoration: const InputDecoration(),
                                    items: AnimeStatus.allValues.map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text(AnimeStatus.getLabel(s)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _status = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('更新频率'),
                                  DropdownButtonFormField<String>(
                                    initialValue: _week,
                                    decoration: const InputDecoration(),
                                    items: [
                                      const DropdownMenuItem(
                                        value: '',
                                        child: Text('不设置'),
                                      ),
                                      ...WeekDay.order.map((w) {
                                        return DropdownMenuItem(
                                          value: w,
                                          child: Text(WeekDay.getFullLabel(w)),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _week = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 播放状态
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('播放状态'),
                                  DropdownButtonFormField<String>(
                                    initialValue: _airStatus,
                                    decoration: const InputDecoration(),
                                    items: [
                                      const DropdownMenuItem(
                                        value: '',
                                        child: Text('不显示'),
                                      ),
                                      ...AirStatus.allValues.map((a) {
                                        return DropdownMenuItem(
                                          value: a,
                                          child: Text(AirStatus.getLabel(a)),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _airStatus = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 已看集数 & 总集数
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('已看集数'),
                                  TextFormField(
                                    controller: _epWatchedController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(hintText: '0'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('总集数'),
                                  TextFormField(
                                    controller: _epTotalController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(hintText: '0 (未知)'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // 更多可选属性折叠面板
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isAdvancedExpanded = !_isAdvancedExpanded;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Text(
                                  _isAdvancedExpanded ? '收起更多信息' : '展开更多信息 (日文名、备注、评分等)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Icon(
                                  _isAdvancedExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isAdvancedExpanded) ...[
                          const SizedBox(height: 12),
                          _buildLabel('日文名称'),
                          TextFormField(
                            controller: _titleJaController,
                            decoration: const InputDecoration(
                              hintText: '例：葬送のフリーレン',
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildLabel('评分 (0 - 10)'),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _rating,
                                  min: 0,
                                  max: 10,
                                  divisions: 20,
                                  label: _rating == 0 ? '未评分' : '$_rating 分',
                                  onChanged: (val) {
                                    setState(() => _rating = val);
                                  },
                                ),
                              ),
                              Text(
                                _rating == 0 ? '未评分' : '$_rating 分',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildLabel('备注 / 评价'),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: '写下观后感、观看平台或备忘笔记...',
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // 底部操作按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    if (isEditing && widget.onDelete != null) ...[
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _handleDelete,
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('删除'),
                      ),
                    ],
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE8EAF1) : const Color(0xFF1F2430),
            ),
          ),
          if (required) ...[
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
