import 'dart:io';

import 'package:flutter/material.dart';
import '../main_page/writer_profile.dart';
import '../theme/theme_controller.dart';

class CoverArtistDirectoryView extends StatefulWidget {
  const CoverArtistDirectoryView({
    required this.coverArtists,
    required this.query,
    this.onCoverArtistTap,
    this.scrollController,
    this.horizontalPadding = 16.0,
    this.isGridView = false,
    super.key,
  });

  final List<WriterProfile> coverArtists;
  final String query;
  final ValueChanged<WriterProfile>? onCoverArtistTap;
  final ScrollController? scrollController;
  final double horizontalPadding;
  final bool isGridView;

  @override
  State<CoverArtistDirectoryView> createState() => _CoverArtistDirectoryViewState();
}

class _CoverArtistDirectoryViewState extends State<CoverArtistDirectoryView> {
  String _selectedFilter = 'All';

  // Authentic Boi Mela green/teal accent matching #1a454f
  static const Color boiMelaGreen = Color(0xFF1A454F);
  static const Color deepTealInk = Color(0xFF12343B);

  static const List<String> _filters = [
    'All',
    'Open for Commissions',
    'Calligraphy & Lettering',
    'Digital & Canvas',
    'Minimalist Typography',
  ];

  List<WriterProfile> _filterArtists(List<WriterProfile> list, String query) {
    var result = list.where((artist) => artist.isCoverArtist).toList();
    final normalized = query.trim().toLowerCase();

    if (normalized.isNotEmpty) {
      result = result
          .where(
            (artist) =>
                artist.name.toLowerCase().contains(normalized) ||
                artist.about.toLowerCase().contains(normalized) ||
                artist.designSpecialization.toLowerCase().contains(normalized) ||
                artist.artStyle.toLowerCase().contains(normalized),
          )
          .toList();
    }

    if (_selectedFilter == 'Open for Commissions') {
      result = result
          .where(
            (a) =>
                a.workAvailability.toLowerCase().contains('available') ||
                a.acceptsCustomRequests.toLowerCase().contains('yes') ||
                a.about.toLowerCase().contains('commission'),
          )
          .toList();
    } else if (_selectedFilter == 'Calligraphy & Lettering') {
      result = result
          .where(
            (a) =>
                a.designSpecialization.toLowerCase().contains('calligraphy') ||
                a.about.toLowerCase().contains('calligraphy') ||
                a.servicesOffered.toLowerCase().contains('calligraphy'),
          )
          .toList();
    } else if (_selectedFilter == 'Digital & Canvas') {
      result = result
          .where(
            (a) =>
                a.artStyle.toLowerCase().contains('digital') ||
                a.artStyle.toLowerCase().contains('canvas') ||
                a.about.toLowerCase().contains('digital') ||
                a.about.toLowerCase().contains('canvas'),
          )
          .toList();
    } else if (_selectedFilter == 'Minimalist Typography') {
      result = result
          .where(
            (a) =>
                a.designSpecialization.toLowerCase().contains('minimalist') ||
                a.about.toLowerCase().contains('minimalist') ||
                a.artStyle.toLowerCase().contains('typography'),
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
        final visibleArtists = _filterArtists(widget.coverArtists, widget.query);

        if (visibleArtists.isEmpty) {
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    widget.query.isEmpty
                        ? 'No cover artists yet'
                        : 'No cover artists found',
                    style: TextStyle(
                      color: theme.mutedColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

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
                // Green Accent Filter Chips
                _buildFilterChips(theme),
                const SizedBox(height: 14),

                // Content View (Grid or List)
                if (widget.isGridView)
                  _buildGridView(visibleArtists, theme, availableWidth)
                else
                  _buildListView(visibleArtists, theme, isCompact),
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
              onTap: () => setState(() => _selectedFilter = filter),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? boiMelaGreen
                      : (theme.isDark
                          ? const Color(0xFF11262B)
                          : const Color(0xFFF0F5F6)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? deepTealInk
                        : (theme.isDark
                            ? boiMelaGreen.withValues(alpha: 0.5)
                            : boiMelaGreen.withValues(alpha: 0.2)),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: boiMelaGreen.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (filter == 'Open for Commissions')
                      const Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: Icon(
                          Icons.brush_rounded,
                          size: 13,
                          color: Color(0xFFE5AE4D),
                        ),
                      ),
                    Text(
                      filter,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (theme.isDark
                                ? const Color(0xFFD2E3E8)
                                : deepTealInk),
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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
    List<WriterProfile> artists,
    NovellyThemeData theme,
    bool isCompact,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: artists.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final artist = artists[index];
        return _CoverArtistCard(
          artist: artist,
          theme: theme,
          isCompact: isCompact,
          onTap: widget.onCoverArtistTap == null
              ? null
              : () => widget.onCoverArtistTap!(artist),
        );
      },
    );
  }

  Widget _buildGridView(
    List<WriterProfile> artists,
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
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return _CoverArtistGridCard(
          artist: artist,
          theme: theme,
          onTap: widget.onCoverArtistTap == null
              ? null
              : () => widget.onCoverArtistTap!(artist),
        );
      },
    );
  }
}

/// Circular Profile Picture for Cover Artists with Green Accent Ring
class _CoverArtistAvatar extends StatelessWidget {
  const _CoverArtistAvatar({
    required this.artist,
    required this.theme,
    required this.compact,
  });

