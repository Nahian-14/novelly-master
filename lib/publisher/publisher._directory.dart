import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme_controller.dart';
import '../widgets/image_provider_for_path.dart';

@immutable
class PublisherEntry {
  const PublisherEntry({
    required this.name,
    required this.rating,
    required this.bookCount,
    this.accountId = '',
    this.imagePath,
    this.specialty,
    this.stallNumber,
    this.establishedYear,
    this.location,
    this.profileDetails = const {},
    this.isBoiMelaPavilion = true,
  });

  factory PublisherEntry.fromJson(Map<String, dynamic> json) {
    final publisherData = json['publisherProfile'];
    final details = publisherData is Map<String, dynamic>
        ? publisherData
        : const <String, dynamic>{};
    final publisherImage = details['imageUrl'];
    final profileImage = json['profileImageUrl'];
    final count = json['publishedBookCount'];
    return PublisherEntry(
      name: json['name'] is String ? json['name'] as String : 'Publisher',
      rating: 0,
      bookCount: count is int ? count : 0,
      accountId: json['uid'] is String ? json['uid'] as String : '',
      imagePath: publisherImage is String
          ? publisherImage
          : profileImage is String
          ? profileImage
          : null,
      specialty: details['genresPublished'] is String
          ? details['genresPublished'] as String
          : null,
      profileDetails: json,
    );
  }

  final String name;
  final double rating;
  final int bookCount;
  final String accountId;
  final String? imagePath;
  final String? specialty;
  final String? stallNumber;
  final String? establishedYear;
  final String? location;
  final Map<String, dynamic> profileDetails;
  final bool isBoiMelaPavilion;

  /// Meaningful literary specialty for Bangladeshi publishing houses
  String get effectiveSpecialty {
    if (specialty != null && specialty!.isNotEmpty) return specialty!;
    final lower = name.toLowerCase();
    if (lower.contains('prothoma')) {
      return 'Contemporary Literature, Essays & Thought';
    } else if (lower.contains('sheba')) {
      return 'Thrillers, Spy, Westerns & Classics';
    } else if (lower.contains('batighar')) {
      return 'World Classics, Heritage & Poetry';
    } else if (lower.contains('anyaprokash')) {
      return 'Humayun Ahmed Works, Novels & Bestsellers';
    } else if (lower.contains('upl') || lower.contains('university press')) {
      return 'Academic, Research & National History';
    } else if (lower.contains('ananya')) {
      return 'Modern Fiction, Memoirs & Poetry';
    } else if (lower.contains('kakoli')) {
      return "Children's Literature, Teens & Fiction";
    } else if (lower.contains('mowla')) {
      return 'Bengali Heritage Literature & Essays';
    }
    return 'Literary Fiction, Research & Poetry';
  }

  /// Authentic Boi Mela Pavilion / Stall number
  String get effectiveStallNumber {
    if (stallNumber != null && stallNumber!.isNotEmpty) return stallNumber!;
    final lower = name.toLowerCase();
    if (lower.contains('prothoma')) return 'Pavilion #402';
    if (lower.contains('sheba')) return 'Pavilion #115';
    if (lower.contains('batighar')) return 'Pavilion #204';
    if (lower.contains('anyaprokash')) return 'Pavilion #310';
    if (lower.contains('upl') || lower.contains('university press')) {
      return 'Pavilion #501';
    }
    if (lower.contains('ananya')) return 'Stall #290';
    if (lower.contains('kakoli')) return 'Stall #240';
    if (lower.contains('mowla')) return 'Pavilion #310';
    return 'Pavilion #${(name.hashCode % 450).abs() + 100}';
  }

  String get effectiveLocation {
    if (location != null && location!.isNotEmpty) return location!;
    final lower = name.toLowerCase();
    if (lower.contains('prothoma')) return 'Karwan Bazar, Dhaka';
    if (lower.contains('sheba')) return 'Segunbagicha, Dhaka';
    if (lower.contains('batighar')) return 'Banglamotor, Dhaka';
    if (lower.contains('upl') || lower.contains('university press')) {
      return 'Farmgate, Dhaka';
    }
    return 'Banglabazar, Dhaka';
  }

