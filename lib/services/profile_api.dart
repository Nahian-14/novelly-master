import 'dart:convert';

import 'package:http/http.dart' as http;

class ProfileApiException implements Exception {
  const ProfileApiException(this.message, {this.statusCode});

  final String message;

  /// The HTTP status when the backend answered, so callers can tell
  /// "your account was rejected" (401/403/404) from "the server is down".
  final int? statusCode;

  @override
  String toString() => message;
}

class ProfileApi {
  ProfileApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL') {
    final uri = Uri.tryParse(_baseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        !const ['http', 'https'].contains(uri.scheme)) {
      throw StateError(
        'Set API_BASE_URL to the backend origin, for example '
        'http://10.0.2.2:3000.',
      );
    }
  }

  // Free hosting tiers can take ~30-60s to wake an idle backend.
  static const _requestTimeout = Duration(seconds: 45);

  final http.Client _client;
  final String _baseUrl;

  Uri get _profileUri => Uri.parse(_baseUrl).resolve('/api/profile');

  Future<Map<String, dynamic>> createProfile({
    required String idToken,
    required String name,
    required String role,
  }) async {
    final response = await _client
        .put(
          _profileUri,
          headers: _headers(idToken),
          body: jsonEncode({'name': name, 'role': role}),
        )
        .timeout(_requestTimeout);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> getProfile({required String idToken}) async {
    final response = await _client
        .get(_profileUri, headers: _headers(idToken))
        .timeout(_requestTimeout);
    return _decodeResponse(response);
  }

  Map<String, String> _headers(String idToken) => {
    'Authorization': 'Bearer $idToken',
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final Object? decodedBody;
    try {
      decodedBody = jsonDecode(response.body);
    } on FormatException {
      throw const ProfileApiException(
        'The backend returned an invalid response.',
      );
    }

    if (decodedBody is! Map<String, dynamic>) {
      throw const ProfileApiException(
        'The backend returned an invalid response.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decodedBody['error'];
      throw ProfileApiException(
        message is String ? message : 'Database request failed.',
        statusCode: response.statusCode,
      );
    }
    return decodedBody;
  }
}
