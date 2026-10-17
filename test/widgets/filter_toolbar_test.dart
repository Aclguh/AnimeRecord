import 'package:anime_record/models/app_constants.dart';
import 'package:anime_record/ui/widgets/filter_toolbar.dart';
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
  group('FilterToolbar Widget Tests', () {
    testWidgets('renders all status tabs and handles tap', (tester) async {
      String selectedStatus = '';

      await tester.pumpWidget(_wrap(
        FilterToolbar(
          activeStatus: AnimeStatus.watching,
          statusCounts: const {AnimeStatus.watching: 3, AnimeStatus.wantToWatch: 5},
          searchQuery: '',
          sortBy: SortOption.defaultSort,
          onSelectStatus: (s) => selectedStatus = s,
          onSearchChanged: (_) {},
          onSortChanged: (_) {},
          onAddAnime: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('在看'), findsOneWidget);
      expect(find.text('想看'), findsOneWidget);

      await tester.tap(find.text('想看'));
      expect(selectedStatus, AnimeStatus.wantToWatch);
    });

    testWidgets('debounces search input and triggers onSearchChanged', (tester) async {
      String searched = '';

      await tester.pumpWidget(_wrap(
        FilterToolbar(
          activeStatus: AnimeStatus.watching,
          statusCounts: const {},
          searchQuery: '',
          sortBy: SortOption.defaultSort,
          onSelectStatus: (_) {},
          onSearchChanged: (q) => searched = q,
          onSortChanged: (_) {},
          onAddAnime: () {},
        ),
      ));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, '芙莉莲');

      // Before debounce fires
      expect(searched, isEmpty);

      // Advance past the 250ms debounce
      await tester.pump(const Duration(milliseconds: 300));
      expect(searched, '芙莉莲');
    });

    testWidgets('triggers onAddAnime callback when clicking add button', (tester) async {
      bool addTapped = false;

      await tester.pumpWidget(_wrap(
        FilterToolbar(
          activeStatus: AnimeStatus.watching,
          statusCounts: const {},
          searchQuery: '',
          sortBy: SortOption.defaultSort,
          onSelectStatus: (_) {},
          onSearchChanged: (_) {},
          onSortChanged: (_) {},
          onAddAnime: () => addTapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('添加番剧'));
      expect(addTapped, isTrue);
    });
  });
}
