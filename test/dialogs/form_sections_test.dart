import 'package:anime_record/ui/dialogs/form/rating_picker_section.dart';
import 'package:anime_record/ui/dialogs/form/tag_selector_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

void main() {
  group('Form Sections Tests', () {
    testWidgets('TagSelectorSection toggles preset tags and adds custom tags', (tester) async {
      List<String> currentTags = ['恋爱'];

      await tester.pumpWidget(_wrap(
        StatefulBuilder(
          builder: (context, setState) => TagSelectorSection(
            tags: currentTags,
            onTagsChanged: (tags) {
              setState(() => currentTags = tags);
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap preset tag '搞笑' to add it
      await tester.tap(find.widgetWithText(FilterChip, '搞笑'));
      await tester.pumpAndSettle();
      expect(currentTags.contains('搞笑'), isTrue);

      // Tap '恋爱' to remove it
      await tester.tap(find.widgetWithText(FilterChip, '恋爱'));
      await tester.pumpAndSettle();
      expect(currentTags.contains('恋爱'), isFalse);

      // Add custom tag
      await tester.enterText(find.byType(TextField), '赛博朋克');
      await tester.tap(find.widgetWithText(OutlinedButton, '添加标签'));
      await tester.pumpAndSettle();

      expect(currentTags.contains('赛博朋克'), isTrue);
      expect(find.text('赛博朋克'), findsOneWidget);
    });

    testWidgets('RatingPickerSection updates value and displays score text', (tester) async {
      double rating = 0.0;

      await tester.pumpWidget(_wrap(
        StatefulBuilder(
          builder: (context, setState) => RatingPickerSection(
            rating: rating,
            onRatingChanged: (val) {
              setState(() => rating = val);
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('未评分'), findsNWidgets(1));

      // Drag slider
      await tester.tap(find.byType(Slider));
      await tester.pumpAndSettle();

      expect(rating > 0, isTrue);
    });
  });
}
