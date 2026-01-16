import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/bloco_event.dart';
import '../services/favorites_service.dart';
import '../services/location_service.dart';
import '../services/sync_manager.dart';
import '../theme/carnival_theme.dart';
import '../widgets/event_card.dart';
import '../widgets/filter_drawer.dart';
import '../widgets/sync_modal.dart';
import 'event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SyncManager _syncManager = SyncManager();
  final FavoritesService _favoritesService = FavoritesService();
  List<BlocoEvent> _filteredEvents = [];
  String _searchQuery = '';
  String _selectedFilter = 'Todos';
  late AnimationController _animationController;

  Position? _currentPosition;
  // Cache all distances once when location changes, not on every filter
  Map<String, String> _allEventDistances = {};
  Map<String, String> _eventDistances = {};

  // Debounce timer for search
  Timer? _searchDebounce;

  final List<String> _filters = ['Todos', 'Hoje', 'Favoritos'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _syncManager.addListener(_onSyncUpdate);
    _favoritesService.addListener(_onFavoritesUpdate);
    _initializeData();
    _getCurrentLocation();
  }

  Future<void> _initializeData() async {
    await _favoritesService.initialize();
    await _syncManager.initialize();
    _filterEvents();
    _animationController.forward();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null && mounted) {
        _currentPosition = position;
        _calculateAllDistances();
        _updateFilteredDistances();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location: $e');
      }
    }
  }

  /// Calculate distances for ALL events once when location changes
  /// This is cached and reused when filtering
  void _calculateAllDistances() {
    if (_currentPosition == null) return;

    final distances = <String, String>{};
    for (final event in _syncManager.events) {
      if (event.latitude != null && event.longitude != null) {
        final distance = LocationService.calculateDistance(
          event.latitude,
          event.longitude,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        if (distance != null) {
          distances[event.id] = LocationService.formatDistance(distance);
        }
      }
    }
    _allEventDistances = distances;
  }

  /// Update distances for filtered events from cache (O(n) lookup, no calculation)
  void _updateFilteredDistances() {
    final distances = <String, String>{};
    for (final event in _filteredEvents) {
      final cached = _allEventDistances[event.id];
      if (cached != null) {
        distances[event.id] = cached;
      }
    }
    setState(() {
      _eventDistances = distances;
    });
  }

  void _onSyncUpdate() {
    if (mounted) {
      _filterEvents();
    }
  }

  void _onFavoritesUpdate() {
    if (mounted) {
      _filterEvents();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _syncManager.removeListener(_onSyncUpdate);
    _favoritesService.removeListener(_onFavoritesUpdate);
    _syncManager.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _filterEvents() {
    final now = DateTime.now();
    final searchLower = _searchQuery.toLowerCase();
    final filterLower = _selectedFilter.toLowerCase();

    // Filter and sort in a single pass where possible
    final filtered = <BlocoEvent>[];
    for (final event in _syncManager.events) {
      // Search matching
      final matchesSearch =
          searchLower.isEmpty ||
          event.name.toLowerCase().contains(searchLower) ||
          event.neighborhood.toLowerCase().contains(searchLower) ||
          event.description.toLowerCase().contains(searchLower);

      if (!matchesSearch) continue;

      // Filter matching
      bool matchesFilter;
      switch (_selectedFilter) {
        case 'Todos':
          matchesFilter = true;
          break;
        case 'Hoje':
          matchesFilter =
              event.dateTime.year == now.year &&
              event.dateTime.month == now.month &&
              event.dateTime.day == now.day;
          break;
        case 'Favoritos':
          matchesFilter = _favoritesService.isFavorite(event.id);
          break;
        case 'Gratuito':
          matchesFilter = event.ticketPrice?.contains('Gratuita') == true;
          break;
        default:
          matchesFilter = event.tags.any(
            (tag) => tag.toLowerCase() == filterLower,
          );
      }

      if (matchesFilter) {
        filtered.add(event);
      }
    }

    // Sort: upcoming events first (soonest first), then past events (most recent first)
    filtered.sort((a, b) {
      final aIsPast = a.dateTime.isBefore(now);
      final bIsPast = b.dateTime.isBefore(now);

      if (aIsPast && !bIsPast) {
        return 1; // a is past, b is upcoming -> b first
      }
      if (!aIsPast && bIsPast) {
        return -1; // a is upcoming, b is past -> a first
      }
      if (!aIsPast && !bIsPast) {
        // Both upcoming: soonest first
        return a.dateTime.compareTo(b.dateTime);
      }
      // Both past: most recent first
      return b.dateTime.compareTo(a.dateTime);
    });

    setState(() {
      _filteredEvents = filtered;
    });

    // Update distances from cache (no recalculation)
    if (_currentPosition != null) {
      _updateFilteredDistances();
    }
  }

  Future<void> _refreshData() async {
    await _syncManager.syncEvents(force: true);
    _calculateAllDistances(); // Recalculate distances for new events
    _animationController.reset();
    _animationController.forward();
    await _getCurrentLocation();
  }

  /// Debounced search handler to avoid filtering on every keystroke
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = value;
      _filterEvents();
    });
  }

  void _showSyncInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSyncInfoSheet(),
    );
  }

  Widget _buildSyncInfoSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: CarnivalTheme.backgroundGradient,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.sync, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sincronizacao Automatica',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: CarnivalTheme.deepPurple,
                        ),
                      ),
                      Text(
                        'Atualiza a cada ${_syncManager.syncIntervalHours}h',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              Icons.access_time,
              'Ultima sincronizacao',
              _syncManager.lastSyncFormatted,
            ),
            _buildInfoRow(
              Icons.event,
              'Total de blocos',
              '${_syncManager.events.length} eventos',
            ),
            _buildInfoRow(
              Icons.cloud_download,
              'Status',
              _syncManager.status.message,
            ),
            if (_syncManager.lastError != null)
              _buildInfoRow(
                Icons.error_outline,
                'Erro',
                _syncManager.lastError!,
                isError: true,
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _syncManager.clearCache();
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Limpar Cache'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _syncManager.isSyncing
                        ? null
                        : () async {
                            await _refreshData();
                            if (mounted) Navigator.pop(context);
                          },
                    icon: _syncManager.isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(
                      _syncManager.isSyncing ? 'Sincronizando...' : 'Sincronizar',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CarnivalTheme.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isError = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isError ? Colors.red : CarnivalTheme.purple,
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : CarnivalTheme.deepPurple,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  bool get _showSyncModal {
    return _syncManager.status == SyncStatus.initializing ||
        _syncManager.isSyncing;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: FilterDrawer(
        searchQuery: _searchQuery,
        selectedFilter: _selectedFilter,
        filters: _filters,
        onSearchChanged: _onSearchChanged,
        onFilterSelected: (filter) {
          _selectedFilter = filter;
          _filterEvents();
        },
      ),
      body: Stack(
        children: [
          // Main content
          Container(
            decoration: const BoxDecoration(
              gradient: CarnivalTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _scaffoldKey.currentState?.openDrawer();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.tune,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image(
                                    image: AssetImage(
                                      'assets/icon/ic_foreground.png',
                                    ),
                                    width: 40,
                                    height: 40,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Meu Carna BH',
                                    style: GoogleFonts.pacifico(
                                      fontSize: 28,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(2, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Sync status row
                        GestureDetector(
                          onTap: _showSyncInfo,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_syncManager.isSyncing)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  Icon(
                                    _syncManager.status == SyncStatus.error
                                        ? Icons.error_outline
                                        : _syncManager.status ==
                                              SyncStatus.offline
                                        ? Icons.cloud_off
                                        : Icons.cloud_done,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                const SizedBox(width: 6),
                                Text(
                                  _syncManager.isSyncing
                                      ? 'Sincronizando...'
                                      : _syncManager.lastSyncFormatted,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Events list
                  Expanded(
                    child: _syncManager.isLoading && _filteredEvents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Carregando blocos...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _filteredEvents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '😢',
                                  style: TextStyle(fontSize: 60),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhum bloco encontrado',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tente outra busca',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshData,
                            color: CarnivalTheme.purple,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount: _filteredEvents.length,
                              itemBuilder: (context, index) {
                                final event = _filteredEvents[index];
                                return SlideTransition(
                                  position:
                                      Tween<Offset>(
                                        begin: const Offset(1, 0),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _animationController,
                                          curve: Interval(
                                            (index / _filteredEvents.length) *
                                                0.5,
                                            ((index + 1) /
                                                        _filteredEvents
                                                            .length) *
                                                    0.5 +
                                                0.5,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                      ),
                                  child: EventCard(
                                    event: event,
                                    distanceText: _eventDistances[event.id],
                                    isFavorite: _favoritesService.isFavorite(
                                      event.id,
                                    ),
                                    onFavoriteToggle: () {
                                      _favoritesService.toggleFavorite(
                                        event.id,
                                      );
                                    },
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) => EventDetailScreen(
                                                event: event,
                                              ),
                                          transitionsBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                child,
                                              ) {
                                                return SlideTransition(
                                                  position:
                                                      Tween<Offset>(
                                                        begin: const Offset(
                                                          1,
                                                          0,
                                                        ),
                                                        end: Offset.zero,
                                                      ).animate(
                                                        CurvedAnimation(
                                                          parent: animation,
                                                          curve: Curves
                                                              .easeOutCubic,
                                                        ),
                                                      ),
                                                  child: child,
                                                );
                                              },
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Full-screen sync modal overlay
          if (_showSyncModal)
            SyncModal(
              status: _syncManager.status,
              onDismiss: () {
                // Force refresh to dismiss modal
                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}
