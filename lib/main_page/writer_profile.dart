import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../logout_confirmation.dart';
import '../Splash,login,register/login.dart';
import '../auth/auth_service.dart';
import '../chat/direct_chat.dart';
import '../publisher/publisher_profile.dart';
import '../theme/theme_controller.dart';
import 'novelly_bottom_navigation.dart';

const _paper = Color(0xFFF4F0E7);
const _line = Color(0xFFDDD5C7);

// Authentic Boi Mela green/teal accent matching #1a454f
const Color _boiMelaGreen = Color(0xFF1A454F);
const Color _deepTealInk = Color(0xFF12343B);

@immutable
class WriterProfile {
  const WriterProfile({
    required this.name,
    this.accountId = '',
    this.goodreads = '',
    this.facebook = '',
    this.instagram = '',
    this.website = '',
    this.about = '',
    this.profileImagePath,
    this.designSpecialization = '',
    this.artStyle = '',
    this.servicesOffered = '',
    this.yearsOfExperience = '',
    this.designTools = '',
    this.workAvailability = '',
    this.acceptsCustomRequests = '',
    this.pricingPackages = '',
    this.averageDeliveryTime = '',
    this.revisionPolicy = '',
    this.isWriter = false,
    this.isPublisher = false,
    this.isCoverArtist = false,
    this.books = const [],
    this.followerIds = const [],
    this.publishers = const [],
  });

  final String name;
  final String accountId;
  final String goodreads;
  final String facebook;
  final String instagram;
  final String website;
  final String about;
  final String? profileImagePath;
  final String designSpecialization;
  final String artStyle;
  final String servicesOffered;
  final String yearsOfExperience;
  final String designTools;
  final String workAvailability;
  final String acceptsCustomRequests;
  final String pricingPackages;
  final String averageDeliveryTime;
  final String revisionPolicy;
  final bool isWriter;
  final bool isPublisher;
  final bool isCoverArtist;
  final List<WriterBook> books;
  final List<String> followerIds;
  final List<String> publishers;

  WriterProfile copyWith({List<WriterBook>? books}) => WriterProfile(
    name: name,
    accountId: accountId,
    goodreads: goodreads,
    facebook: facebook,
    instagram: instagram,
    website: website,
    about: about,
    profileImagePath: profileImagePath,
    designSpecialization: designSpecialization,
    artStyle: artStyle,
    servicesOffered: servicesOffered,
    yearsOfExperience: yearsOfExperience,
    designTools: designTools,
    workAvailability: workAvailability,
    acceptsCustomRequests: acceptsCustomRequests,
    pricingPackages: pricingPackages,
    averageDeliveryTime: averageDeliveryTime,
    revisionPolicy: revisionPolicy,
    isWriter: isWriter,
    isPublisher: isPublisher,
    isCoverArtist: isCoverArtist,
    books: books ?? this.books,
    followerIds: followerIds,
    publishers: publishers,
  );

  int get publishedBookCount => books.length;
  int get reviewCount =>
      books.fold(0, (total, book) => total + book.reviews.length);
  int get followerCount => followerIds.length;
  double get rating => books.isEmpty
      ? 0
      : books.fold(0.0, (total, book) => total + book.rating) / books.length;
}

@immutable
class WriterBook {
  const WriterBook({
    required this.title,
    this.rating = 0.0,
    this.reviews = const [],
  });

  final String title;
  final double rating;
  final List<WriterBookReview> reviews;
}

@immutable
class WriterBookReview {
  const WriterBookReview({
    required this.reviewerName,
    required this.rating,
    required this.body,
  });

  final String reviewerName;
  final double rating;
  final String body;
}

class _ProfileEditResult {
  const _ProfileEditResult(this.profile, this.avatarPath);

  final WriterProfile profile;
  final String? avatarPath;
}

class WriterProfileScreen extends StatefulWidget {
  static WriterProfile currentUser = const WriterProfile(name: 'Your profile');
  static String? currentAvatarPath;

