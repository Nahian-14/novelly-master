import 'package:flutter/foundation.dart';

class LocalSearchCacheManager {
  LocalSearchCacheManager._();

  static final LocalSearchCacheManager instance = LocalSearchCacheManager._();

  final List<String> _recentSearches = [
    'Humayun Ahmed',
    'Prothoma Prokashan',
    'Calligraphy Covers',
    'Misir Ali',
    'Boi Mela 2025',
  ];

  final Map<String, List<dynamic>> _queryCache = {};

  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  void addRecentSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _recentSearches.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > 10) {
      _recentSearches.removeLast();
    }
  }

  void clearRecentSearches() {
    _recentSearches.clear();
  }

  void cacheResults(String query, List<dynamic> results) {
    _queryCache[query.toLowerCase().trim()] = results;
  }

  List<dynamic>? getCachedResults(String query) {
    return _queryCache[query.toLowerCase().trim()];
  }
}
