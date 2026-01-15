import 'package:flutter/material.dart';

import '../models/bloco_event.dart';
import '../theme/carnival_theme.dart';

class EventCard extends StatelessWidget {
  final BlocoEvent event;
  final VoidCallback onTap;
  final String? distanceText;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.distanceText,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  // Cached decorations for better performance
  static final _cardBorderRadius = BorderRadius.circular(20);
  static final _badgeBorderRadius = BorderRadius.circular(20);
  static final _priceBorderRadius = BorderRadius.circular(15);
  static final _distanceBorderRadius = BorderRadius.circular(10);

  static const _dateGradient = LinearGradient(
    colors: [CarnivalTheme.purple, CarnivalTheme.pink],
  );

  bool get _isPastEvent {
    final now = DateTime.now();
    final eventEnd = event.dateTime.add(const Duration(hours: 6));
    return eventEnd.isBefore(now);
  }

  @override
  Widget build(BuildContext context) {
    final isPast = _isPastEvent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isPast ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isPast ? null : CarnivalTheme.cardGradient,
            color: isPast ? Colors.grey[200] : null,
            borderRadius: _cardBorderRadius,
            boxShadow: [
              BoxShadow(
                color: isPast
                    ? Colors.grey.withOpacity(0.2)
                    : CarnivalTheme.purple.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: _cardBorderRadius,
            child: Stack(
              children: [
                // Decorative confetti dots - using const where possible
                const _ConfettiDot(
                  right: -10,
                  top: -10,
                  size: 60,
                  color: CarnivalTheme.pink,
                  opacity: 0.2,
                ),
                const _ConfettiDot(
                  right: 30,
                  top: 20,
                  size: 20,
                  color: CarnivalTheme.yellow,
                  opacity: 0.4,
                ),
                const _ConfettiDot(
                  right: 60,
                  bottom: 10,
                  size: 15,
                  color: CarnivalTheme.cyan,
                  opacity: 0.3,
                ),
                // Favorite button
                if (onFavoriteToggle != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _FavoriteButton(
                      isFavorite: isFavorite,
                      onTap: onFavoriteToggle!,
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
                              gradient: _dateGradient,
                              borderRadius: _badgeBorderRadius,
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
                              borderRadius: _badgeBorderRadius,
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
                          if (distanceText != null && distanceText!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: CarnivalTheme.cyan.withOpacity(0.2),
                                borderRadius: _distanceBorderRadius,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.navigation,
                                    size: 12,
                                    color: CarnivalTheme.cyan,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    distanceText!,
                                    style: const TextStyle(
                                      color: CarnivalTheme.cyan,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Tags
                      if (event.tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (int i = 0; i < event.tags.length; i++)
                              _TagChip(tag: event.tags[i], index: i),
                          ],
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
                                borderRadius: _priceBorderRadius,
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
      ),
    );
  }
}

/// Confetti dot decoration - extracted for const construction
class _ConfettiDot extends StatelessWidget {
  final double? right;
  final double? top;
  final double? bottom;
  final double size;
  final Color color;
  final double opacity;

  const _ConfettiDot({
    this.right,
    this.top,
    this.bottom,
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Favorite button - extracted for cleaner code
class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 20,
          color: isFavorite ? CarnivalTheme.pink : Colors.grey,
        ),
      ),
    );
  }
}

/// Tag chip - extracted for cleaner iteration
class _TagChip extends StatelessWidget {
  final String tag;
  final int index;

  const _TagChip({required this.tag, required this.index});

  static final _borderRadius = BorderRadius.circular(12);

  @override
  Widget build(BuildContext context) {
    final color = CarnivalTheme.getTagColor(index);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: _borderRadius,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
