class DiscoverBook {
  const DiscoverBook({
    required this.title,
    required this.author,
    required this.rating,
    required this.genre,
    this.id,
    this.description = '',
    this.pageCount,
    this.isbn,
    this.publication,
    this.goodreadsLink,
    this.imageUrl,
    this.creatorUid,
  });

  final String? id;
  final String title;
  final String author;
  final String rating;
  final String genre;
  final String description;
  final int? pageCount;
  final String? isbn;
  final String? publication;
  final String? goodreadsLink;
  final String? imageUrl;
  final String? creatorUid;
}
