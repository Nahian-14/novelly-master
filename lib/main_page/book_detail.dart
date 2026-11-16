import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../reader/sample_reader.dart';
import '../services/book_api.dart';
import '../services/content_api.dart';
import '../theme/theme_controller.dart';
import 'writer_profile.dart';
import '../widgets/image_provider_for_path.dart';

const Color _boiMelaGreen = Color(0xFF1A454F);
const Color _deepTealInk = Color(0xFF12343B);
const Color _gold = Color(0xFFE5AE4D);

@immutable
class BookDetail {
  const BookDetail({
    required this.title,
    required this.author,
    required this.rating,
    this.id,
    this.creatorUid,
    this.isPublished = false,
    this.canPublish = false,
    this.reviewCount,
    this.pageCount,
    required this.genres,
    this.description = '',
    this.externalRating,
    this.coverImagePath,
    this.coverImageBytes,
    this.isbn,
    this.publication,
    this.goodreadsLink,
    required this.reviews,
  });

  final String title;
  final String author;
  final double rating;
  final String? id;
  final String? creatorUid;
  final bool isPublished;
  final bool canPublish;
  final int? reviewCount;
  final int? pageCount;
  final List<String> genres;
  final String description;
  final double? externalRating;
  final String? coverImagePath;
  final Uint8List? coverImageBytes;
  final String? isbn;
  final String? publication;
  final String? goodreadsLink;
  final List<BookReview> reviews;
}

@immutable
class BookReview {
  const BookReview({
    required this.reviewerName,
    required this.rating,
    required this.createdAt,
    required this.body,
  });

