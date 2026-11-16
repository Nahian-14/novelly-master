import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cover/cover_artist_profile.dart';
import '../cover/cover_artist_directory.dart';
import '../cover/cover_design.dart';
import '../theme/theme_controller.dart';
import '../widgets/boi_mela_banner.dart';
import '../services/local_search_cache.dart';
import 'book_detail.dart';
import 'discover_book.dart';
import 'novelly_bottom_navigation.dart';
import 'writer_profile.dart';
import '../publisher/publisher._directory.dart';
import '../publisher/publisher_profile.dart';

const Color _muted = Color(0xFF777873);
// Authentic Boi Mela green/teal accent matching #1a454f
const Color _boiMelaGreen = Color(0xFF1A454F);
const Color _deepTealInk = Color(0xFF12343B);

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    this.books = const [],
    this.publishers = const [],
    this.coverArtists = const [],
    this.coverDesigns = const [],
    this.coverDrafts = const [],
    this.initialTab = 0,
  });

  final List<DiscoverBook> books;
  final List<PublisherEntry> publishers;
  final List<WriterProfile> coverArtists;
  final List<CoverDesign> coverDesigns;
  final List<CoverDesign> coverDrafts;
  final int initialTab;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';
  String _selectedFilter = 'All';
  late int _selectedTab;
  bool _gridView = false;

  final List<String> _quickFilterChips = const [
    'All',
    'Humayun Ahmed',
    'Boi Mela Bestsellers',
    'Sci-Fi & Thrillers',
    'Calligraphy Art',
    'Classic Literature',
    'Poetry',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  List<int> get _visibleTabIds =>
      WriterProfileScreen.currentUser.isWriter ||
          WriterProfileScreen.currentUser.isPublisher ||
          WriterProfileScreen.currentUser.isCoverArtist
      ? [0, 1, 2]
      : [0, 2];

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<DiscoverBook> get _visibleBooks {
    final query = _query.trim().toLowerCase();
    List<DiscoverBook> filtered = widget.books;

    if (_selectedFilter == 'Humayun Ahmed') {
      filtered = filtered.where((b) => b.author.contains('Humayun Ahmed')).toList();
    } else if (_selectedFilter == 'Boi Mela Bestsellers') {
      filtered = filtered.where((b) => double.tryParse(b.rating) != null && double.parse(b.rating) >= 4.8).toList();
    } else if (_selectedFilter == 'Sci-Fi & Thrillers') {
      filtered = filtered.where((b) => b.genre.contains('Young Adult') || b.genre.contains('Mystery')).toList();
    } else if (_selectedFilter == 'Calligraphy Art') {
      filtered = filtered.where((b) => b.genre.contains('Poetry') || b.genre.contains('Classic')).toList();
    } else if (_selectedFilter == 'Classic Literature') {
      filtered = filtered.where((b) => b.genre.contains('Classic') || b.genre.contains('Literary')).toList();
    } else if (_selectedFilter == 'Poetry') {
      filtered = filtered.where((b) => b.genre.contains('Poetry')).toList();
    }

    if (query.isEmpty) return filtered;

    LocalSearchCacheManager.instance.addRecentSearch(query);
    return filtered
        .where(
          (book) =>
              book.title.toLowerCase().contains(query) ||
              book.author.toLowerCase().contains(query) ||
              book.genre.toLowerCase().contains(query),
        )
        .toList();
  }

  void _openBook(DiscoverBook book) {
    HapticFeedback.lightImpact();
    final rating = double.tryParse(book.rating) ?? 0;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookDetailScreen(
          book: BookDetail(
            title: book.title,
            author: book.author,
            rating: rating,
            genres: [book.genre],
            reviews: const [],
          ),
        ),
      ),
    );
  }

  void _openPublisher(PublisherEntry publisher) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublisherProfileScreen(
          profile: PublisherProfile.preview(
            name: publisher.name,
            publishedBookCount: publisher.bookCount,
            accountId: publisher.accountId,
            imagePath: publisher.imagePath,
          ),
        ),
      ),
    );
  }

  void _navigate(NovellyNavigationDestination destination) {
    handleNovellyNavigation(
      context: context,
      currentDestination: NovellyNavigationDestination.discover,
      targetDestination: destination,
      coverDesigns: widget.coverDesigns,
      coverDrafts: widget.coverDrafts,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NovellyThemeData>(
      valueListenable: NovellyThemeController.instance,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.paperColor,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.gradientColors,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final mobile = constraints.maxWidth < 600;
                  final horizontalPadding = (constraints.maxWidth * 0.05).clamp(
                    mobile ? 16.0 : 20.0,
                    38.0,
                  );
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          mobile ? 8 : 12,
                          horizontalPadding,
                          0,
                        ),
                        child: Column(
                          children: [
                            _buildHeader(constraints.maxWidth, mobile, theme),
                            SizedBox(height: mobile ? 8 : 16),
                            _buildTabs(mobile, theme),
                            SizedBox(height: mobile ? 12 : 18),
                            _buildSearchField(mobile, theme),
                            SizedBox(height: mobile ? 10 : 14),
                            if (_selectedTab == 0) ...[
                              _buildQuickFilterChips(theme),
                              SizedBox(height: mobile ? 12 : 18),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        child: RawScrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          thickness: 6,
                          radius: const Radius.circular(8),
                          thumbColor: theme.inkColor,
                          trackColor: theme.lineColor.withValues(alpha: 0.35),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: KeyedSubtree(
                              key: ValueKey<int>(_selectedTab),
                              child: _selectedTab == 0
                                  ? _buildBookResultsWithBanner(
                                      constraints.maxWidth,
                                      horizontalPadding,
                                      theme,
                                    )
                                  : _selectedTab == 1
                                  ? PublisherDirectoryView(
                                      publishers: widget.publishers,
                                      query: _query,
                                      onPublisherTap: _openPublisher,
                                      scrollController: _scrollController,
                                      horizontalPadding: horizontalPadding,
                                    )
                                  : CoverArtistDirectoryView(
                                      coverArtists: widget.coverArtists,
                                      query: _query,
                                      onCoverArtistTap: _openCoverArtist,
                                      scrollController: _scrollController,
                                      horizontalPadding: horizontalPadding,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          mobile ? 7 : 10,
                          horizontalPadding,
                          mobile ? 8 : 10,
                        ),
                        child: _buildBottomNavigation(mobile),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _openCoverArtist(WriterProfile artist) {
    HapticFeedback.lightImpact();
    final currentUser = WriterProfileScreen.currentUser;
    final isCurrentUser =
        currentUser.isCoverArtist &&
        (artist.accountId.isNotEmpty
            ? artist.accountId == currentUser.accountId
            : artist.name == currentUser.name);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CoverArtistProfileScreen(
          profile: artist,
          isCurrentUser: isCurrentUser,
          covers: isCurrentUser ? widget.coverDesigns : const [],
          drafts: isCurrentUser ? widget.coverDrafts : const [],
          books: widget.books,
          publishers: widget.publishers,
          coverArtists: widget.coverArtists,
        ),
      ),
    );
  }

  Widget _buildHeader(double availableWidth, bool mobile, NovellyThemeData theme) {
    final titleSize = mobile
        ? (availableWidth * 0.075).clamp(29.0, 34.0)
        : (availableWidth * 0.062).clamp(36.0, 48.0);
    final controlSize = mobile ? 48.0 : 56.0;
    return SizedBox(
      height: controlSize,
      child: Row(
        children: [
          Text(
            'Novelly',
            style: TextStyle(
              color: theme.inkColor,
              fontFamily: 'Georgia',
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              letterSpacing: -2.2,
              height: 1,
            ),
          ),
          const Spacer(),
          if (_selectedTab == 0)
            SizedBox(
              width: controlSize,
              height: controlSize,
              child: IconButton(
                tooltip: _gridView
                    ? 'Switch to list view'
                    : 'Switch to grid view',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _gridView = !_gridView);
                },
                style: IconButton.styleFrom(
                  foregroundColor: theme.deepInkColor,
                  side: BorderSide(color: theme.lineColor),
                  shape: const CircleBorder(),
                ),
                icon: Icon(
                  _gridView ? Icons.view_list_rounded : Icons.tune_rounded,
                  size: mobile ? 24 : 28,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool mobile, NovellyThemeData theme) {
    const allLabels = ['Books', 'Publishers', 'Covers'];
    final tabIds = _visibleTabIds;
    return SizedBox(
      height: mobile ? 48 : 57,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: List.generate(tabIds.length, (position) {
                final tabId = tabIds[position];
                final selected = _selectedTab == tabId;
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTab = tabId);
                    },
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: selected
                              ? tabId == 1
                                    ? theme.accentGold
                                    : theme.inkColor
                              : theme.mutedColor,
                          fontSize: mobile ? 19 : 23,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        child: Text(allLabels[tabId]),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            height: 2,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: theme.lineColor)),
                Row(
                  children: List.generate(tabIds.length, (position) {
                    final tabId = tabIds[position];
                    final selected = _selectedTab == tabId;
                    return Expanded(
                      child: Center(
                        child: selected
                            ? FractionallySizedBox(
                                widthFactor: tabIds.length == 2 ? 0.44 : 0.48,
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: _selectedTab == 1 ? theme.accentGold : theme.inkColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool mobile, NovellyThemeData theme) {
    return Container(
      height: mobile ? 54 : 64,
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF11262B) : const Color(0xFFFAFBFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.isDark
              ? _boiMelaGreen.withValues(alpha: 0.5)
              : _boiMelaGreen.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? Colors.black.withValues(alpha: 0.25)
                : _boiMelaGreen.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        style: TextStyle(
          color: theme.isDark ? Colors.white : _deepTealInk,
          fontSize: mobile ? 16 : 19,
        ),
        decoration: InputDecoration(
          hintText: _selectedTab == 0
              ? 'Search books, authors, genres...'
              : 'Search ${_selectedTab == 1 ? 'publishers' : 'covers'}...',
          hintStyle: TextStyle(
            color: theme.mutedColor.withValues(alpha: 0.8),
            fontSize: mobile ? 15 : 18,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.isDark ? theme.accentGold : _boiMelaGreen,
            size: mobile ? 22 : 26,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: mobile ? 14 : 18,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilterChips(NovellyThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _quickFilterChips.map((chip) {
          final selected = _selectedFilter == chip;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedFilter = chip);
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                decoration: BoxDecoration(
                  color: selected
                      ? _boiMelaGreen
                      : (theme.isDark
                          ? const Color(0xFF11262B)
                          : const Color(0xFFF0F5F6)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? _deepTealInk
                        : (theme.isDark
                            ? _boiMelaGreen.withValues(alpha: 0.5)
                            : _boiMelaGreen.withValues(alpha: 0.2)),
                    width: selected ? 1.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _boiMelaGreen.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  chip,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : (theme.isDark ? const Color(0xFFD2E3E8) : _deepTealInk),
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookResultsWithBanner(
    double availableWidth,
    double horizontalPadding,
    NovellyThemeData theme,
  ) {
    final books = _visibleBooks;

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 6),
      children: [
        BoiMelaBannerWidget(
          onStallTap: (publisherName) {
            HapticFeedback.lightImpact();
            setState(() {
              _query = publisherName;
              _searchController.text = publisherName;
            });
          },
        ),
        if (books.isEmpty)
          _buildEmptySection('No books found')
        else if (_gridView)
          _buildGridView(books, availableWidth, theme)
        else
          _buildListView(books, availableWidth, theme),
      ],
    );
  }

  Widget _buildGridView(
    List<DiscoverBook> books,
    double availableWidth,
    NovellyThemeData theme,
  ) {
    final mobile = availableWidth < 600;
    final columns = availableWidth >= 900
        ? 4
        : availableWidth >= 650
        ? 3
        : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: mobile ? 12 : 16,
        mainAxisSpacing: mobile ? 12 : 16,
        childAspectRatio: mobile ? 0.95 : 0.72,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) => _GridBookCard(
        book: books[index],
        onTap: () => _openBook(books[index]),
        compact: mobile,
        theme: theme,
      ),
    );
  }

  Widget _buildListView(
    List<DiscoverBook> books,
    double availableWidth,
    NovellyThemeData theme,
  ) {
    final cardHeight = (availableWidth * 0.225).clamp(138.0, 172.0);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      separatorBuilder: (context, index) => const SizedBox(height: 19),
      itemBuilder: (context, index) => SizedBox(
        height: cardHeight,
        child: _ListBookCard(
          book: books[index],
          onTap: () => _openBook(books[index]),
          theme: theme,
        ),
      ),
    );
  }

  Widget _buildEmptySection(String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(title, style: const TextStyle(color: _muted, fontSize: 17)),
      ),
    );
  }

  Widget _buildBottomNavigation(bool mobile) {
    final account = WriterProfileScreen.currentUser;
    return NovellyBottomNavigation(
      libraryLabel: account.isCoverArtist
          ? 'My Designs'
          : account.isPublisher
          ? 'My Publishing'
          : 'My Book',
      libraryIcon: account.isCoverArtist
          ? Icons.palette_outlined
          : Icons.menu_book_outlined,
      selectedDestination: NovellyNavigationDestination.discover,
      compact: mobile,
      onDestinationSelected: _navigate,
    );
  }
}

class _ListBookCard extends StatelessWidget {
  const _ListBookCard({
    required this.book,
    required this.onTap,
    required this.theme,
  });

  final DiscoverBook book;
  final VoidCallback onTap;
  final NovellyThemeData theme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 500;
        final coverWidth = (constraints.maxWidth * 0.185).clamp(
          narrow ? 74.0 : 84.0,
          128.0,
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.isDark
                  ? const Color(0xFF11262B)
                  : const Color(0xFFFAFBFB),
              border: Border.all(
                color: theme.isDark
                    ? _boiMelaGreen.withValues(alpha: 0.5)
                    : _boiMelaGreen.withValues(alpha: 0.2),
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : _boiMelaGreen.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: coverWidth,
                  child: _BookCoverTile(
                    title: book.title,
                    author: book.author,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(narrow ? 13 : 24, 12, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.isDark ? Colors.white : _deepTealInk,
                            fontSize: narrow ? 16 : 25,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.mutedColor,
                            fontSize: narrow ? 13 : 18,
                          ),
                        ),
                        SizedBox(height: narrow ? 6 : 8),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: narrow ? 7 : 13,
                          runSpacing: 4,
                          children: [
                            _RatingStars(size: narrow ? 14 : 19),
                            Text(
                              book.rating,
                              style: TextStyle(
                                color: theme.inkColor,
                                fontSize: narrow ? 12 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 16,
                              color: theme.isDark
                                  ? _boiMelaGreen.withValues(alpha: 0.4)
                                  : _boiMelaGreen.withValues(alpha: 0.25),
                            ),
                            // Boi Mela Green Accent Genre Tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: theme.isDark
                                    ? _boiMelaGreen.withValues(alpha: 0.35)
                                    : const Color(0xFFE8F1F2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: theme.isDark
                                      ? _boiMelaGreen.withValues(alpha: 0.6)
                                      : _boiMelaGreen.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                book.genre,
                                style: TextStyle(
                                  color: theme.isDark ? Colors.white : _deepTealInk,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.isDark
                            ? const Color(0xFF15333B)
                            : const Color(0xFFE8F1F2),
                        border: Border.all(
                          color: _boiMelaGreen.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: theme.isDark ? Colors.white : _deepTealInk,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BookCoverTile extends StatelessWidget {
  const _BookCoverTile({
    required this.title,
    required this.author,
  });

  final String title;
  final String author;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF153A40), Color(0xFF0D292E)],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFFE5AE4D),
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Georgia',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    author,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE5AE4D),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridBookCard extends StatelessWidget {
  const _GridBookCard({
    required this.book,
    required this.onTap,
    required this.compact,
    required this.theme,
  });

  final DiscoverBook book;
  final VoidCallback onTap;
  final bool compact;
  final NovellyThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.isDark
              ? const Color(0xFF11262B)
              : const Color(0xFFFAFBFB),
          border: Border.all(
            color: _boiMelaGreen.withValues(alpha: theme.isDark ? 0.45 : 0.2),
            width: 1.1,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: theme.isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : _boiMelaGreen.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: compact ? 7 : 6,
              child: _BookCoverTile(
                title: book.title,
                author: book.author,
              ),
            ),
            Expanded(
              flex: compact ? 4 : 5,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 12,
                  vertical: compact ? 4 : 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: compact
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.isDark ? Colors.white : _deepTealInk,
                        fontSize: compact ? 13 : 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!compact) const SizedBox(height: 3),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.mutedColor,
                        fontSize: compact ? 11 : 13,
                      ),
                    ),
                    if (!compact) const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: theme.accentGold, size: compact ? 12 : 15),
                            SizedBox(width: compact ? 2 : 4),
                            Text(
                              book.rating,
                              style: TextStyle(
                                color: theme.inkColor,
                                fontSize: compact ? 11 : 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: theme.isDark
                                  ? _boiMelaGreen.withValues(alpha: 0.35)
                                  : const Color(0xFFE8F1F2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              book.genre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.isDark ? Colors.white : _deepTealInk,
                                fontSize: compact ? 9.5 : 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({this.size = 19});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: const Color(0xFFC89543), size: size),
        Icon(Icons.star, color: const Color(0xFFC89543), size: size),
        Icon(Icons.star, color: const Color(0xFFC89543), size: size),
        Icon(Icons.star, color: const Color(0xFFC89543), size: size),
        Icon(Icons.star_half, color: const Color(0xFFC89543), size: size),
      ],
    );
  }
}
