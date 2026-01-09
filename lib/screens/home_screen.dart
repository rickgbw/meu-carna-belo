import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bloco_event.dart';
import '../theme/carnival_theme.dart';
import '../widgets/event_card.dart';
import '../services/sync_manager.dart';
import 'event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final SyncManager _syncManager = SyncManager();
  List<BlocoEvent> _filteredEvents = [];
  String _searchQuery = '';
  String _selectedFilter = 'Todos';
  late AnimationController _animationController;

  final List<String> _filters = [
    'Todos',
    'Gratuito',
    'Axe',
    'Samba',
    'Funk',
    'Rock',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _syncManager.addListener(_onSyncUpdate);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _syncManager.initialize();
    _filterEvents();
    _animationController.forward();
  }

  void _onSyncUpdate() {
    if (mounted) {
      _filterEvents();
    }
  }

  @override
  void dispose() {
    _syncManager.removeListener(_onSyncUpdate);
    _syncManager.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _filterEvents() {
    setState(() {
      _filteredEvents = _syncManager.events.where((event) {
        final matchesSearch =
            event.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                event.neighborhood
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                event.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());

        final matchesFilter = _selectedFilter == 'Todos' ||
            (_selectedFilter == 'Gratuito' &&
                event.ticketPrice?.contains('Gratuita') == true) ||
            event.tags
                .any((tag) => tag.toLowerCase() == _selectedFilter.toLowerCase());

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _refreshData() async {
    await _syncManager.syncEvents(force: true);
    _animationController.reset();
    _animationController.forward();
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
                child: const Icon(
                  Icons.sync,
                  color: Colors.white,
                  size: 28,
                ),
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
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
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
                  label: Text(_syncManager.isSyncing ? 'Sincronizando...' : 'Sincronizar'),
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
          const SizedBox(height: 16),
          Text(
            'Fontes: blocosderua.com e outros sites de carnaval',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isError = false}) {
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
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                    // Title with sync button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '🎭',
                          style: TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Meu Carna BH',
                          style: GoogleFonts.pacifico(
                            fontSize: 32,
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
                        const SizedBox(width: 8),
                        const Text(
                          '🎉',
                          style: TextStyle(fontSize: 28),
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
                                    : _syncManager.status == SyncStatus.offline
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
                    const SizedBox(height: 12),
                    Text(
                      'Blocos de Rua 2026',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterEvents();
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar blocos...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(
                            Icons.search,
                            color: CarnivalTheme.purple.withOpacity(0.6),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.refresh,
                              color: _syncManager.isSyncing
                                  ? Colors.grey[300]
                                  : CarnivalTheme.purple.withOpacity(0.6),
                            ),
                            onPressed:
                                _syncManager.isSyncing ? null : _refreshData,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Filter chips
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                _selectedFilter = filter;
                                _filterEvents();
                              },
                              backgroundColor: Colors.white.withOpacity(0.2),
                              selectedColor: CarnivalTheme.yellow,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? CarnivalTheme.deepPurple
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? CarnivalTheme.yellow
                                      : Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Events count and next sync
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        '${_filteredEvents.length} blocos encontrados',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_syncManager.needsSync && !_syncManager.isSyncing)
                      GestureDetector(
                        onTap: _refreshData,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: CarnivalTheme.orange.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.update,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Atualizar',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
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
                                  position: Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(
                                        (index / _filteredEvents.length) * 0.5,
                                        ((index + 1) / _filteredEvents.length) *
                                                0.5 +
                                            0.5,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                  ),
                                  child: EventCard(
                                    event: event,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation,
                                                  secondaryAnimation) =>
                                              EventDetailScreen(event: event),
                                          transitionsBuilder: (context,
                                              animation,
                                              secondaryAnimation,
                                              child) {
                                            return SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(1, 0),
                                                end: Offset.zero,
                                              ).animate(CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeOutCubic,
                                              )),
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
    );
  }
}