  final String reviewerName;
  final double rating;
  final DateTime createdAt;
  final String body;
}

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({required this.book, super.key});

  final BookDetail book;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _descriptionExpanded = false;
  bool _sortByRating = false;
  bool _publishing = false;
  late bool _isPublished;

  @override
  void initState() {
    super.initState();
    _isPublished = widget.book.isPublished;
  }

  Future<void> _publishBook() async {
    final id = widget.book.id;
    if (id == null || _publishing || _isPublished) return;
    setState(() => _publishing = true);
    try {
      await BookApi().publishBook(id);
      if (!mounted) return;
      setState(() => _isPublished = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book published and visible to everyone.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish the book: $error')),
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _openAuthorProfile() async {
    final uid = widget.book.creatorUid;
    late final WriterProfile profile;
    if (uid == null || uid.isEmpty) {
      profile = WriterProfile(
        name: widget.book.author,
        books: [
          WriterBook(
            title: widget.book.title,
            rating: widget.book.rating,
            reviews: widget.book.reviews
                .map(
                  (review) => WriterBookReview(
                    reviewerName: review.reviewerName,
                    rating: review.rating,
                    body: review.body,
                  ),
                )
                .toList(),
          ),
        ],
        publishers: const [],
        about: 'More information about ${widget.book.author}.',
      );
    } else {
      try {
        final result = await ContentApi().get(
          '/api/profiles/${Uri.encodeComponent(uid)}',
        );
        if (result is! Map<String, dynamic>) {
          throw const ContentApiException(
            'The backend returned an invalid writer profile.',
          );
        }
        profile = WriterProfile.fromJson(result);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load writer information: $error')),
        );
        return;
      }
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WriterProfileScreen(profile: profile),
      ),
    );
  }

  List<BookReview> get _sortedReviews {
    final reviews = [...widget.book.reviews];
    if (_sortByRating) {
      reviews.sort((a, b) => b.rating.compareTo(a.rating));
    } else {
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return reviews;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NovellyThemeData>(
      valueListenable: NovellyThemeController.instance,
      builder: (context, theme, _) {
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
                  final horizontalPadding = (constraints.maxWidth * 0.045)
                      .clamp(16.0, 26.0);
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      6,
                      horizontalPadding,
                      20,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildBackButton(theme),
                            const SizedBox(height: 10),
                            _buildBookHeader(constraints.maxWidth, theme),
                            if (widget.book.canPublish && !_isPublished)
                              _buildPublishButton(),
                            const SizedBox(height: 12),
                            _buildGenreTags(theme),
                            const SizedBox(height: 12),
                            _buildReadSampleButton(),
                            const SizedBox(height: 16),
                            _buildSectionHeading('Book Description', theme),
                            const SizedBox(height: 8),
                            _buildDescription(theme),
                            if (_bookInformation.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              _buildSectionHeading('Book Information', theme),
                              const SizedBox(height: 8),
                              _buildBookInformation(theme),
                            ],
                            if (widget.book.externalRating != null) ...[
                              const SizedBox(height: 12),
                              _buildExternalRating(theme),
                            ],
                            const SizedBox(height: 16),
                            _buildReviewsHeading(theme),
                            const SizedBox(height: 10),
                            ..._sortedReviews.map(
                              (review) => Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: _ReviewCard(
                                  review: review,
                                  theme: theme,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton(NovellyThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).maybePop(),
        style: IconButton.styleFrom(
          backgroundColor: theme.isDark
              ? const Color(0xFF15333B)
              : const Color(0xFFE9E4D8),
          foregroundColor: theme.isDark ? Colors.white : _deepTealInk,
          fixedSize: const Size(38, 38),
          padding: EdgeInsets.zero,
        ),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 17,
          color: theme.isDark ? Colors.white : _deepTealInk,
        ),
      ),
    );
  }

  Widget _buildReadSampleButton() {
    return SizedBox(
      height: 42,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SampleReaderScreen(
                title: widget.book.title,
                author: widget.book.author,
                sampleContent: widget.book.description,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _boiMelaGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1.5,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: const Icon(Icons.auto_stories_rounded, color: _gold, size: 18),
        label: const Text(
          'Read Sample Chapter 📖',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPublishButton() => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SizedBox(
      height: 42,
      child: FilledButton.icon(
        onPressed: _publishing ? null : _publishBook,
        icon: _publishing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.public),
        label: Text(_publishing ? 'Publishing...' : 'Publish this book'),
      ),
    ),
  );

  Widget _buildBookHeader(double availableWidth, NovellyThemeData theme) {
    final compact = availableWidth <= 420;
    final coverWidth = (availableWidth * 0.25).clamp(88.0, 118.0);
    final coverHeight = coverWidth * 1.38;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BookCover(
          width: coverWidth,
          height: coverHeight,
          imagePath: widget.book.coverImagePath,
          imageBytes: widget.book.coverImageBytes,
        ),
        SizedBox(width: compact ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.isDark ? Colors.white : _deepTealInk,
                  fontFamily: 'Georgia',
                  fontSize: compact ? 22 : 26,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              InkWell(
                onTap: _openAuthorProfile,
                child: Text(
                  'by ${widget.book.author}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.isDark ? theme.accentGold : _boiMelaGreen,
                    fontSize: compact ? 14 : 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _RatingStars(
                    rating: widget.book.rating,
                    size: compact ? 16 : 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.book.rating.toStringAsFixed(1),
                    style: TextStyle(
                      color: theme.isDark ? Colors.white : _deepTealInk,
                      fontSize: compact ? 13.5 : 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (widget.book.reviewCount != null ||
                  widget.book.pageCount != null) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if (widget.book.reviewCount != null)
                      '${widget.book.reviewCount} reviews',
                    if (widget.book.pageCount != null)
                      '${widget.book.pageCount} pages',
                  ].join('   |   '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.mutedColor,
                    fontSize: compact ? 11.5 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenreTags(NovellyThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: widget.book.genres
          .map(
            (genre) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4.5,
              ),
              decoration: BoxDecoration(
                color: theme.isDark
                    ? _boiMelaGreen.withValues(alpha: 0.35)
                    : const Color(0xFFE8F1F2),
                border: Border.all(
                  color: theme.isDark
                      ? _boiMelaGreen.withValues(alpha: 0.6)
                      : _boiMelaGreen.withValues(alpha: 0.25),
                  width: 0.8,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                genre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.isDark ? Colors.white : _deepTealInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSectionHeading(String title, NovellyThemeData theme) {
    final compact = MediaQuery.sizeOf(context).width <= 420;
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: theme.isDark
                ? _boiMelaGreen.withValues(alpha: 0.4)
                : _boiMelaGreen.withValues(alpha: 0.22),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.isDark ? Colors.white : _deepTealInk,
              fontFamily: 'Georgia',
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: theme.isDark
                ? _boiMelaGreen.withValues(alpha: 0.4)
                : _boiMelaGreen.withValues(alpha: 0.22),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(NovellyThemeData theme) {
    return Column(
      children: [
        Text(
          widget.book.description.isEmpty
              ? 'Description coming soon.'
              : widget.book.description,
          maxLines: _descriptionExpanded ? null : 3,
          overflow: _descriptionExpanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.isDark ? Colors.white70 : const Color(0xFF55595C),
            fontSize: 14,
            height: 1.45,
          ),
        ),
        SizedBox(
          height: 28,
          child: IconButton(
            tooltip: _descriptionExpanded
                ? 'Show less'
                : 'Read full description',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            onPressed: () =>
                setState(() => _descriptionExpanded = !_descriptionExpanded),
            icon: Icon(
              _descriptionExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: theme.isDark ? theme.accentGold : _boiMelaGreen,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  List<MapEntry<String, String>> get _bookInformation => [
    if (widget.book.publication?.trim().isNotEmpty ?? false)
      MapEntry('Publication', widget.book.publication!.trim()),
    if (widget.book.isbn?.trim().isNotEmpty ?? false)
      MapEntry('ISBN', widget.book.isbn!.trim()),
    if (widget.book.goodreadsLink?.trim().isNotEmpty ?? false)
      MapEntry('Goodreads', widget.book.goodreadsLink!.trim()),
  ];

  Widget _buildBookInformation(NovellyThemeData theme) {
    return Column(
      children: [
        for (final entry in _bookInformation)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 95,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: theme.isDark ? Colors.white : _deepTealInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: theme.isDark
                          ? Colors.white70
                          : const Color(0xFF55595C),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildExternalRating(NovellyThemeData theme) {
    final externalRating = widget.book.externalRating!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF11262B) : const Color(0xFFFAFBFB),
        border: Border.all(
          color: theme.isDark
              ? _boiMelaGreen.withValues(alpha: 0.5)
              : _boiMelaGreen.withValues(alpha: 0.22),
          width: 1.1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goodreads Review',
                  style: TextStyle(
                    color: theme.isDark ? Colors.white : _deepTealInk,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                _RatingStars(rating: externalRating, size: 17),
              ],
            ),
          ),
          Text(
            externalRating.toStringAsFixed(1),
            style: TextStyle(
              color: theme.isDark ? Colors.white : _deepTealInk,
              fontFamily: 'Georgia',
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.isDark ? Colors.white70 : _deepTealInk,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsHeading(NovellyThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Reviews (${widget.book.reviewCount ?? widget.book.reviews.length})',
            style: TextStyle(
              color: theme.isDark ? Colors.white : _deepTealInk,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        PopupMenuButton<bool>(
          initialValue: _sortByRating,
          onSelected: (sortByRating) =>
              setState(() => _sortByRating = sortByRating),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: theme.isDark ? const Color(0xFF11262B) : Colors.white,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: false,
              child: Text(
                'Most Recent',
                style: TextStyle(
                  color: theme.isDark ? Colors.white : _deepTealInk,
                  fontSize: 13,
                ),
              ),
            ),
            PopupMenuItem(
              value: true,
              child: Text(
                'Highest Rated',
                style: TextStyle(
                  color: theme.isDark ? Colors.white : _deepTealInk,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.isDark
                  ? const Color(0xFF11262B)
                  : const Color(0xFFFAFBFB),
              border: Border.all(
                color: theme.isDark
                    ? _boiMelaGreen.withValues(alpha: 0.5)
                    : _boiMelaGreen.withValues(alpha: 0.22),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _sortByRating ? 'Highest Rated' : 'Most Recent',
                  style: TextStyle(
                    color: theme.isDark ? Colors.white : _deepTealInk,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 17,
                  color: theme.isDark ? Colors.white70 : _deepTealInk,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({
    required this.width,
    required this.height,
    this.imagePath,
    this.imageBytes,
  });

  final double width;
  final double height;
  final String? imagePath;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        imageBytes != null ||
        (imagePath != null && imagePath!.trim().isNotEmpty);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF153A40), Color(0xFF0D292E)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _boiMelaGreen.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image(
              image: imageBytes != null
                  ? MemoryImage(imageBytes!)
                  : imageProviderForPath(imagePath!),
              fit: BoxFit.cover,
              width: width,
              height: height,
              errorBuilder: (context, error, stackTrace) => _fallbackCover(),
            )
          : _fallbackCover(),
    );
  }

  Widget _fallbackCover() {
    return Center(
      child: Icon(Icons.menu_book_rounded, color: _gold, size: width * 0.45),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.theme});

  final BookReview review;
  final NovellyThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF11262B) : const Color(0xFFFAFBFB),
        border: Border.all(
          color: theme.isDark
              ? _boiMelaGreen.withValues(alpha: 0.45)
              : _boiMelaGreen.withValues(alpha: 0.2),
          width: 1.1,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? Colors.black.withValues(alpha: 0.2)
                : _boiMelaGreen.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: theme.isDark
                ? const Color(0xFF15333B)
                : const Color(0xFFE8F1F2),
            child: Icon(
              Icons.person,
              color: theme.isDark ? theme.accentGold : _boiMelaGreen,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.reviewerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.isDark ? Colors.white : _deepTealInk,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _relativeDate(review.createdAt),
                      style: TextStyle(color: theme.mutedColor, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _RatingStars(rating: review.rating, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: theme.mutedColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  review.body,
                  style: TextStyle(
                    color: theme.isDark
                        ? Colors.white70
                        : const Color(0xFF55595C),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relativeDate(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return '1 day ago';
    if (days < 7) return '$days days ago';
    if (days < 14) return '1 week ago';
    if (days < 30) return '${days ~/ 7} weeks ago';
    if (days < 365) return '${days ~/ 30} months ago';
    return '${days ~/ 365} years ago';
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating, required this.size});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final difference = rating - index;
        final icon = difference >= 0.75
            ? Icons.star_rounded
            : difference >= 0.25
            ? Icons.star_half_rounded
            : Icons.star_outline_rounded;
        return Icon(icon, color: _gold, size: size);
      }),
    );
  }
}