  const WriterProfileScreen({
    super.key,
    this.profile,
    this.isCurrentUser = false,
  });

  final WriterProfile? profile;
  final bool isCurrentUser;

  @override
  State<WriterProfileScreen> createState() => _WriterProfileScreenState();
}

class _WriterProfileScreenState extends State<WriterProfileScreen> {
  late WriterProfile _profile = widget.isCurrentUser
      ? WriterProfileScreen.currentUser
      : (widget.profile ?? const WriterProfile(name: 'Author'));
  String? _avatarPath;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.isCurrentUser) {
      _avatarPath = WriterProfileScreen.currentAvatarPath;
    }
  }

  Future<void> _editProfile() async {
    final result = await showDialog<_ProfileEditResult>(
      context: context,
      builder: (_) =>
          _ProfileEditDialog(profile: _profile, avatarPath: _avatarPath),
    );
    if (result == null || !mounted) return;

    setState(() {
      _profile = result.profile;
      _avatarPath = result.avatarPath;
    });
    if (widget.isCurrentUser) WriterProfileScreen.currentUser = _profile;
    if (widget.isCurrentUser) {
      WriterProfileScreen.currentAvatarPath = _avatarPath;
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showLogoutConfirmationDialog(context);
    if (shouldLogout != true || !mounted) return;

    await AuthService().signOut();
    WriterProfileScreen.currentUser = const WriterProfile(name: 'Your profile');
    WriterProfileScreen.currentAvatarPath = null;
    PublisherProfileScreen.currentUser = null;
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openSettingsSheet(NovellyThemeData theme) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _ProfileSettingsSheet(
        onEditProfile: () {
          Navigator.pop(sheetContext);
          _editProfile();
        },
        onLogout: () {
          Navigator.pop(sheetContext);
          _confirmLogout();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editable = widget.isCurrentUser;
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
                  final pad = (constraints.maxWidth * .045).clamp(14.0, 26.0);
                  final compact = constraints.maxWidth < 600;
                  final horizontalPadding = (constraints.maxWidth * 0.05).clamp(
                    compact ? 16.0 : 20.0,
                    38.0,
                  );
                  final account = WriterProfileScreen.currentUser;
                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(pad, 6, pad, 20),
                          children: [
                            // Compact Header Bar
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Back',
                                  onPressed: () => Navigator.maybePop(context),
                                  icon: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: theme.isDark ? Colors.white : _deepTealInk,
                                    size: 20,
                                  ),
                                ),
                                Text(
                                  'Author Profile',
                                  style: TextStyle(
                                    color: theme.isDark ? Colors.white : _deepTealInk,
                                    fontFamily: 'Georgia',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const Spacer(),
                                if (editable)
                                  IconButton(
                                    tooltip: 'Settings',
                                    onPressed: () => _openSettingsSheet(theme),
                                    icon: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: theme.isDark
                                            ? const Color(0xFF15333B)
                                            : const Color(0xFFE8F1F2),
                                        border: Border.all(
                                          color: _boiMelaGreen.withValues(alpha: 0.35),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.settings_outlined,
                                        color: theme.isDark ? Colors.white : _deepTealInk,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Space-Efficient Hero Profile Card
                            _profileCard(editable, theme, compact),
                            const SizedBox(height: 14),

                            // About Card
                            if (_profile.about.isNotEmpty) ...[
                              _aboutCard(theme),
                              const SizedBox(height: 14),
                            ],

                            // Books Showcase Card
                            if (_profile.books.isNotEmpty) ...[
                              _booksCard(theme),
                              const SizedBox(height: 14),
                            ],

                            // Worked with Publishers Card
                            if (_profile.publishers.isNotEmpty) ...[
                              _publishersCard(theme),
                            ],
                          ],
                        ),
                      ),
                      if (widget.isCurrentUser)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            compact ? 7 : 10,
                            horizontalPadding,
                            compact ? 8 : 10,
                          ),
                          child: NovellyBottomNavigation(
                            libraryLabel: account.isCoverArtist
                                ? 'My Designs'
                                : account.isPublisher
                                    ? 'My Publishing'
                                    : 'My Book',
                            libraryIcon: account.isCoverArtist
                                ? Icons.palette_outlined
                                : Icons.menu_book_outlined,
                            selectedDestination:
                                NovellyNavigationDestination.profile,
                            compact: compact,
                            onDestinationSelected: (destination) {
                              handleNovellyNavigation(
                                context: context,
                                currentDestination:
                                    NovellyNavigationDestination.profile,
                                targetDestination: destination,
                              );
                            },
                          ),
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

  /// Compact Hero Profile Card with balanced green accent & white/mint ratio
  Widget _profileCard(bool editable, NovellyThemeData theme, bool compact) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(theme),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Avatar with Boi Mela Green Accent Gradient Ring
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_boiMelaGreen, _deepTealInk],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _boiMelaGreen.withValues(alpha: theme.isDark ? 0.35 : 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: compact ? 36 : 42,
                backgroundColor: theme.isDark ? const Color(0xFF11262B) : const Color(0xFFF0F5F6),
                backgroundImage: _avatarPath == null
                    ? null
                    : FileImage(File(_avatarPath!)),
                child: _avatarPath == null
                    ? Icon(Icons.person, color: theme.isDark ? theme.accentGold : _boiMelaGreen, size: 38)
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Profile Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.isDark ? Colors.white : _deepTealInk,
                            fontFamily: 'Georgia',
                            fontSize: compact ? 19 : 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (_profile.isWriter)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.isDark
                                ? _boiMelaGreen.withValues(alpha: 0.35)
                                : const Color(0xFFE8F1F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.isDark
                                  ? _boiMelaGreen.withValues(alpha: 0.6)
                                  : _boiMelaGreen.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'Writer',
                            style: TextStyle(
                              color: theme.isDark ? Colors.white : _deepTealInk,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Author of ${_profile.publishedBookCount} books',
                    style: TextStyle(
                      color: theme.mutedColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Compact Rating Row
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Icon(
                          _profile.rating >= i
                              ? Icons.star
                              : _profile.rating >= i - .5
                              ? Icons.star_half
                              : Icons.star_border,
                          color: const Color(0xFFE5AE4D),
                          size: 16,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        _profile.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: theme.inkColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Social Links
                  if (_profile.goodreads.isNotEmpty ||
                      _profile.facebook.isNotEmpty ||
                      _profile.instagram.isNotEmpty ||
                      _profile.website.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (_profile.goodreads.isNotEmpty)
                          _socialLink(
                            _profile.goodreads,
                            _profile.goodreads,
                            Icons.auto_stories_outlined,
                            theme,
                          ),
                        if (_profile.facebook.isNotEmpty)
                          _socialLink(
                            'Facebook',
                            _profile.facebook,
                            Icons.facebook,
                            theme,
                          ),
                        if (_profile.instagram.isNotEmpty)
                          _socialLink(
                            'Instagram',
                            _profile.instagram,
                            Icons.camera_alt_outlined,
                            theme,
                          ),
                        if (_profile.website.isNotEmpty)
                          _socialLink(
                            'Website',
                            _profile.website,
                            Icons.language_rounded,
                            theme,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Space-Efficient Dashboard Stats Strip
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: theme.isDark ? const Color(0xFF15333B) : const Color(0xFFE8F1F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.isDark
                  ? _boiMelaGreen.withValues(alpha: 0.5)
                  : _boiMelaGreen.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              _stat(
                'Published books',
                '${_profile.publishedBookCount}',
                Icons.menu_book_outlined,
                theme,
              ),
              Container(
                width: 1,
                height: 28,
                color: theme.isDark
                    ? _boiMelaGreen.withValues(alpha: 0.4)
                    : _boiMelaGreen.withValues(alpha: 0.25),
              ),
              _stat(
                'Reviews',
                '${_profile.reviewCount}',
                Icons.star_border_rounded,
                theme,
              ),
              Container(
                width: 1,
                height: 28,
                color: theme.isDark
                    ? _boiMelaGreen.withValues(alpha: 0.4)
                    : _boiMelaGreen.withValues(alpha: 0.25),
              ),
              _stat(
                'Followers',
                _formatCount(_profile.followerCount),
                Icons.people_outline_rounded,
                theme,
              ),
            ],
          ),
        ),

        // Action Buttons Row for non-editable profile (Message button)
        if (!editable) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: FilledButton.icon(
              onPressed: () => openDirectChat(
                context,
                userId: _profile.accountId,
                userName: _profile.name,
                avatarPath: _avatarPath ?? _profile.profileImagePath,
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Message'),
              style: FilledButton.styleFrom(
                backgroundColor: _boiMelaGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _stat(
    String label,
    String value,
    IconData icon,
    NovellyThemeData theme,
  ) =>
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: theme.isDark ? theme.accentGold : _boiMelaGreen, size: 15),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: theme.isDark ? Colors.white : _deepTealInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.mutedColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _aboutCard(NovellyThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_edu_rounded, color: theme.isDark ? theme.accentGold : _boiMelaGreen, size: 18),
              const SizedBox(width: 6),
              _sectionTitle('About the Author', theme, fontSize: 15),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _profile.about,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? null : TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: theme.isDark ? Colors.white70 : theme.inkColor,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 16,
                color: theme.isDark ? theme.accentGold : _boiMelaGreen,
              ),
              label: Text(
                _expanded ? 'Read less' : 'Read more',
                style: TextStyle(
                  color: theme.isDark ? theme.accentGold : _boiMelaGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _booksCard(NovellyThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: theme.isDark ? theme.accentGold : _boiMelaGreen, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: _sectionTitle('Books by ${_profile.name}', theme, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth > 650 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _profile.books.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.3,
                ),
                itemBuilder: (context, index) => _bookTile(_profile.books[index], theme),
              );
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All books are shown here.')),
              ),
              icon: Icon(Icons.chevron_right_rounded, color: theme.isDark ? theme.accentGold : _boiMelaGreen, size: 18),
              label: Text(
                'View all books (${_profile.publishedBookCount})',
                style: TextStyle(
                  color: theme.isDark ? Colors.white : _deepTealInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _publishersCard(NovellyThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.apartment_rounded, color: theme.isDark ? theme.accentGold : _boiMelaGreen, size: 18),
              const SizedBox(width: 6),
              _sectionTitle('Worked with', theme, fontSize: 15),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _profile.publishers.map((p) => _publisher(p, theme)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, NovellyThemeData theme, {double fontSize = 18}) =>
      Text(
        title,
        style: TextStyle(
          color: theme.isDark ? Colors.white : _deepTealInk,
          fontFamily: 'Georgia',
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
      );

  Widget _bookTile(WriterBook book, NovellyThemeData theme) => Container(
        decoration: BoxDecoration(
          color: theme.isDark
              ? _boiMelaGreen.withValues(alpha: 0.35)
              : const Color(0xFFE8F1F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.isDark
                ? _boiMelaGreen.withValues(alpha: 0.6)
                : _boiMelaGreen.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(
              width: 36,
              color: _boiMelaGreen,
              child: const Center(
                child: Icon(Icons.menu_book_rounded, color: Color(0xFFE5AE4D), size: 18),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.isDark ? Colors.white : _deepTealInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${book.rating.toStringAsFixed(1)} ★',
                      style: const TextStyle(
                        color: Color(0xFFE5AE4D),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _publisher(String name, NovellyThemeData theme) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: theme.isDark
              ? _boiMelaGreen.withValues(alpha: 0.35)
              : const Color(0xFFE8F1F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.isDark
                ? _boiMelaGreen.withValues(alpha: 0.6)
                : _boiMelaGreen.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _boiMelaGreen,
              ),
              child: const Icon(Icons.apartment_rounded, size: 11, color: Colors.white),
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 11.5,
                color: theme.isDark ? Colors.white : _deepTealInk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _socialLink(
    String label,
    String value,
    IconData icon,
    NovellyThemeData theme,
  ) =>
      Tooltip(
        message: value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: theme.isDark ? theme.accentGold : _boiMelaGreen),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: theme.isDark ? Colors.white : _deepTealInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  String _formatCount(int count) => count >= 1000
      ? '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K'
      : '$count';

  BoxDecoration _cardDecoration(NovellyThemeData theme) => BoxDecoration(
        color: theme.isDark ? const Color(0xFF11262B) : const Color(0xFFFAFBFB),
        border: Border.all(
          color: theme.isDark
              ? _boiMelaGreen.withValues(alpha: 0.5)
              : _boiMelaGreen.withValues(alpha: 0.2),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : _boiMelaGreen.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      );
}

class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({required this.profile, required this.avatarPath});

  final WriterProfile profile;
  final String? avatarPath;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  String? _avatarPath;
  late final _name = TextEditingController(text: widget.profile.name);
  late final _goodreads = TextEditingController(text: widget.profile.goodreads);
  late final _facebook = TextEditingController(text: widget.profile.facebook);
  late final _instagram = TextEditingController(text: widget.profile.instagram);
  late final _website = TextEditingController(text: widget.profile.website);
  late final _about = TextEditingController(text: widget.profile.about);
  late final _publishers = TextEditingController(
    text: widget.profile.publishers.join(', '),
  );

  @override
  void initState() {
    super.initState();
    _avatarPath = widget.avatarPath;
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null && mounted) setState(() => _avatarPath = image.path);
  }

  @override
  void dispose() {
    _name.dispose();
    _goodreads.dispose();
    _facebook.dispose();
    _instagram.dispose();
    _website.dispose();
    _about.dispose();
    _publishers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: _paper,
    insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 14, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_boiMelaGreen, _deepTealInk],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Edit profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _boiMelaGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: _boiMelaGreen,
                          backgroundImage: _avatarPath == null
                              ? null
                              : FileImage(File(_avatarPath!)),
                          child: _avatarPath == null
                              ? const Icon(Icons.person, color: Colors.white, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Profile photo',
                            style: TextStyle(
                              color: _deepTealInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickAvatar,
                          icon: const Icon(Icons.photo_library_outlined, size: 16),
                          label: const Text('Change'),
                          style: TextButton.styleFrom(foregroundColor: _boiMelaGreen),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _field('Display name', _name, Icons.badge_outlined),
                  const SizedBox(height: 12),
                  _field('Goodreads link', _goodreads, Icons.link_rounded),
                  const SizedBox(height: 12),
                  _field('Facebook link', _facebook, Icons.facebook),
                  const SizedBox(height: 12),
                  _field(
                    'Instagram link',
                    _instagram,
                    Icons.camera_alt_outlined,
                  ),
                  const SizedBox(height: 12),
                  _field('Website link', _website, Icons.language_rounded),
                  const SizedBox(height: 12),
                  _field(
                    'About the author',
                    _about,
                    Icons.edit_note_rounded,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    'Worked with',
                    _publishers,
                    Icons.apartment_rounded,
                    helperText: 'Separate publisher names with commas.',
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _deepTealInk,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: _line),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(
                      context,
                      _ProfileEditResult(
                        WriterProfile(
                          name: _name.text.trim().isEmpty
                              ? widget.profile.name
                              : _name.text.trim(),
                          accountId: widget.profile.accountId,
                          goodreads: _goodreads.text.trim(),
                          facebook: _facebook.text.trim(),
                          instagram: _instagram.text.trim(),
                          website: _website.text.trim(),
                          about: _about.text.trim(),
                          profileImagePath: _avatarPath,
                          designSpecialization:
                              widget.profile.designSpecialization,
                          artStyle: widget.profile.artStyle,
                          servicesOffered: widget.profile.servicesOffered,
                          yearsOfExperience: widget.profile.yearsOfExperience,
                          designTools: widget.profile.designTools,
                          workAvailability: widget.profile.workAvailability,
                          acceptsCustomRequests:
                              widget.profile.acceptsCustomRequests,
                          pricingPackages: widget.profile.pricingPackages,
                          averageDeliveryTime:
                              widget.profile.averageDeliveryTime,
                          revisionPolicy: widget.profile.revisionPolicy,
                          isWriter: widget.profile.isWriter,
                          isPublisher: widget.profile.isPublisher,
                          isCoverArtist: widget.profile.isCoverArtist,
                          books: widget.profile.books,
                          followerIds: widget.profile.followerIds,
                          publishers: _publishers.text
                              .split(',')
                              .map((name) => name.trim())
                              .where((name) => name.isNotEmpty)
                              .toList(),
                        ),
                        _avatarPath,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _boiMelaGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    String? helperText,
  }) => TextField(
    controller: controller,
    maxLines: maxLines,
    minLines: maxLines == 1 ? 1 : 3,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Icon(icon, color: _boiMelaGreen, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: .75),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _boiMelaGreen, width: 1.5),
      ),
    ),
  );
}

class _ProfileSettingsSheet extends StatelessWidget {
  const _ProfileSettingsSheet({
    required this.onEditProfile,
    required this.onLogout,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NovellyThemeData>(
      valueListenable: NovellyThemeController.instance,
      builder: (context, theme, _) {
        final isDark = theme.isDark;
        final cardBg = isDark ? const Color(0xFF15333B) : const Color(0xFFF0F5F6);
        final borderColor = isDark
            ? _boiMelaGreen.withValues(alpha: 0.5)
            : _boiMelaGreen.withValues(alpha: 0.2);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF11262B) : const Color(0xFFFAFBFB),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.paddingOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cardBg,
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      color: isDark ? theme.accentGold : _boiMelaGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: isDark ? Colors.white : _deepTealInk,
                      fontFamily: 'Georgia',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : _deepTealInk,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Appearance / Theme Section
              _sectionHeader('APPEARANCE', theme),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1D3B42) : Colors.white,
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: isDark ? theme.accentGold : _boiMelaGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dark Mode',
                            style: TextStyle(
                              color: isDark ? Colors.white : _deepTealInk,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            isDark ? 'Boi Mela Dark theme' : 'Paper Cream Light theme',
                            style: TextStyle(
                              color: theme.mutedColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: isDark,
                      activeThumbColor: theme.accentGold,
                      activeTrackColor: _boiMelaGreen,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade400,
                      onChanged: (val) {
                        NovellyThemeController.instance.setTheme(
                          val ? NovellyThemeMode.midnightInk : NovellyThemeMode.paperCream,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Account & Profile Section
              _sectionHeader('ACCOUNT & PROFILE', theme),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onEditProfile,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF1D3B42) : Colors.white,
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              color: isDark ? theme.accentGold : _boiMelaGreen,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : _deepTealInk,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Name, photo, biography & links',
                                  style: TextStyle(
                                    color: theme.mutedColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white54 : _deepTealInk.withValues(alpha: 0.5),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Session & Security Section
              _sectionHeader('SESSION', theme),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onLogout,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF381E1E)
                                  : const Color(0xFFFFEBEE),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFE53935),
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Tooltip(
                                  message: 'Log out',
                                  child: Text(
                                    'Log out',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFFFF8A80)
                                          : const Color(0xFFD32F2F),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Sign out of your account on this device',
                                  style: TextStyle(
                                    color: theme.mutedColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white54 : _deepTealInk.withValues(alpha: 0.5),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, NovellyThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: theme.mutedColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