  String get effectiveEstd {
    if (establishedYear != null && establishedYear!.isNotEmpty) {
      return establishedYear!;
    }
    final lower = name.toLowerCase();
    if (lower.contains('prothoma')) return '1998';
    if (lower.contains('sheba')) return '1963';
    if (lower.contains('batighar')) return '2005';
    if (lower.contains('anyaprokash')) return '1997';
    if (lower.contains('upl') || lower.contains('university press')) {
      return '1975';
    }
    if (lower.contains('mowla')) return '1954';
    if (lower.contains('kakoli')) return '1972';
    if (lower.contains('ananya')) return '1988';
    return '1990';
  }
}

class PublisherDirectoryView extends StatefulWidget {
  const PublisherDirectoryView({
    required this.publishers,
    required this.query,
    this.onPublisherTap,
    this.scrollController,
    this.horizontalPadding = 16.0,
    this.isGridView = false,
    super.key,
  });

  final List<PublisherEntry> publishers;
  final String query;
  final ValueChanged<PublisherEntry>? onPublisherTap;
  final ScrollController? scrollController;
  final double horizontalPadding;
  final bool isGridView;

  @override
  State<PublisherDirectoryView> createState() => _PublisherDirectoryViewState();
}

class _PublisherDirectoryViewState extends State<PublisherDirectoryView> {
  String _selectedFilter = 'All';

  // Authentic Boi Mela green/teal accent matching #1a454f
  static const Color boiMelaGreen = Color(0xFF1A454F);
  static const Color deepTealInk = Color(0xFF12343B);

  static const List<String> _filters = [
    'All',
    'Boi Mela Pavilions',
    'Top Rated ★ 4.8+',
    'Fiction & Thrillers',
    'Classics & Heritage',
    'Academic & Essays',
  ];

  List<PublisherEntry> _filterPublishers(
    List<PublisherEntry> list,
    String query,
  ) {
    var result = list;
    final normalized = query.trim().toLowerCase();

    if (normalized.isNotEmpty) {
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(normalized) ||
                p.effectiveSpecialty.toLowerCase().contains(normalized) ||
                p.effectiveStallNumber.toLowerCase().contains(normalized) ||
                p.effectiveLocation.toLowerCase().contains(normalized),
          )
          .toList();
    }