  final WriterProfile artist;
  final NovellyThemeData theme;
  final bool compact;

  static const Color boiMelaGreen = Color(0xFF1A454F);
  static const Color deepTealInk = Color(0xFF12343B);

  String _getInitials(String input) {
    final words = input.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return 'A';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = compact ? 58.0 : 66.0;
    final imagePath = artist.profileImagePath;
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            boiMelaGreen,
            deepTealInk,
          ],
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
          color: theme.isDark ? const Color(0xFF11262B) : const Color(0xFFF0F5F6),
        ),
        child: ClipOval(
          child: hasImage
              ? Image.file(
                  File(imagePath),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        color: theme.isDark ? theme.accentGold : boiMelaGreen,
                        size: 21,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _getInitials(artist.name),
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

/// Redesigned Cover Artist Card (List View) with Boi Mela Green (#1a454f) Accent and Circular Profile Picture
class _CoverArtistCard extends StatelessWidget {
  const _CoverArtistCard({
    required this.artist,
    required this.theme,
    required this.isCompact,
    this.onTap,
  });

  final WriterProfile artist;
  final NovellyThemeData theme;
  final bool isCompact;
  final VoidCallback? onTap;

  static const Color boiMelaGreen = Color(0xFF1A454F);
  static const Color deepTealInk = Color(0xFF12343B);

  @override
  Widget build(BuildContext context) {
    final specialization = artist.designSpecialization.isNotEmpty
        ? artist.designSpecialization
        : (artist.about.isNotEmpty ? artist.about : 'Cover Artist');

    final subInfo = artist.artStyle.isNotEmpty
        ? '${artist.artStyle}${artist.yearsOfExperience.isNotEmpty ? ' • ${artist.yearsOfExperience}' : ''}'
        : (artist.yearsOfExperience.isNotEmpty
            ? '${artist.yearsOfExperience} experience'
            : '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
              _CoverArtistAvatar(
                artist: artist,
                theme: theme,
                compact: isCompact,
              ),
              SizedBox(width: isCompact ? 12 : 16),

              // Center Artist Dossier
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      artist.name,
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
                      specialization,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.mutedColor,
                        fontSize: isCompact ? 12 : 13,
                        height: 1.25,
                      ),
                    ),
                    if (subInfo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subInfo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.mutedColor.withValues(alpha: 0.8),
                          fontSize: isCompact ? 11 : 11.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Boi Mela Green Accent Status / Service Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Availability / Commission Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.isDark
                                ? boiMelaGreen.withValues(alpha: 0.35)
                                : const Color(0xFFE8F1F2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: theme.isDark
                                  ? boiMelaGreen.withValues(alpha: 0.6)
                                  : boiMelaGreen.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.brush_rounded,
                                color: theme.isDark ? theme.accentGold : boiMelaGreen,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Cover Artist',
                                style: TextStyle(
                                  color: theme.isDark ? Colors.white : deepTealInk,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Custom requests badge
                        if (artist.acceptsCustomRequests.toLowerCase().contains('yes') ||
                            artist.workAvailability.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: boiMelaGreen.withValues(alpha: theme.isDark ? 0.35 : 0.09),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              artist.workAvailability.isNotEmpty
                                  ? 'Commission Open'
                                  : 'Custom Requests',
                              style: TextStyle(
                                color: theme.isDark ? theme.accentGold : deepTealInk,
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
                        ? const Color(0xFF15333B)
                        : const Color(0xFFE8F1F2),
                    border: Border.all(
                      color: boiMelaGreen.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.isDark ? Colors.white : deepTealInk,
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

/// Redesigned Cover Artist Card (Grid View) with Boi Mela Green Accent
class _CoverArtistGridCard extends StatelessWidget {
  const _CoverArtistGridCard({
    required this.artist,
    required this.theme,
    this.onTap,
  });

  final WriterProfile artist;
  final NovellyThemeData theme;
  final VoidCallback? onTap;

  static const Color boiMelaGreen = Color(0xFF1A454F);
  static const Color deepTealInk = Color(0xFF12343B);

  @override
  Widget build(BuildContext context) {
    final specialization = artist.designSpecialization.isNotEmpty
        ? artist.designSpecialization
        : (artist.about.isNotEmpty ? artist.about : 'Cover Artist');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
              color: boiMelaGreen.withValues(alpha: theme.isDark ? 0.45 : 0.2),
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
              _CoverArtistAvatar(
                artist: artist,
                theme: theme,
                compact: true,
              ),
              const SizedBox(height: 8),

              Text(
                artist.name,
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
                specialization,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.isDark
                      ? boiMelaGreen.withValues(alpha: 0.35)
                      : const Color(0xFFE8F1F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'View Portfolio',
                  style: TextStyle(
                    color: theme.isDark ? Colors.white : deepTealInk,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
