import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class BookApiException implements Exception {
  const BookApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A book as stored in the database.
class RemoteBook {
  const RemoteBook({
    required this.id,
    required this.title,
    required this.authorName,
    this.status = 'draft',
    this.creatorUid,
    this.imageUrl,
    this.imageBase64,
    this.description = '',
    this.pageCount,
    this.genre,
    this.isbn = '',
    this.publication = '',
    this.goodreadsLink = '',
    this.shelfCategory = '',
  });

  factory RemoteBook.fromJson(Map<String, dynamic> json) {
    String text(String key) => json[key] is String ? json[key] as String : '';
    return RemoteBook(
      id: text('id'),
      title: text('title'),
      authorName: text('authorName'),
      status: text('status').isEmpty ? 'published' : text('status'),
      creatorUid: json['creatorUid'] is String
          ? json['creatorUid'] as String
          : null,
      imageUrl: json['imageUrl'] is String && json['imageUrl']!.isNotEmpty
          ? json['imageUrl'] as String
          : null,
      imageBase64: json['imageBase64'] is String
          ? json['imageBase64'] as String
          : null,
      description: text('description'),
      pageCount: json['pageCount'] is int ? json['pageCount'] as int : null,
      genre: json['genre'] is String ? json['genre'] as String : null,
      isbn: text('isbn'),
      publication: text('publication'),
      goodreadsLink: text('goodreadsLink'),
      shelfCategory: text('shelfCategory'),
    );
  }

  final String id;
  final String title;
  final String authorName;
  final String status;
  final String? creatorUid;
  final String? imageUrl;
  final String? imageBase64;
  final String description;
  final int? pageCount;
  final String? genre;
  final String isbn;
  final String publication;
  final String goodreadsLink;
  final String shelfCategory;
}

class BookApi {
  BookApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL');

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) {
    final base = Uri.tryParse(_baseUrl);
    if (base == null || !base.hasAuthority) {
      throw const BookApiException(
        'API_BASE_URL is not set. Run Flutter with '
        '--dart-define=API_BASE_URL=http://10.0.2.2:3000',
      );
    }
    return base.resolve(path);
  }

  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const BookApiException('You are signed out. Please sign in again.');
    }
    final token = await user.getIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<List<RemoteBook>> fetchMyBooks() => _fetchList('/api/books/mine');

  Future<List<RemoteBook>> fetchAllBooks({String query = ''}) => _fetchList(
    '/api/books${query.trim().isEmpty ? '' : '?q=${Uri.encodeQueryComponent(query.trim())}'}',
  );

  Future<RemoteBook> fetchBook(String id) async {
    final response = await _client
        .get(
          _uri('/api/books/${Uri.encodeComponent(id)}'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));
    final body = _decode(response);
    if (body is! Map<String, dynamic>) {
      throw const BookApiException('The backend returned an invalid response.');
    }
    return RemoteBook.fromJson(body);
  }

  Future<RemoteBook> createBook({
    required String title,
    String description = '',
    int? pageCount,
    String? genre,
    String isbn = '',
    String publication = '',
    String goodreadsLink = '',
    String shelfCategory = '',
    String? imageBase64,
    String? imageContentType,
  }) async {
    final response = await _client
        .post(
          _uri('/api/books'),
          headers: await _headers(),
          body: jsonEncode({
            'title': title,
            'description': description,
            'pageCount': pageCount,
            'genre': genre,
            'isbn': isbn,
            'publication': publication,
            'goodreadsLink': goodreadsLink,
            'shelfCategory': shelfCategory,
            'imageBase64': ?imageBase64,
            'imageBase64ContentType': ?imageContentType,
          }),
        )
        .timeout(const Duration(seconds: 10));
    final body = _decode(response);
    if (body is! Map<String, dynamic>) {
      throw const BookApiException('The backend returned an invalid response.');
    }
    return RemoteBook.fromJson(body);
  }

  Future<RemoteBook> publishBook(String id) async {
    final response = await _client
        .patch(
          _uri('/api/books/${Uri.encodeComponent(id)}/publish'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));
    final body = _decode(response);
    if (body is! Map<String, dynamic>) {
      throw const BookApiException('The backend returned an invalid response.');
    }
    return RemoteBook.fromJson(body);
  }

  Future<List<RemoteBook>> _fetchList(String path) async {
    final response = await _client
        .get(_uri(path), headers: await _headers())
        .timeout(const Duration(seconds: 10));
    final body = _decode(response);
    if (body is! List) {
      throw const BookApiException('The backend returned an invalid response.');
    }
    return body
        .whereType<Map<String, dynamic>>()
        .map(RemoteBook.fromJson)
        .toList();
  }

  Object? _decode(http.Response response) {
    final Object? body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw BookApiException(
        'The backend returned an invalid response (HTTP ${response.statusCode}).',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map<String, dynamic> ? body['error'] : null;
      throw BookApiException(
        message is String
            ? message
            : 'Database request failed (HTTP ${response.statusCode}).',
      );
    }
    return body;
  }
}