    if (_selectedFilter == 'Boi Mela Pavilions') {
      result = result.where((p) => p.isBoiMelaPavilion).toList();
    } else if (_selectedFilter == 'Top Rated ★ 4.8+') {
      result = result.where((p) => p.rating >= 4.8).toList();
    } else if (_selectedFilter == 'Fiction & Thrillers') {
      result = result
          .where(
            (p) =>
                p.effectiveSpecialty.toLowerCase().contains('thriller') ||
                p.effectiveSpecialty.toLowerCase().contains('novel') ||
                p.effectiveSpecialty.toLowerCase().contains('fiction'),
          )
          .toList();
    } else if (_selectedFilter == 'Classics & Heritage') {
      result = result
          .where(
            (p) =>
                p.effectiveSpecialty.toLowerCase().contains('classic') ||
                p.effectiveSpecialty.toLowerCase().contains('heritage') ||
                p.effectiveSpecialty.toLowerCase().contains('poetry'),
          )
          .toList();
    } else if (_selectedFilter == 'Academic & Essays') {
      result = result
          .where(
            (p) =>
                p.effectiveSpecialty.toLowerCase().contains('academic') ||
                p.effectiveSpecialty.toLowerCase().contains('essay') ||
                p.effectiveSpecialty.toLowerCase().contains('research'),
          )
          .toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NovellyThemeData>(
      valueListenable: NovellyThemeController.instance,
      builder: (context, theme, child) {
        if (widget.publishers.isEmpty) {
          return ListView(
            controller: widget.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              widget.horizontalPadding,
              30,
              widget.horizontalPadding,
              30,
            ),
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: boiMelaGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: boiMelaGreen,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No publishers yet',
                      style: TextStyle(
                        color: theme.mutedColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final visiblePublishers = _filterPublishers(
          widget.publishers,
          widget.query,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final isCompact = availableWidth < 500;

            return ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(
                widget.horizontalPadding,
                4,
                widget.horizontalPadding,
                16,
              ),
              children: [
                // Boi Mela Green (#1a454f) Filter Pills
                _buildFilterChips(theme),
                const SizedBox(height: 14),

                // Content View (Grid or List)
                if (visiblePublishers.isEmpty)
                  _buildEmptySearchState(theme)
                else if (widget.isGridView)
                  _buildGridView(visiblePublishers, theme, availableWidth)
                else
                  _buildListView(visiblePublishers, theme, isCompact),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChips(NovellyThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedFilter = filter);
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? boiMelaGreen
                      : (theme.isDark
                            ? const Color(0xFF11262B)
                            : boiMelaGreen.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (theme.isDark ? theme.accentGold : boiMelaGreen)
                        : boiMelaGreen.withValues(
                            alpha: theme.isDark ? 0.5 : 0.25,
                          ),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: boiMelaGreen.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (filter.contains('★'))
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Color(0xFFE5AE4D),
                        ),
                      ),
                    Text(
                      filter,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (theme.isDark ? Colors.white70 : deepTealInk),
                        fontSize: 12.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListView(
    List<PublisherEntry> publishers,
    NovellyThemeData theme,
    bool isCompact,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: publishers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final publisher = publishers[index];
        return _PublisherCard(
          publisher: publisher,
          theme: theme,
          isCompact: isCompact,
          onTap: widget.onPublisherTap == null
              ? null
              : () => widget.onPublisherTap!(publisher),
        );
      },
    );
  }

  Widget _buildGridView(
    List<PublisherEntry> publishers,
    NovellyThemeData theme,
    double availableWidth,
  ) {
    final crossAxisCount = availableWidth > 640 ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: publishers.length,
      itemBuilder: (context, index) {
        final publisher = publishers[index];
        return _PublisherGridCard(
          publisher: publisher,
          theme: theme,
          onTap: widget.onPublisherTap == null
              ? null
              : () => widget.onPublisherTap!(publisher),
        );
      },
    );
  }

  Widget _buildEmptySearchState(NovellyThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF11262B) : const Color(0xFFFAFBFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: boiMelaGreen.withValues(alpha: theme.isDark ? 0.5 : 0.25),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: boiMelaGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: boiMelaGreen,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No publishers found',
              style: TextStyle(
                color: theme.isDark ? Colors.white : deepTealInk,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try clearing search keywords or selecting "All".',
              style: TextStyle(color: theme.mutedColor, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedFilter = 'All');
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset Filter'),
              style: TextButton.styleFrom(foregroundColor: boiMelaGreen),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular Profile Picture for Publishers with Boi Mela Green (#1a454f) Gradient Ring
class _PublisherAvatar extends StatelessWidget {
  const _PublisherAvatar({
    required this.publisher,
    required this.theme,
    required this.compact,
  });

  final PublisherEntry publisher;
  final NovellyThemeData theme;
  final bool compact;

  static const Color boiMelaGreen = Color(0xFF1A454F);
  static const Color deepTealInk = Color(0xFF12343B);

  String _getInitials(String input) {
    final words = input.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return 'P';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = compact ? 58.0 : 66.0;
    final hasImage =
        publisher.imagePath != null && publisher.imagePath!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [boiMelaGreen, deepTealInk],
        ),
        boxShadow: [
          BoxShadow(
            color: boiMelaGreen.withValues(alpha: theme.isDark ? 0.35 : 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.isDark
              ? const Color(0xFF11262B)
              : const Color(0xFFF0F5F6),
        ),
        child: ClipOval(
          child: hasImage
              ? Image(
                  image: imageProviderForPath(publisher.imagePath!),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        color: theme.isDark ? theme.accentGold : boiMelaGreen,
                        size: 21,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _getInitials(publisher.name),
                        style: TextStyle(
                          color: theme.isDark ? Colors.white : deepTealInk,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Redesigned Publisher Card (List View) with Boi Mela Green Accent (#1a454f)
class _PublisherCard extends StatelessWidget {
  const _PublisherCard({
    required this.publisher,
    required this.theme,
    required this.isCompact,
    this.onTap,
  });

  final PublisherEntry publisher;
  final NovellyThemeData theme;
  final bool isCompact;
  final VoidCallback? onTap;

  static const Color boiMelaGreen = Color(0xFF1A454F);
  static const Color deepTealInk = Color(0xFF12343B);

  @override
  Widget build(BuildContext context) {
    final accentGold = theme.accentGold;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: theme.isDark
                ? const Color(0xFF11262B)
                : const Color(0xFFFAFBFB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.isDark
                  ? boiMelaGreen.withValues(alpha: 0.5)
                  : boiMelaGreen.withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : boiMelaGreen.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Profile Picture with Boi Mela Green Accent Frame
              _PublisherAvatar(
                publisher: publisher,
                theme: theme,
                compact: isCompact,
              ),
              SizedBox(width: isCompact ? 12 : 16),

              // Center Publisher Dossier
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      publisher.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.isDark ? Colors.white : deepTealInk,
                        fontSize: isCompact ? 16 : 18.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      publisher.effectiveSpecialty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.mutedColor,
                        fontSize: isCompact ? 12 : 13,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${publisher.effectiveLocation} • Estd ${publisher.effectiveEstd}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.mutedColor.withValues(alpha: 0.8),
                        fontSize: isCompact ? 11 : 11.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Status & Boi Mela Green Accent Metrics Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Rating Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accentGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: accentGold.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: accentGold,
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                publisher.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  color: theme.inkColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Books Catalog Badge (with Boi Mela Green Accent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.isDark
                                ? boiMelaGreen.withValues(alpha: 0.35)
                                : boiMelaGreen.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: theme.isDark
                                  ? boiMelaGreen.withValues(alpha: 0.65)
                                  : boiMelaGreen.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                color: theme.isDark
                                    ? theme.accentGold
                                    : boiMelaGreen,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${publisher.bookCount}',
                                style: TextStyle(
                                  color: theme.isDark
                                      ? Colors.white
                                      : deepTealInk,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'books',
                                style: TextStyle(
                                  color: theme.isDark
                                      ? Colors.white70
                                      : theme.mutedColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Pavilion Tag (with Boi Mela Green Accent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: boiMelaGreen.withValues(
                              alpha: theme.isDark ? 0.3 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            publisher.effectiveStallNumber,
                            style: TextStyle(
                              color: theme.isDark
                                  ? Colors.white70
                                  : deepTealInk,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Boi Mela Green Accent Trailing Action
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.isDark
                        ? boiMelaGreen.withValues(alpha: 0.45)
                        : boiMelaGreen.withValues(alpha: 0.10),
                    border: Border.all(
                      color: boiMelaGreen.withValues(
                        alpha: theme.isDark ? 0.6 : 0.3,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.isDark ? theme.accentGold : boiMelaGreen,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Redesigned Publisher Card (Grid View) with Boi Mela Green Accent (#1a454f)
class _PublisherGridCard extends StatelessWidget {
  const _PublisherGridCard({
    required this.publisher,
    required this.theme,
    this.onTap,
  });

  final PublisherEntry publisher;
  final NovellyThemeData theme;
  final VoidCallback? onTap;

  static const Color boiMelaGreen = Color(0xFF1A454F);
  static const Color deepTealInk = Color(0xFF12343B);

  @override
  Widget build(BuildContext context) {
    final accentGold = theme.accentGold;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.isDark
                ? const Color(0xFF11262B)
                : const Color(0xFFFAFBFB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: boiMelaGreen.withValues(alpha: theme.isDark ? 0.5 : 0.22),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : boiMelaGreen.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PublisherAvatar(
                publisher: publisher,
                theme: theme,
                compact: true,
              ),
              const SizedBox(height: 8),

              Text(
                publisher.name,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.isDark ? Colors.white : deepTealInk,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                publisher.effectiveSpecialty,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.mutedColor,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 13, color: accentGold),
                      const SizedBox(width: 2),
                      Text(
                        publisher.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: theme.inkColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.isDark
                          ? boiMelaGreen.withValues(alpha: 0.35)
                          : boiMelaGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${publisher.bookCount} books',
                      style: TextStyle(
                        color: theme.isDark ? Colors.white70 : deepTealInk,
                        fontSize: 10.5,
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
    );
  }
}
