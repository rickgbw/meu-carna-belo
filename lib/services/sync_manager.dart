import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/bloco_event.dart';
import '../data/blocos_data.dart';
import 'carnival_scraper.dart';

class SyncManager extends ChangeNotifier {
  static const String _eventsBoxName = 'carnival_events';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncIntervalKey = 'sync_interval_hours';
  static const int _defaultSyncIntervalHours = 24;

  Box<String>? _eventsBox;
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
      _events = BlocosData.getBlocos();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load events from local cache
  Future<void> _loadCachedEvents() async {
    if (_eventsBox == null || _eventsBox!.isEmpty) {
      // Use static data as fallback
      _events = BlocosData.getBlocos();
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
      _events = BlocosData.getBlocos();
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
        // Save to cache
        await _saveEventsToCache(mergedEvents);

        _events = mergedEvents;
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

  /// Merge scraped events with existing events
  List<BlocoEvent> _mergeEvents(List<BlocoEvent> newEvents) {
    final Map<String, BlocoEvent> eventMap = {};

    // Add existing events
    for (final event in _events) {
      eventMap[event.id] = event;
    }

    // Add static events as fallback
    for (final event in BlocosData.getBlocos()) {
      if (!eventMap.containsKey(event.id)) {
        eventMap[event.id] = event;
      }
    }

    // Add/update with new events
    for (final event in newEvents) {
      eventMap[event.id] = event;
    }

    return eventMap.values.toList();
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
    await _prefs?.remove(_lastSyncKey);
    _lastSyncTime = null;
    _events = BlocosData.getBlocos();
    notifyListeners();
  }

  /// Add a manual event
  Future<void> addManualEvent(BlocoEvent event) async {
    _events.add(event);
    _events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    await _saveEventsToCache(_events);
    notifyListeners();
  }

  @override
  void dispose() {
    _eventsBox?.close();
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
