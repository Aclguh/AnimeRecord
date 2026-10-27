import 'package:anime_record/ui/widgets/anime_cover_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('AnimeCoverImage renders CachedNetworkImage when url is valid', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimeCoverImage(
            url: 'https://example.com/cover.jpg',
            width: 80,
            height: 120,
          ),
        ),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsOneWidget);
    final cachedImage = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(cachedImage.imageUrl, 'https://example.com/cover.jpg');
    expect(cachedImage.maxHeightDiskCache, 600);
    expect(cachedImage.maxWidthDiskCache, 450);
  });

  test('AnimeCoverCacheManager has proper cache configuration', () {
    expect(AnimeCoverCacheManager.key, 'anime_cover_cache');
    expect(AnimeCoverCacheManager.instance, isNotNull);
  });
}
