import 'package:flutter/material.dart';
import '../models/bloco_event.dart';
import '../theme/carnival_theme.dart';

class EventCard extends StatelessWidget {
  final BlocoEvent event;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: CarnivalTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: CarnivalTheme.purple.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Decorative confetti dots
              Positioned(
                right: -10,
                top: -10,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: CarnivalTheme.pink.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 30,
                top: 20,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: CarnivalTheme.yellow.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 60,
                bottom: 10,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: CarnivalTheme.cyan.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                event.formattedDate,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: CarnivalTheme.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                event.formattedTime,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Event name
                    Text(
                      event.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: CarnivalTheme.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: CarnivalTheme.pink.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.neighborhood,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: event.tags.asMap().entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: CarnivalTheme.getTagColor(entry.key)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CarnivalTheme.getTagColor(entry.key)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: CarnivalTheme.getTagColor(entry.key),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (event.ticketPrice != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: event.ticketPrice!.contains('Gratuita')
                                  ? CarnivalTheme.green
                                  : CarnivalTheme.gold,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              event.ticketPrice!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: CarnivalTheme.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
