import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/bloco_event.dart';
import '../data/blocos_data.dart';
import 'carnival_scraper.dart';
import 'geocoding_service.dart';

class SyncManager extends ChangeNotifier {
  static const String _eventsBoxName = 'carnival_events';
  static const String _geocodeCacheBoxName = 'geocode_cache';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncIntervalKey = 'sync_interval_hours';
  static const int _defaultSyncIntervalHours = 24;

  // Cache static blocos data - computed once
  static List<BlocoEvent>? _cachedStaticBlocos;
  static List<BlocoEvent> get _staticBlocos =>
      _cachedStaticBlocos ??= BlocosData.getBlocos();

  Box<String>? _eventsBox;
  Box<String>? _geocodeCacheBox;
  SharedPreferences? _prefs;
  List<BlocoEvent> _events = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _lastError;
  DateTime? _lastSyncTime;
  SyncStatus _status = SyncStatus.idle;

  List<BlocoEvent> get events => _events;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  SyncStatus get status => _status;

  int get syncIntervalHours =>
      _prefs?.getInt(_syncIntervalKey) ?? _defaultSyncIntervalHours;

  bool get needsSync {
    if (_lastSyncTime == null) return true;
    final hoursSinceSync =
        DateTime.now().difference(_lastSyncTime!).inHours;
    return hoursSinceSync >= syncIntervalHours;
  }

  String get lastSyncFormatted {
    if (_lastSyncTime == null) return 'Nunca sincronizado';

    final now = DateTime.now();
    final diff = now.difference(_lastSyncTime!);

    if (diff.inMinutes < 1) return 'Agora mesmo';
    if (diff.inMinutes < 60) return 'Ha ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Ha ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ontem';
    return 'Ha ${diff.inDays} dias';
  }

