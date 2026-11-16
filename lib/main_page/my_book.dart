import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/book_api.dart';
import '../widgets/image_provider_for_path.dart';
import '../theme/theme_controller.dart';
import 'book_detail.dart';
import 'novelly_bottom_navigation.dart';
import 'writer_profile.dart';

// Authentic Boi Mela green/teal accent matching #1a454f
const Color _boiMelaGreen = Color(0xFF1A454F);
const Color _deepTealInk = Color(0xFF12343B);

class MyBookScreen extends StatefulWidget {
  const MyBookScreen({super.key});

  @override
  State<MyBookScreen> createState() => _MyBookScreenState();
}

class _MyBookScreenState extends State<MyBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _search = TextEditingController();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _pages = TextEditingController();
  final _goodreads = TextEditingController();
  final _isbn = TextEditingController();
  final _publication = TextEditingController();
  final BookApi _bookApi = BookApi();
  final List<_MyBook> _books = [];
  String _query = '';
  String _selectedShelf = 'All';
  String? _genre;
  String? _imagePath;
  bool _adding = false;
  bool _isGridView = true;

  static const List<String> _shelves = [
    'All',
    'Currently Reading 📖',
    'Want to Read 🔖',
    'Completed ✅',
    'Cover Ideas 🎨',
  ];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  /// Loads this user's saved books from the database.
  Future<void> _loadBooks() async {
    try {
      final fetched = await _bookApi.fetchMyBooks();
      if (!mounted) return;
      setState(() {
        _books
          ..clear()
          ..addAll(fetched.map(_myBookFromRemote));
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load your books: $error')),
      );
    }
  }

  _MyBook _myBookFromRemote(RemoteBook book) => _MyBook(
    id: book.id,
    title: book.title,
    description: book.description,
    pageCount: book.pageCount,
    genre: book.genre,
    isbn: book.isbn,
    publication: book.publication,
    goodreadsLink: book.goodreadsLink,
    shelfCategory: book.shelfCategory.isEmpty
        ? 'Currently Reading 📖'
        : book.shelfCategory,
    status: book.status,
    imagePath: book.imageUrl,
    imageBytes: book.imageBase64 == null
        ? null
        : base64Decode(book.imageBase64!),
  );

  @override
  void dispose() {
    _search.dispose();
    _title.dispose();
    _description.dispose();
    _pages.dispose();
    _goodreads.dispose();
    _isbn.dispose();
    _publication.dispose();
    super.dispose();
  }

  List<_MyBook> get _visibleBooks {
    var filtered = _books
        .where(
          (book) => book.title.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    if (_selectedShelf != 'All') {
      filtered = filtered
          .where((b) => b.shelfCategory == _selectedShelf)
          .toList();
    }
    return filtered;
  }

  Future<void> _openBook(_MyBook book) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookDetailScreen(
          book: BookDetail(
            id: book.id,
            title: book.title,
            author: WriterProfileScreen.currentUser.name,
            rating: 0,
            pageCount: book.pageCount,
            genres: book.genre == null ? const [] : [book.genre!],
            description: book.description,
            coverImagePath: book.imagePath,
            coverImageBytes: book.imageBytes,
            isPublished: book.status == 'published',
            canPublish: book.id != null,
            reviews: const [],
            isbn: book.isbn,
            publication: book.publication,
            goodreadsLink: book.goodreadsLink,
          ),
        ),
      ),
    );
    if (mounted) _loadBooks();
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;
    final imageFile = _imagePath == null ? null : XFile(_imagePath!);
    final imageBytes = imageFile == null ? null : await imageFile.readAsBytes();
    final book = _MyBook(
      title: _title.text.trim(),
      description: _description.text.trim(),
      pageCount: int.tryParse(_pages.text.trim()),
      genre: _genre,
      isbn: _isbn.text.trim(),
      publication: _publication.text.trim(),
      goodreadsLink: _goodreads.text.trim(),
      imagePath: _imagePath,
      imageBytes: imageBytes,
      shelfCategory: _selectedShelf == 'All'
          ? 'Currently Reading 📖'
          : _selectedShelf,
    );
    try {
      final saved = await _bookApi.createBook(
        title: book.title,
        description: book.description,
        pageCount: book.pageCount,
        genre: book.genre,
        isbn: book.isbn,
        publication: book.publication,
        goodreadsLink: book.goodreadsLink,
        shelfCategory: book.shelfCategory,
        imageBase64: imageBytes == null ? null : base64Encode(imageBytes),
        imageContentType: imageFile?.mimeType ?? 'image/jpeg',
      );
      final persistedBook = _myBookFromRemote(saved);
      if (!mounted) return;
      setState(() {
        _books.insert(0, persistedBook);
        _adding = false;
        _search.clear();
        _query = '';
        _title.clear();
        _description.clear();
        _pages.clear();
        _goodreads.clear();
        _isbn.clear();
        _publication.clear();
        _genre = null;
        _imagePath = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the book: $error')),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Book saved as a private draft.')),
    );
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null && mounted) setState(() => _imagePath = image.path);
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
                  final compact = constraints.maxWidth < 600;
                  final horizontalPadding = (constraints.maxWidth * 0.05).clamp(
                    compact ? 16.0 : 20.0,
                    38.0,
                  );
                  return Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            8,
                            horizontalPadding,
                            0,
                          ),
                          child: _adding
                              ? _addBookForm(compact, theme)
                              : _bookList(compact, theme),
                        ),
                      ),
                      if (!_adding)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            compact ? 7 : 10,
                            horizontalPadding,
                            compact ? 8 : 10,
                          ),
                          child: _bottomNavigation(compact),
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

  Widget _header(bool compact, NovellyThemeData theme) => Row(
    children: [
      if (_adding) ...[
        IconButton(
          tooltip: 'Back',
          onPressed: () => setState(() => _adding = false),
          style: IconButton.styleFrom(
            backgroundColor: theme.isDark
                ? const Color(0xFF15333B)
                : const Color(0xFFE8F1F2),
            foregroundColor: theme.isDark ? Colors.white : _deepTealInk,
          ),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.isDark ? Colors.white : _deepTealInk,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
      ],
      Text(
        'My Book',
        style: TextStyle(
          color: theme.isDark ? Colors.white : _deepTealInk,
          fontFamily: 'Georgia',
          fontSize: compact ? 24 : 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      const Spacer(),
      if (!_adding)
        IconButton(
          tooltip: _isGridView ? 'Switch to list view' : 'Switch to grid view',
          onPressed: () => setState(() => _isGridView = !_isGridView),
          icon: Container(
            width: 36,
            height: 36,
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
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: theme.isDark ? theme.accentGold : _boiMelaGreen,
              size: 20,
            ),
          ),
        ),
    ],
  );

  Widget _bottomNavigation(bool compact) => NovellyBottomNavigation(
    libraryLabel: WriterProfileScreen.currentUser.isPublisher
        ? 'My Publishing'
        : 'My Book',
    selectedDestination: NovellyNavigationDestination.library,
    compact: compact,
    onDestinationSelected: (destination) {
      handleNovellyNavigation(
        context: context,
        currentDestination: NovellyNavigationDestination.library,
        targetDestination: destination,
      );
    },
  );

  Widget _bookList(bool compact, NovellyThemeData theme) => Column(
    children: [
      _header(compact, theme),
      const SizedBox(height: 12),
      _searchField(compact, theme),
      const SizedBox(height: 12),
      _shelvesFilterChips(theme),
      const SizedBox(height: 16),
      _shelfHeaderRow(compact, theme),
      const SizedBox(height: 12),
      Expanded(
        child: _books.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 48,
                      color: theme.mutedColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No books yet. Add a book to get started.',
                      style: TextStyle(color: theme.mutedColor, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : _visibleBooks.isEmpty
            ? Center(
                child: Text(
                  'No books found',
                  style: TextStyle(color: theme.mutedColor),
                  textAlign: TextAlign.center,
                ),
              )
            : _isGridView
            ? GridView.builder(
                itemCount: _visibleBooks.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: compact ? 3 : 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: compact ? 0.72 : 0.78,
                ),
                itemBuilder: (context, index) =>
                    _gridBookCard(_visibleBooks[index], theme, compact),
              )
            : ListView.separated(
                itemCount: _visibleBooks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _listBookCard(_visibleBooks[index], theme, compact),
              ),
      ),
      const SizedBox(height: 8),
      _bookCollectionCounter(theme),
    ],
  );

  Widget _searchField(bool compact, NovellyThemeData theme) {
    return Container(
      height: compact ? 48 : 56,
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
        controller: _search,
        onChanged: (value) => setState(() => _query = value),
        style: TextStyle(
          color: theme.isDark ? Colors.white : _deepTealInk,
          fontSize: compact ? 15 : 17,
        ),
        decoration: InputDecoration(
          hintText: 'Search your books...',
          hintStyle: TextStyle(
            color: theme.mutedColor.withValues(alpha: 0.8),
            fontSize: compact ? 14 : 16,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.isDark ? theme.accentGold : _boiMelaGreen,
            size: compact ? 22 : 25,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: compact ? 12 : 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _shelvesFilterChips(NovellyThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _shelves.map((shelf) {
          final selected = _selectedShelf == shelf;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedShelf = shelf),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
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
                  shelf,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : (theme.isDark
                              ? const Color(0xFFD2E3E8)
                              : _deepTealInk),
                    fontSize: 12,
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

  Widget _shelfHeaderRow(bool compact, NovellyThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Personal Bookshelf',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.isDark ? Colors.white : _deepTealInk,
                    fontFamily: 'Georgia',
                    fontSize: compact ? 17 : 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: theme.isDark
                      ? _boiMelaGreen.withValues(alpha: 0.35)
                      : const Color(0xFFE8F1F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.isDark
                        ? _boiMelaGreen.withValues(alpha: 0.5)
                        : _boiMelaGreen.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${_visibleBooks.length}',
                  style: TextStyle(
                    color: theme.isDark ? theme.accentGold : _boiMelaGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => setState(() => _adding = true),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Book'),
          style: FilledButton.styleFrom(
            backgroundColor: _boiMelaGreen,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 8 : 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _coverTilePlaceholder() {
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
          const Center(
            child: Icon(
              Icons.menu_book_rounded,
              color: Color(0xFFE5AE4D),
              size: 32,
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
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

  Widget _gridBookCard(
    _MyBook book,
    NovellyThemeData theme,
    bool compact,
  ) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _openBook(book),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.isDark
              ? const Color(0xFF11262B)
              : const Color(0xFFFAFBFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _boiMelaGreen.withValues(alpha: theme.isDark ? 0.45 : 0.2),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : _boiMelaGreen.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6,
              child: book.imageBytes != null || book.imagePath != null
                  ? Image(
                      image: book.imageBytes != null
                          ? MemoryImage(book.imageBytes!)
                          : imageProviderForPath(book.imagePath!),
                      fit: BoxFit.cover,
                    )
                  : _coverTilePlaceholder(),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.isDark ? Colors.white : _deepTealInk,
                        fontFamily: 'Georgia',
                        fontSize: compact ? 12 : 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (book.genre != null && book.genre!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.isDark
                              ? _boiMelaGreen.withValues(alpha: 0.35)
                              : const Color(0xFFE8F1F2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          book.genre!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.isDark ? Colors.white : _deepTealInk,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _listBookCard(
    _MyBook book,
    NovellyThemeData theme,
    bool compact,
  ) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _openBook(book),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.isDark
              ? const Color(0xFF11262B)
              : const Color(0xFFFAFBFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.isDark
                ? _boiMelaGreen.withValues(alpha: 0.5)
                : _boiMelaGreen.withValues(alpha: 0.2),
            width: 1.2,
          ),
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
        child: Row(
          children: [
            Container(
              width: 58,
              height: 78,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _boiMelaGreen.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: book.imageBytes != null || book.imagePath != null
                  ? Image(
                      image: book.imageBytes != null
                          ? MemoryImage(book.imageBytes!)
                          : imageProviderForPath(book.imagePath!),
                      fit: BoxFit.cover,
                    )
                  : _coverTilePlaceholder(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.isDark ? Colors.white : _deepTealInk,
                      fontSize: compact ? 15.5 : 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (book.publication.isNotEmpty)
                    Text(
                      book.publication,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.mutedColor, fontSize: 12),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (book.genre != null && book.genre!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
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
                            book.genre!,
                            style: TextStyle(
                              color: theme.isDark ? Colors.white : _deepTealInk,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.isDark
                              ? _boiMelaGreen.withValues(alpha: 0.2)
                              : const Color(0xFFF0F5F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          book.shelfCategory,
                          style: TextStyle(
                            color: theme.isDark
                                ? theme.accentGold
                                : _boiMelaGreen,
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
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Container(
                width: 32,
                height: 32,
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
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _bookCollectionCounter(NovellyThemeData theme) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Flexible(
        child: Divider(
          color: theme.isDark
              ? _boiMelaGreen.withValues(alpha: 0.4)
              : _boiMelaGreen.withValues(alpha: 0.25),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_rounded, size: 15, color: theme.accentGold),
            const SizedBox(width: 6),
            Text(
              '${_books.length} Books',
              style: TextStyle(
                color: theme.isDark ? theme.accentGold : _boiMelaGreen,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
      Flexible(
        child: Divider(
          color: theme.isDark
              ? _boiMelaGreen.withValues(alpha: 0.4)
              : _boiMelaGreen.withValues(alpha: 0.25),
        ),
      ),
    ],
  );

  Widget _addBookForm(bool compact, NovellyThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _header(compact, theme),
      const SizedBox(height: 10),
      Text(
        'Add a New Book',
        style: TextStyle(
          color: theme.isDark ? Colors.white : _deepTealInk,
          fontFamily: 'Georgia',
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 14),
      Expanded(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _formField(
                          Icons.menu_book_rounded,
                          'Title',
                          'Enter book title',
                          _title,
                          theme,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter a book title'
                              : null,
                        ),
                        _formField(
                          Icons.description_outlined,
                          'Description',
                          'Write description',
                          _description,
                          theme,
                          lines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  _imagePicker(compact, theme),
                ],
              ),
              _formField(
                Icons.sell_outlined,
                'Genre',
                'Select genre',
                null,
                theme,
              ),
              _formField(
                Icons.auto_stories_outlined,
                'Page',
                'Enter number of pages',
                _pages,
                theme,
                keyboard: TextInputType.number,
              ),
              _formField(
                Icons.link_rounded,
                'Goodreads Link',
                'Paste goodreads link',
                _goodreads,
                theme,
              ),
              _formField(
                Icons.tag_rounded,
                'ISBN Number',
                'Enter ISBN number',
                _isbn,
                theme,
              ),
              _formField(
                Icons.apartment_rounded,
                'Publication',
                'Enter publication name',
                _publication,
                theme,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _saveBook,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Add Book'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _boiMelaGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _imagePicker(bool compact, NovellyThemeData theme) => InkWell(
    onTap: _pickImage,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: compact ? 84 : 100,
      height: 114,
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF11262B) : const Color(0xFFFAFBFB),
        border: Border.all(
          color: _boiMelaGreen.withValues(alpha: 0.5),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(12),
        image: _imagePath == null
            ? null
            : DecorationImage(
                image: imageProviderForPath(_imagePath!),
                fit: BoxFit.cover,
              ),
      ),
      child: _imagePath == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: theme.accentGold,
                  size: 26,
                ),
                const SizedBox(height: 6),
                Text(
                  'Add Image',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.accentGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : null,
    ),
  );

  Widget _formField(
    IconData icon,
    String label,
    String hint,
    TextEditingController? controller,
    NovellyThemeData theme, {
    int lines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(right: 11),
          decoration: BoxDecoration(
            color: theme.isDark
                ? const Color(0xFF15333B)
                : const Color(0xFFE8F1F2),
            shape: BoxShape.circle,
            border: Border.all(
              color: _boiMelaGreen.withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: theme.isDark ? theme.accentGold : _boiMelaGreen,
          ),
        ),
        Expanded(
          child: label == 'Genre'
              ? DropdownButtonFormField<String>(
                  initialValue: _genre,
                  decoration: _fieldDecoration(label, hint, theme),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: theme.isDark ? Colors.white70 : _deepTealInk,
                  ),
                  dropdownColor: theme.isDark
                      ? const Color(0xFF11262B)
                      : const Color(0xFFFAFBFB),
                  items:
                      const [
                            'Fantasy',
                            'Fiction',
                            'Mystery',
                            'Romance',
                            'Science Fiction',
                            'Non-fiction',
                          ]
                          .map(
                            (genre) => DropdownMenuItem(
                              value: genre,
                              child: Text(
                                genre,
                                style: TextStyle(
                                  color: theme.isDark
                                      ? Colors.white
                                      : _deepTealInk,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _genre = value),
                )
              : TextFormField(
                  controller: controller,
                  validator: validator,
                  keyboardType: keyboard,
                  maxLines: lines,
                  style: TextStyle(
                    color: theme.isDark ? Colors.white : _deepTealInk,
                  ),
                  decoration: _fieldDecoration(label, hint, theme),
                ),
        ),
      ],
    ),
  );

  InputDecoration _fieldDecoration(
    String label,
    String hint,
    NovellyThemeData theme,
  ) => InputDecoration(
    labelText: label,
    hintText: hint,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    filled: true,
    fillColor: theme.isDark ? const Color(0xFF11262B) : const Color(0xFFFAFBFB),
    labelStyle: TextStyle(
      color: theme.isDark ? Colors.white : _deepTealInk,
      fontFamily: 'Georgia',
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: TextStyle(
      color: theme.mutedColor.withValues(alpha: 0.75),
      fontSize: 13,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.isDark
            ? _boiMelaGreen.withValues(alpha: 0.5)
            : _boiMelaGreen.withValues(alpha: 0.22),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: theme.isDark
            ? _boiMelaGreen.withValues(alpha: 0.5)
            : _boiMelaGreen.withValues(alpha: 0.22),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _boiMelaGreen, width: 1.5),
    ),
  );
}

class _MyBook {
  const _MyBook({
    this.id,
    required this.title,
    this.description = '',
    this.pageCount,
    this.genre,
    this.isbn = '',
    this.publication = '',
    this.goodreadsLink = '',
    this.imagePath,
    this.imageBytes,
    this.shelfCategory = 'Currently Reading 📖',
    this.status = 'draft',
  });

  final String? id;
  final String title;
  final String description;
  final int? pageCount;
  final String? genre;
  final String isbn;
  final String publication;
  final String goodreadsLink;
  final String? imagePath;
  final Uint8List? imageBytes;
  final String shelfCategory;
  final String status;
}
