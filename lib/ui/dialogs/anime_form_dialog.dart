import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/l10n.dart';
import '../../models/anime_record.dart';
import '../../models/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/anime_cover_image.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/toast_overlay.dart';
import 'form/rating_picker_section.dart';
import 'form/tag_selector_section.dart';

/// 添加 / 编辑番剧模态弹窗（支持封面输入预览、标签选择、评分调节与键盘安全适配）
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
  late TextEditingController _coverUrlController;
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
    _coverUrlController = TextEditingController(text: rec?.coverUrl ?? '');
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

    if (rec != null &&
        (rec.titleJa.isNotEmpty ||
            rec.coverUrl.isNotEmpty ||
            rec.notes.isNotEmpty ||
            rec.tags.isNotEmpty ||
            rec.rating > 0)) {
      _isAdvancedExpanded = true;
    }
  }

  @override
  void dispose() {
    _titleZhController.dispose();
    _titleJaController.dispose();
    _coverUrlController.dispose();
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
      coverUrl: _coverUrlController.text.trim(),
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

    final validationError = newOrUpdated.validateError();
    if (validationError != null) {
      Toast.show(
        context,
        validationError.localizedMessage(context.l10nOrNull),
        type: ToastType.error,
      );
      return;
    }

    widget.onSave(newOrUpdated);
    Navigator.of(context).pop();
  }

  Future<void> _handleDelete() async {
    final title = _titleZhController.text.trim().isEmpty
        ? (context.l10nOrNull?.unnamedAnime ?? '未命名番剧')
        : _titleZhController.text.trim();
    final confirmed = await ConfirmDialog.show(
      context,
      title: context.l10nOrNull?.deleteAnime ?? '删除番剧',
      message: context.l10nOrNull?.deleteAnimeConfirm(title) ??
          '确定要删除「$title」吗？此操作不可撤销。',
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
    final l10n = context.l10nOrNull;
    final isEditing = widget.initialRecord != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(22),
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
                      isEditing ? (l10n?.editAnime ?? '编辑番剧') : (l10n?.addAnime ?? '添加番剧'),
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
                const SizedBox(height: 14),
                // 表单主体内容（可滚动）
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 中文名称（必填）
                        _buildLabel(l10n?.titleZhLabel ?? '中文名称', required: true),
                        TextFormField(
                          controller: _titleZhController,
                          autofocus: !isEditing,
                          decoration: InputDecoration(
                            hintText: l10n?.titleZhHint ?? '例：葬送的芙莉莲',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return l10n?.titleZhValidation ?? '请输入番剧名称';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        // 观看状态 & 更新频率
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(l10n?.watchStatusSelectLabel ?? '观看状态'),
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(l10n?.airDaySelectLabel ?? '更新频率'),
                                  DropdownButtonFormField<String>(
                                    initialValue: _week,
                                    decoration: const InputDecoration(),
                                    items: [
                                      DropdownMenuItem(
                                        value: '',
                                        child: Text(l10n?.airDayNone ?? '不设置'),
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
                        const SizedBox(height: 14),
                        // 播放状态
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(l10n?.airStatusSelectLabel ?? '播放状态'),
                                  DropdownButtonFormField<String>(
                                    initialValue: _airStatus,
                                    decoration: const InputDecoration(),
                                    items: [
                                      DropdownMenuItem(
                                        value: '',
                                        child: Text(l10n?.airStatusNone ?? '不显示'),
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
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // 已看集数 & 总集数
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(l10n?.episodesWatchedLabel ?? '已看集数'),
                                  TextFormField(
                                    controller: _epWatchedController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: const InputDecoration(hintText: '0'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(l10n?.episodesTotalLabel ?? '总集数'),
                                  TextFormField(
                                    controller: _epTotalController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: InputDecoration(
                                      hintText: l10n?.episodesTotalHint ?? '0 (未知)',
                                    ),
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
                                  _isAdvancedExpanded
                                      ? (l10n?.cancel ?? '收起更多信息')
                                      : (l10n?.advancedOptions ?? '展开更多信息 (封面海报、日文名、标签、评分等)'),
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
                          // 封面海报链接输入与预览
                          _buildLabel(l10n?.coverUrlLabel ?? '封面图片链接 (URL)'),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _coverUrlController,
                                  onChanged: (_) => setState(() {}),
                                  validator: (val) {
                                    if (val != null && val.trim().isNotEmpty) {
                                      final uri = Uri.tryParse(val.trim());
                                      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
                                        return l10n?.coverUrlValidation ?? '封面链接必须是以 http:// 或 https:// 开头的有效网址';
                                      }
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: l10n?.coverUrlHint ?? 'https://example.com/poster.jpg',
                                  ),
                                ),
                              ),
                              if (_coverUrlController.text.trim().isNotEmpty) ...[
                                const SizedBox(width: 10),
                                AnimeCoverImage(
                                  url: _coverUrlController.text.trim(),
                                  width: 48,
                                  height: 48,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),
                          // 日文名称
                          _buildLabel(l10n?.titleJaLabel ?? '日文名称'),
                          TextFormField(
                            controller: _titleJaController,
                            decoration: InputDecoration(
                              hintText: l10n?.titleJaHint ?? '例：葬送のフリーレン',
                            ),
                          ),
                          const SizedBox(height: 14),
                          // 标签选择器
                          _buildLabel(l10n?.tagsLabel ?? '标签 (点击选择或添加)'),
                          TagSelectorSection(
                            tags: _tags,
                            onTagsChanged: (newTags) => setState(() => _tags = newTags),
                          ),
                          const SizedBox(height: 14),

                          // 评分
                          _buildLabel(l10n?.ratingLabel ?? '评分 (0 - 10)'),
                          RatingPickerSection(
                            rating: _rating,
                            onRatingChanged: (newRating) => setState(() => _rating = newRating),
                          ),
                          const SizedBox(height: 14),
                          // 备注
                          _buildLabel(l10n?.notesLabel ?? '备注 / 评价'),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: l10n?.notesHint ?? '写下观后感、观看平台或备忘笔记...',
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 底部操作按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n?.cancel ?? '取消'),
                    ),
                    if (isEditing && widget.onDelete != null) ...[
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.dangerRed,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _handleDelete,
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: Text(l10n?.delete ?? '删除'),
                      ),
                    ],
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _save,
                      child: Text(l10n?.save ?? '保存'),
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
              color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
            ),
          ),
          if (required) ...[
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: AppTheme.dangerRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
