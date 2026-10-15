import 'package:flutter/material.dart';
import '../../../models/app_constants.dart';

/// 表单弹窗 - 标签选择与自定义标签管理子组件
class TagSelectorSection extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagSelectorSection({
    super.key,
    required this.tags,
    required this.onTagsChanged,
  });

  @override
  State<TagSelectorSection> createState() => _TagSelectorSectionState();
}

class _TagSelectorSectionState extends State<TagSelectorSection> {
  final TextEditingController _customTagController = TextEditingController();

  @override
  void dispose() {
    _customTagController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    final next = List<String>.from(widget.tags);
    if (next.contains(tag)) {
      next.remove(tag);
    } else {
      next.add(tag);
    }
    widget.onTagsChanged(next);
  }

  void _addCustomTag() {
    final text = _customTagController.text.trim();
    if (text.isNotEmpty && !widget.tags.contains(text)) {
      final next = List<String>.from(widget.tags)..add(text);
      widget.onTagsChanged(next);
      _customTagController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...kPresetTags.map((tag) {
              final isSelected = widget.tags.contains(tag);
              return FilterChip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                onSelected: (_) => _toggleTag(tag),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              );
            }),
            ...widget.tags.where((t) => !kPresetTags.contains(t)).map((customTag) {
              return InputChip(
                label: Text(customTag, style: const TextStyle(fontSize: 12)),
                selected: true,
                onDeleted: () => _toggleTag(customTag),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _customTagController,
                  onSubmitted: (_) => _addCustomTag(),
                  decoration: const InputDecoration(
                    hintText: '输入自定义标签并按添加',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _addCustomTag,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('添加标签'),
            ),
          ],
        ),
      ],
    );
  }
}
