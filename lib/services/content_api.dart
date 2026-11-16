import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ContentApiException implements Exception {
  const ContentApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ContentApi {
  ContentApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL');

  final http.Client _client;
  final String _baseUrl;

  Uri uri(String path) {
    final base = Uri.tryParse(_baseUrl);
    if (base == null || !base.hasAuthority) {
      throw const ContentApiException(
        'API_BASE_URL is not set. Start Flutter with '
        '--dart-define=API_BASE_URL=http://10.0.2.2:3000',
      );
    }
    return base.resolve(path);
  }

  String absoluteUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final value = Uri.tryParse(path);
    return value?.hasAuthority == true ? path : uri(path).toString();
  }

  Future<Map<String, dynamic>> imagePayload(String field, String? path) async {
    if (path == null ||
        path.isEmpty ||
        Uri.tryParse(path)?.hasAuthority == true) {
      return {};
    }
    final image = XFile(path);
    final mimeType = image.mimeType ?? 'image/jpeg';
    return {
      field: base64Encode(await image.readAsBytes()),
      '${field}ContentType': mimeType,
    };
  }

  Future<Object?> get(String path) => request('GET', path);

  Future<Object?> post(String path, Map<String, dynamic> body) =>
      request('POST', path, body: body);

  Future<Object?> put(String path, Map<String, dynamic> body) =>
      request('PUT', path, body: body);

  Future<Object?> patch(String path, [Map<String, dynamic>? body]) =>
      request('PATCH', path, body: body);

  Future<void> delete(String path) async {
    final response = await _client
        .delete(uri(path), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwResponse(response);
    }
  }

  Future<Object?> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = this.uri(path);
    final headers = await _headers();
    final encodedBody = body == null ? null : jsonEncode(body);
    final response = switch (method) {
      'GET' => await _client.get(uri, headers: headers),
      'POST' => await _client.post(uri, headers: headers, body: encodedBody),
      'PUT' => await _client.put(uri, headers: headers, body: encodedBody),
      'PATCH' => await _client.patch(uri, headers: headers, body: encodedBody),
      _ => throw ArgumentError.value(method, 'method', 'Unsupported method'),
    };
    return _decode(response);
  }

  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ContentApiException(
        'You are signed out. Please sign in again.',
      );
    }
    final token = await user.getIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Object? _decode(http.Response response) {
    final Object? body;
    try {
      body = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      throw ContentApiException(
        'The backend returned an invalid response (HTTP ${response.statusCode}).',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwResponse(response, decodedBody: body);
    }
    return body;
  }

  Never _throwResponse(http.Response response, {Object? decodedBody}) {
    Object? body = decodedBody;
    if (body == null && response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } on FormatException {
        body = null;
      }
    }
    final message = body is Map<String, dynamic> ? body['error'] : null;
    throw ContentApiException(
      message is String
          ? message
          : 'Database request failed (HTTP ${response.statusCode}).',
    );
  }
}
