import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novelly/main_page/book_detail.dart';
import 'package:novelly/main_page/discover.dart';
import 'package:novelly/main_page/discover_book.dart';
import 'package:novelly/main_page/writer_profile.dart';

import 'fixtures/writer_profile_fixture.dart';

void main() {
  setUp(() {
    WriterProfileScreen.currentUser = const WriterProfile(name: 'Your profile');
  });

  testWidgets('Discover book cards render available cover images', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DiscoverScreen(
          books: [
            DiscoverBook(
              title: 'Image Test',
              author: 'A. Writer',
              rating: 'New',
              genre: 'Fantasy',
              imageUrl: 'assets/novelly2.png',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is FileImage &&
            (widget.image as FileImage).file.path == 'assets/novelly2.png',
      ),
      findsOneWidget,
    );
  });

  testWidgets('profile edit dialog can be cancelled without changing profile', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DiscoverScreen()));
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Author Profile'), findsOneWidget);
    expect(find.text('Your profile'), findsOneWidget);
    expect(find.byTooltip('Edit stats'), findsNothing);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'New Name');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Your profile'), findsOneWidget);
    expect(find.text('New Name'), findsNothing);
  });

  testWidgets('sample author profile data is visible and derived from books', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: WriterProfileScreen(profile: sampleWriterProfile)),
    );

    expect(find.text('George Orwell'), findsOneWidget);
    expect(find.text('Published books'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Reviews'), findsOneWidget);
    expect(find.text('312'), findsOneWidget);
    expect(find.text('8.4K'), findsOneWidget);
    expect(find.byTooltip('Edit stats'), findsNothing);
    expect(find.text('Writer'), findsOneWidget);
    expect(find.byTooltip('https://facebook.com/georgeorwell'), findsOneWidget);
    expect(
      find.byTooltip('https://instagram.com/georgeorwell'),
      findsOneWidget,
    );
    expect(find.byTooltip('https://george-orwell.example'), findsOneWidget);
  });

  test(
    'public writer profile data includes the account ID and published books',
    () {
      final profile = WriterProfile.fromJson({
        'uid': 'writer-123',
        'name': 'Published Writer',
        'role': 'Writer',
        'about': 'Writes speculative fiction.',
        'publishedBookCount': 1,
        'books': [
          {'title': 'A Published Story', 'rating': 0},
        ],
      });

      expect(profile.accountId, 'writer-123');
      expect(profile.about, 'Writes speculative fiction.');
      expect(profile.publishedBookCount, 1);
      expect(profile.books.single.title, 'A Published Story');
    },
  );

  testWidgets('current user can cancel or confirm logging out', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WriterProfileScreen(isCurrentUser: true)),
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(find.text('Author Profile'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('book author name opens that writer profile', (tester) async {
    final book = BookDetail(
      title: 'Sample book',
      author: 'Eleanor Hart',
      rating: 4.5,
      genres: ['Fiction'],
      reviews: [
        BookReview(
          reviewerName: 'Reader',
          rating: 4,
          createdAt: DateTime(2026),
          body: 'A review.',
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp(home: BookDetailScreen(book: book)));

    await tester.tap(find.text('by Eleanor Hart'));
    await tester.pumpAndSettle();

    expect(find.text('Author Profile'), findsOneWidget);
    expect(find.text('Eleanor Hart'), findsOneWidget);
    expect(find.text('Published books'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('0'), findsOneWidget);
  });
}
