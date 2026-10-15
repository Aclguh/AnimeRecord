import 'package:flutter/material.dart';

/// 表单弹窗 - 评分选择滑块与数值展示子组件 (0 - 10 分)
class RatingPickerSection extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;

  const RatingPickerSection({
    super.key,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Slider(
            value: rating,
            min: 0,
            max: 10,
            divisions: 20,
            label: rating == 0 ? '未评分' : '$rating 分',
            onChanged: onRatingChanged,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          constraints: const BoxConstraints(minWidth: 54),
          alignment: Alignment.centerRight,
          child: Text(
            rating == 0 ? '未评分' : '$rating 分',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF18181B),
            ),
          ),
        ),
      ],
    );
  }
}
