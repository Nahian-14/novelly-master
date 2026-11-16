import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../chat/chat_list.dart';
import '../cover/cover_artist_profile.dart';
import '../cover/cover_design.dart';
import '../cover/my_designs.dart';
import '../publisher/publisher._directory.dart';
import '../publisher/publisher_dashboard.dart';
import '../publisher/publisher_profile.dart';
import 'discover.dart';
import 'discover_book.dart';
import 'my_book.dart';
import 'writer_profile.dart';

const Color _deepInk = Color(0xFF12343B);
const Color _gold = Color(0xFFE5AE4D);

enum NovellyNavigationDestination { discover, library, chat, profile }

void handleNovellyNavigation({
  required BuildContext context,
  required NovellyNavigationDestination currentDestination,
  required NovellyNavigationDestination targetDestination,
  List<DiscoverBook> books = const [],
  List<PublisherEntry> publishers = const [],
  List<WriterProfile> coverArtists = const [],
  List<CoverDesign> coverDesigns = const [],
  List<CoverDesign> coverDrafts = const [],
}) {
  if (currentDestination == targetDestination) return;

  HapticFeedback.selectionClick();

  final account = WriterProfileScreen.currentUser;
  Widget targetScreen;

  switch (targetDestination) {
    case NovellyNavigationDestination.discover:
      targetScreen = DiscoverScreen(
        books: books,
        publishers: publishers,
        coverArtists: coverArtists,
        coverDesigns: coverDesigns,
        coverDrafts: coverDrafts,
      );
      break;
    case NovellyNavigationDestination.library:
      targetScreen = account.isCoverArtist
          ? MyDesignsScreen(covers: coverDesigns, drafts: coverDrafts)
          : account.isPublisher
          ? const PublisherDashboardScreen()
          : const MyBookScreen();
      break;
    case NovellyNavigationDestination.chat:
      targetScreen = const ChatListScreen();
      break;
    case NovellyNavigationDestination.profile:
      if (account.isCoverArtist) {
        targetScreen = CoverArtistProfileScreen(
          isCurrentUser: true,
          covers: coverDesigns,
          drafts: coverDrafts,
          books: books,
          publishers: publishers,
          coverArtists: coverArtists,
        );
      } else if (account.isPublisher) {
        targetScreen = PublisherProfileScreen(
          isCurrentUser: true,
          profile: PublisherProfileScreen.currentUser,
        );
      } else {
        targetScreen = const WriterProfileScreen(isCurrentUser: true);
      }
      break;
  }

  Navigator.of(context).pushReplacement(
    PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    ),
  );
}

class NovellyBottomNavigation extends StatelessWidget {
  const NovellyBottomNavigation({
    required this.libraryLabel,
    required this.selectedDestination,
    required this.compact,
    required this.onDestinationSelected,
    this.libraryIcon = Icons.menu_book_outlined,
    super.key,
  });

  final String libraryLabel;
  final IconData libraryIcon;
  final NovellyNavigationDestination selectedDestination;
  final bool compact;
  final ValueChanged<NovellyNavigationDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final destinations = [
      (
        destination: NovellyNavigationDestination.discover,
        icon: Icons.explore_outlined,
        label: 'Discover',
      ),
      (
        destination: NovellyNavigationDestination.library,
        icon: libraryIcon,
        label: libraryLabel,
      ),
      (
        destination: NovellyNavigationDestination.chat,
        icon: Icons.chat_bubble_outline,
        label: 'Chat',
      ),
      (
        destination: NovellyNavigationDestination.profile,
        icon: Icons.person_outline,
        label: 'Profile',
      ),
    ];

    return Container(
      height: compact ? 68 : 92,
      decoration: BoxDecoration(
        color: _deepInk,
        borderRadius: BorderRadius.circular(compact ? 23 : 29),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final item in destinations)
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onDestinationSelected(item.destination);
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: selectedDestination == item.destination ? 1.12 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          item.icon,
                          color: selectedDestination == item.destination
                              ? _gold
                              : Colors.white.withValues(alpha: 0.75),
                          size: compact ? 25 : 34,
                        ),
                      ),
                      SizedBox(height: compact ? 2 : 4),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selectedDestination == item.destination
                              ? _gold
                              : Colors.white.withValues(alpha: 0.75),
                          fontSize: compact ? 12 : 16,
                          fontWeight: selectedDestination == item.destination
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
