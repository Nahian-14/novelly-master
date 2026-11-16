import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novelly/cover/cover_commission_modal.dart';
import 'package:novelly/main_page/my_book.dart';
import 'package:novelly/publisher/publisher_dashboard.dart';
import 'package:novelly/reader/sample_reader.dart';
import 'package:novelly/services/local_search_cache.dart';
import 'package:novelly/theme/theme_controller.dart';
import 'package:novelly/widgets/boi_mela_banner.dart';

void main() {

  test('Theme controller cycles through Paper Cream and Midnight Ink', () {
    final controller = NovellyThemeController.instance;
    controller.setTheme(NovellyThemeMode.paperCream);
    expect(controller.value.mode, NovellyThemeMode.paperCream);

    controller.cycleTheme();
    expect(controller.value.mode, NovellyThemeMode.midnightInk);

    controller.cycleTheme();
    expect(controller.value.mode, NovellyThemeMode.paperCream);
  });

  testWidgets('Sample Reader displays chapter teaser and typography controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SampleReaderScreen(
          title: 'Nondito Noroke',
          author: 'Humayun Ahmed',
        ),
      ),
    );

    expect(find.text('Nondito Noroke'), findsWidgets);
    expect(find.textContaining('CHAPTER I'), findsOneWidget);

    // Open typography bottom sheet
    await tester.tap(find.byTooltip('Typography Options'));
    await tester.pumpAndSettle();

    expect(find.text('Typography & Theme'), findsOneWidget);
    expect(find.text('Paper Tint'), findsOneWidget);
  });

  testWidgets('Cover Commission Modal calculates total price in real time', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoverCommissionModal(
            artistName: 'Sabyasachi Hazra',
          ),
        ),
      ),
    );

    expect(find.text('Commission Cover Art'), findsOneWidget);
    expect(find.text('Step 1: Choose Artwork Type'), findsOneWidget);
    expect(find.textContaining('৳5,000'), findsWidgets);

    // Navigate to step 2
    await tester.tap(find.text('Next Step ➔'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2: Format & Dimensions'), findsOneWidget);
  });

  testWidgets('Boi Mela Banner displays stalls and triggers stall tap callbacks', (tester) async {
    String? tappedStall;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoiMelaBannerWidget(
            onStallTap: (stall) => tappedStall = stall,
          ),
        ),
      ),
    );

    expect(find.text('EKUSHEY BOI MELA 2025'), findsOneWidget);
    expect(find.textContaining('Prothoma #402'), findsOneWidget);

    await tester.tap(find.textContaining('Prothoma #402'));
    await tester.pumpAndSettle();

    expect(tappedStall, 'Prothoma');
  });

  test('Local Search Cache Manager caches recent search queries', () {
    final cache = LocalSearchCacheManager.instance;
    cache.addRecentSearch('Humayun Ahmed');
    cache.addRecentSearch('Boi Mela 2025');

    expect(cache.recentSearches, contains('Boi Mela 2025'));
    expect(cache.recentSearches, contains('Humayun Ahmed'));
  });

  testWidgets('Personal Bookshelf in MyBookScreen displays shelf filter chips', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyBookScreen()));

    expect(find.text('Personal Bookshelf'), findsOneWidget);
    expect(find.text('Currently Reading 📖'), findsOneWidget);
    expect(find.text('Want to Read 🔖'), findsOneWidget);
  });

  testWidgets('Publisher Dashboard displays Manuscript Deal Tracker board', (tester) async {
    PublisherWorkspaceStore.resetForTesting();
    await tester.pumpWidget(const MaterialApp(home: PublisherDashboardScreen()));

    expect(find.textContaining('Manuscript Deal Tracker'), findsOneWidget);
    expect(find.textContaining('The Rain Collector'), findsOneWidget);
    expect(find.text('Under Review 🔍'), findsWidgets);
  });
}
