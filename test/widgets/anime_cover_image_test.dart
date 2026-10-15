import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_record/ui/widgets/anime_cover_image.dart';

void main() {
  testWidgets('AnimeCoverImage renders empty placeholder when url is empty', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimeCoverImage(url: '', width: 68, height: 94),
        ),
      ),
    );

    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
  });
}