  /// Initialize the sync manager
  Future<void> initialize() async {
    _isLoading = true;
    _status = SyncStatus.initializing;
    notifyListeners();

    try {
      // Initialize Hive
      await Hive.initFlutter();
      _eventsBox = await Hive.openBox<String>(_eventsBoxName);
      _geocodeCacheBox = await Hive.openBox<String>(_geocodeCacheBoxName);

      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Load last sync time
      final lastSyncTimestamp = _prefs?.getInt(_lastSyncKey);
      if (lastSyncTimestamp != null) {
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncTimestamp);
      }

      // Load cached events
      await _loadCachedEvents();

      // If no events or needs sync, try to sync
      if (_events.isEmpty || needsSync) {
        await syncEvents(showLoading: _events.isEmpty);
      }

      _status = SyncStatus.idle;
    } catch (e) {
      _lastError = 'Erro ao inicializar: $e';
      _status = SyncStatus.error;

      // Fall back to static data
      _events = List.from(_staticBlocos);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load events from local cache
  Future<void> _loadCachedEvents() async {
    if (_eventsBox == null || _eventsBox!.isEmpty) {
      // Use static data as fallback
      _events = List.from(_staticBlocos);
      return;
    }

    final List<BlocoEvent> loadedEvents = [];

    for (final key in _eventsBox!.keys) {
      try {
        final jsonStr = _eventsBox!.get(key);
        if (jsonStr != null) {
          final map = json.decode(jsonStr) as Map<String, dynamic>;
          loadedEvents.add(_eventFromJson(map));
        }
      } catch (e) {
        // Skip corrupted cache entries
      }
    }

    if (loadedEvents.isNotEmpty) {
      _events = loadedEvents;
      _events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } else {
      _events = List.from(_staticBlocos);
    }
  }

  /// Sync events from the internet
  Future<bool> syncEvents({bool showLoading = true, bool force = false}) async {
    if (_isSyncing) return false;

    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      _lastError = 'Sem conexao com a internet';
      _status = SyncStatus.offline;
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    if (showLoading) _isLoading = true;
    _status = SyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      // Fetch events from web
      final scrapedEvents = await CarnivalScraper.fetchAllEvents();

      // Merge with existing events
      final mergedEvents = _mergeEvents(scrapedEvents);

      if (mergedEvents.isNotEmpty) {
        // Geocode events that don't have coordinates
        final geocodedEvents = await _geocodeEventsWithoutCoordinates(mergedEvents);

        // Save to cache
        await _saveEventsToCache(geocodedEvents);

        _events = geocodedEvents;
        _events.sort((a, b) => a.dateTime.compareTo(b.dateTime));

        // Update last sync time
        _lastSyncTime = DateTime.now();
        await _prefs?.setInt(
            _lastSyncKey, _lastSyncTime!.millisecondsSinceEpoch);

        _status = SyncStatus.success;
        notifyListeners();
        return true;
      } else {
        // Keep existing events if scraping returned nothing
        _status = SyncStatus.idle;
        return false;
      }
    } catch (e) {
      _lastError = 'Erro ao sincronizar: $e';
      _status = SyncStatus.error;
      return false;
    } finally {
      _isSyncing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Merge scraped events with existing events (optimized single-pass merge)
  List<BlocoEvent> _mergeEvents(List<BlocoEvent> newEvents) {
    // Pre-size the map for better performance
    final eventMap = <String, BlocoEvent>{};

    // Add existing events first (they have the most up-to-date coordinates)
    for (final event in _events) {
      eventMap[event.id] = event;
    }

    // Add static events only if not already present (use cached static data)
    for (final event in _staticBlocos) {
      eventMap.putIfAbsent(event.id, () => event);
    }

    // Add/update with new events, preserving coordinates from existing
    for (final event in newEvents) {
      final existing = eventMap[event.id];
      if (existing != null &&
          existing.latitude != null &&
          existing.longitude != null &&
          event.latitude == null) {
        // Keep existing coordinates
        eventMap[event.id] = event.copyWith(
          latitude: existing.latitude,
          longitude: existing.longitude,
        );
      } else {
        eventMap[event.id] = event;
      }
    }

    return eventMap.values.toList();
  }

  /// Get cached geocode result
  ({double latitude, double longitude})? _getCachedGeocode(String address) {
    final cached = _geocodeCacheBox?.get(address);
    if (cached != null) {
      try {
        final parts = cached.split(',');
        if (parts.length == 2) {
          return (
            latitude: double.parse(parts[0]),
            longitude: double.parse(parts[1]),
          );
        }
      } catch (_) {
        // Invalid cache entry
      }
    }
    return null;
  }

  /// Cache geocode result
  Future<void> _cacheGeocode(String address, double lat, double lng) async {
    await _geocodeCacheBox?.put(address, '$lat,$lng');
  }

  /// Geocode events that don't have coordinates (with caching)
  Future<List<BlocoEvent>> _geocodeEventsWithoutCoordinates(
    List<BlocoEvent> events,
  ) async {
    final List<BlocoEvent> geocodedEvents = [];
    final List<BlocoEvent> eventsToGeocode = [];

    // Separate events that need geocoding
    for (final event in events) {
      if (event.latitude == null || event.longitude == null) {
        eventsToGeocode.add(event);
      } else {
        geocodedEvents.add(event);
      }
    }

    // Geocode events that need coordinates
    if (eventsToGeocode.isNotEmpty) {
      if (kDebugMode) {
        print('Geocoding ${eventsToGeocode.length} events...');
      }

      for (final event in eventsToGeocode) {
        try {
          // Build address string
          final addressString = event.address.contains('Belo Horizonte')
              ? event.address
              : '${event.address}, ${event.neighborhood}, Belo Horizonte, MG';

          // Check cache first
          var coordinates = _getCachedGeocode(addressString);

          if (coordinates == null) {
            // Not in cache, fetch from service
            coordinates = await GeocodingService.geocodeAddress(addressString);

            // Cache the result if successful
            if (coordinates != null) {
              await _cacheGeocode(
                addressString,
                coordinates.latitude,
                coordinates.longitude,
              );
            }

            // Small delay to avoid rate limiting (only for actual API calls)
            await Future.delayed(const Duration(milliseconds: 300));
          }

          if (coordinates != null) {
            geocodedEvents.add(
              event.copyWith(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude,
              ),
            );
          } else {
            // Keep event without coordinates if geocoding fails
            geocodedEvents.add(event);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error geocoding ${event.name}: $e');
          }
          // Keep event without coordinates on error
          geocodedEvents.add(event);
        }
      }
    }

    return geocodedEvents;
  }

  /// Save events to local cache
  Future<void> _saveEventsToCache(List<BlocoEvent> events) async {
    if (_eventsBox == null) return;

    await _eventsBox!.clear();

    for (final event in events) {
      final jsonStr = json.encode(_eventToJson(event));
      await _eventsBox!.put(event.id, jsonStr);
    }
  }

  /// Convert event to JSON
  Map<String, dynamic> _eventToJson(BlocoEvent event) {
    return {
      'id': event.id,
      'name': event.name,
      'dateTime': event.dateTime.toIso8601String(),
      'description': event.description,
      'address': event.address,
      'neighborhood': event.neighborhood,
      'ticketPrice': event.ticketPrice,
      'ticketUrl': event.ticketUrl,
      'latitude': event.latitude,
      'longitude': event.longitude,
      'imageUrl': event.imageUrl,
      'tags': event.tags,
    };
  }

  /// Convert JSON to event
  BlocoEvent _eventFromJson(Map<String, dynamic> json) {
    return BlocoEvent(
      id: json['id'] as String,
      name: json['name'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      description: json['description'] as String,
      address: json['address'] as String,
      neighborhood: json['neighborhood'] as String,
      ticketPrice: json['ticketPrice'] as String?,
      ticketUrl: json['ticketUrl'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      imageUrl: json['imageUrl'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }

  /// Set sync interval in hours
  Future<void> setSyncInterval(int hours) async {
    await _prefs?.setInt(_syncIntervalKey, hours);
    notifyListeners();
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _eventsBox?.clear();
    await _geocodeCacheBox?.clear();
    await _prefs?.remove(_lastSyncKey);
    _lastSyncTime = null;
    _events = List.from(_staticBlocos);
    notifyListeners();
  }

  /// Add a manual event
  Future<void> addManualEvent(BlocoEvent event) async {
    _events.add(event);
    _events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    await _saveEventsToCache(_events);
    notifyListeners();
  }

  /// Geocode all events that don't have coordinates
  /// This can be called manually to update coordinates for existing events
  Future<void> geocodeEventsWithoutCoordinates() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      final geocodedEvents = await _geocodeEventsWithoutCoordinates(_events);
      
      if (geocodedEvents.isNotEmpty) {
        await _saveEventsToCache(geocodedEvents);
        _events = geocodedEvents;
        _events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        _status = SyncStatus.success;
      }
    } catch (e) {
      _lastError = 'Erro ao geocodificar eventos: $e';
      _status = SyncStatus.error;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _eventsBox?.close();
    _geocodeCacheBox?.close();
    super.dispose();
  }
}

enum SyncStatus {
  idle,
  initializing,
  syncing,
  success,
  error,
  offline,
}

extension SyncStatusExtension on SyncStatus {
  String get message {
    switch (this) {
      case SyncStatus.idle:
        return 'Pronto';
      case SyncStatus.initializing:
        return 'Inicializando...';
      case SyncStatus.syncing:
        return 'Sincronizando...';
      case SyncStatus.success:
        return 'Sincronizado!';
      case SyncStatus.error:
        return 'Erro na sincronizacao';
      case SyncStatus.offline:
        return 'Sem conexao';
    }
  }

  bool get isLoading =>
      this == SyncStatus.initializing || this == SyncStatus.syncing;
}
