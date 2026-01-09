import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bloco_event.dart';
import '../theme/carnival_theme.dart';

class EventDetailScreen extends StatelessWidget {
  final BlocoEvent event;

  const EventDetailScreen({super.key, required this.event});

  Future<void> _openGoogleMaps() async {
    final url = Uri.parse(event.googleMapsUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTicketUrl() async {
    if (event.ticketUrl != null) {
      final url = Uri.parse(event.ticketUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
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
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Detalhes do Bloco',
                        style: GoogleFonts.pacifico(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Text('🎊', style: TextStyle(fontSize: 28)),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Decorative element
                          Center(
                            child: Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    CarnivalTheme.purple,
                                    CarnivalTheme.pink,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Event name
                          Row(
                            children: [
                              const Text('🎭', style: TextStyle(fontSize: 32)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  event.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: CarnivalTheme.deepPurple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Date and time card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  CarnivalTheme.purple,
                                  CarnivalTheme.pink,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'DATA',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        event.formattedDate,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'HORARIO',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        event.formattedTime,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Description
                          _buildSection(
                            icon: Icons.info_outline,
                            title: 'Sobre o Bloco',
                            child: Text(
                              event.description,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Location
                          _buildSection(
                            icon: Icons.location_on,
                            title: 'Local',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.address,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${event.neighborhood}, Belo Horizonte - MG',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Price
                          if (event.ticketPrice != null)
                            _buildSection(
                              icon: Icons.confirmation_number,
                              title: 'Ingresso',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      event.ticketPrice!.contains('Gratuita')
                                          ? CarnivalTheme.green.withOpacity(0.1)
                                          : CarnivalTheme.gold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color:
                                        event.ticketPrice!.contains('Gratuita')
                                            ? CarnivalTheme.green
                                            : CarnivalTheme.gold,
                                  ),
                                ),
                                child: Text(
                                  event.ticketPrice!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        event.ticketPrice!.contains('Gratuita')
                                            ? CarnivalTheme.green
                                            : CarnivalTheme.gold,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          // Tags
                          if (event.tags.isNotEmpty)
                            _buildSection(
                              icon: Icons.tag,
                              title: 'Estilos',
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    event.tags.asMap().entries.map((entry) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CarnivalTheme.getTagColor(entry.key)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            CarnivalTheme.getTagColor(entry.key)
                                                .withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        color:
                                            CarnivalTheme.getTagColor(entry.key),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          const SizedBox(height: 32),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.map,
                                  label: 'Como Chegar',
                                  gradient: const LinearGradient(
                                    colors: [
                                      CarnivalTheme.cyan,
                                      CarnivalTheme.green,
                                    ],
                                  ),
                                  onTap: _openGoogleMaps,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (event.ticketUrl != null)
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.confirmation_number,
                                    label: 'Comprar',
                                    gradient: const LinearGradient(
                                      colors: [
                                        CarnivalTheme.orange,
                                        CarnivalTheme.yellow,
                                      ],
                                    ),
                                    onTap: _openTicketUrl,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Fun decoration
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text('🎺', style: TextStyle(fontSize: 24)),
                                SizedBox(width: 8),
                                Text('🥁', style: TextStyle(fontSize: 24)),
                                SizedBox(width: 8),
                                Text('🎷', style: TextStyle(fontSize: 24)),
                                SizedBox(width: 8),
                                Text('🎤', style: TextStyle(fontSize: 24)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CarnivalTheme.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: CarnivalTheme.purple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CarnivalTheme.deepPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: child,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: CarnivalTheme.purple.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
