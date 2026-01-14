import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService extends ChangeNotifier {
  static const String _favoritesKey = 'favorite_blocos';

  SharedPreferences? _prefs;
  Set<String> _favoriteIds = {};
  bool _isSaving = false;

  Set<String> get favoriteIds => _favoriteIds;

  /// Initialize the favorites service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFavorites();
  }

  void _loadFavorites() {
    final favorites = _prefs?.getStringList(_favoritesKey) ?? [];
    _favoriteIds = favorites.toSet();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    // Prevent concurrent saves
    if (_isSaving) return;
    _isSaving = true;
    try {
      await _prefs?.setStringList(_favoritesKey, _favoriteIds.toList());
    } finally {
      _isSaving = false;
    }
  }

  /// Check if an event is favorited
  bool isFavorite(String eventId) {
    return _favoriteIds.contains(eventId);
  }

  /// Toggle favorite status for an event
  Future<void> toggleFavorite(String eventId) async {
    if (_favoriteIds.contains(eventId)) {
      _favoriteIds.remove(eventId);
    } else {
      _favoriteIds.add(eventId);
    }
    // Notify immediately for responsive UI
    notifyListeners();
    // Save in background (non-blocking)
    _saveFavorites();
  }

  /// Add an event to favorites
  Future<void> addFavorite(String eventId) async {
    if (!_favoriteIds.contains(eventId)) {
      _favoriteIds.add(eventId);
      notifyListeners();
      _saveFavorites();
    }
  }

  /// Remove an event from favorites
  Future<void> removeFavorite(String eventId) async {
    if (_favoriteIds.contains(eventId)) {
      _favoriteIds.remove(eventId);
      notifyListeners();
      _saveFavorites();
    }
  }

  /// Get the count of favorites
  int get favoritesCount => _favoriteIds.length;
}
