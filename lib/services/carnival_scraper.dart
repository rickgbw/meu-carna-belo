import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/bloco_event.dart';

class CarnivalScraper {
  static const List<String> _sources = [
    'https://docs.google.com/spreadsheets/d/1rG1TIgtPcuaCUx0JjPyuCGs18TYGztEZPRMHpzXH_UM/edit?fbclid=PAc3J0YwZhcHBfaWQMMjU2MjgxMDQwNTU4AAGnFicur5bsdkg5Dm3Wykg4jj6vnGP23hsZcGT7ZSQWnwyVXHB_wLp3kVyufac&brid=oK3oAjo3xLT4iyLjh9IaJw&gid=0#gid=0',
  ];

  // CORS proxy for web platform (free public proxies)
  static const List<String> _corsProxies = [
    'https://api.allorigins.win/raw?url=',
    'https://corsproxy.io/?',
  ];

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7',
  };

  // Pre-compiled RegExp patterns for better performance
  static final RegExp _datePattern1 = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})');
  static final RegExp _datePattern2 = RegExp(r'(\d{1,2})\s+de\s+(\w+)', caseSensitive: false);
  static final RegExp _datePattern3 = RegExp(r'(\d{1,2})/(\d{1,2})');
  static final RegExp _timePattern = RegExp(r'(\d{1,2})[h:](\d{2})?');
  static final RegExp _idNormalizePattern = RegExp(r'[^a-z0-9]');
  static final RegExp _pricePattern = RegExp(r'R\$\s*(\d+)');
  static final RegExp _urlDatePattern1 = RegExp(r'(\d{2})-(\d{2})-(\d{2})');
  static final RegExp _urlDatePattern2 = RegExp(r'(\d{4})-(\d{2})-(\d{2})');

  // Static month map for efficient lookups
  static const Map<String, int> _monthMap = {
    'jan': 1, 'janeiro': 1, '01': 1, '1': 1,
    'fev': 2, 'fevereiro': 2, '02': 2, '2': 2,
    'mar': 3, 'marco': 3, '03': 3, '3': 3,
    'abr': 4, 'abril': 4, '04': 4, '4': 4,
    'mai': 5, 'maio': 5, '05': 5, '5': 5,
    'jun': 6, 'junho': 6, '06': 6, '6': 6,
    'jul': 7, 'julho': 7, '07': 7, '7': 7,
    'ago': 8, 'agosto': 8, '08': 8, '8': 8,
    'set': 9, 'setembro': 9, '09': 9, '9': 9,
    'out': 10, 'outubro': 10, '10': 10,
    'nov': 11, 'novembro': 11, '11': 11,
    'dez': 12, 'dezembro': 12, '12': 12,
  };

  /// Fetches carnival events from all configured sources
  static Future<List<BlocoEvent>> fetchAllEvents() async {
    final List<BlocoEvent> allEvents = [];
    final Set<String> seenIds = {};

    for (final source in _sources) {
      try {
        final events = await _fetchFromSource(source);
        for (final event in events) {
          if (!seenIds.contains(event.id)) {
            seenIds.add(event.id);
            allEvents.add(event);
          }
        }
      } catch (e) {
        // Continue to next source on error
      }
    }

    // Sort by date
    allEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return allEvents;
  }

  static Future<List<BlocoEvent>> _fetchFromSource(String url) async {
    // On web, try CORS proxies
    if (kIsWeb) {
      for (final proxy in _corsProxies) {
        try {
          final proxyUrl = '$proxy${Uri.encodeComponent(url)}';
          final response = await http
              .get(Uri.parse(proxyUrl))
              .timeout(const Duration(seconds: 30));

          if (response.statusCode == 200 && response.body.isNotEmpty) {
            final events = _parseHtml(response.body, url);
            if (events.isNotEmpty) {
              return events;
            }
          }
        } catch (e) {
          // Try next proxy
          continue;
        }
      }
      return [];
    }

    // On mobile/desktop, fetch directly
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return _parseHtml(response.body, url);
      }
    } catch (e) {
      // Silently fail, will use cached data
    }
    return [];
  }

  static List<BlocoEvent> _parseHtml(String htmlContent, String sourceUrl) {
    final List<BlocoEvent> events = [];
    final document = html_parser.parse(htmlContent);

    // Try to find event cards/items - common patterns on carnival sites
    final eventElements = document.querySelectorAll(
      '.evento, .bloco, .event-item, .programacao-item, article, .card',
    );

    for (final element in eventElements) {
      try {
        final event = _parseEventElement(element, sourceUrl);
        if (event != null) {
          events.add(event);
        }
      } catch (e) {
        // Skip malformed elements
      }
    }

    // If no events found with specific selectors, try generic parsing
    if (events.isEmpty) {
      events.addAll(_parseGenericStructure(document, sourceUrl));
    }

    return events;
  }

  static BlocoEvent? _parseEventElement(Element element, String sourceUrl) {
    // Try to extract event name
    String? name = _extractText(element, [
      'h1',
      'h2',
      'h3',
      'h4',
      '.titulo',
      '.title',
      '.nome',
      '.name',
      '.event-title',
    ]);

    if (name == null || name.isEmpty) return null;

    // Extract date
    String? dateStr = _extractText(element, [
      '.data',
      '.date',
      '.quando',
      '.when',
      'time',
      '.event-date',
    ]);

    // Extract time
    String? timeStr = _extractText(element, [
      '.horario',
      '.hora',
      '.time',
      '.hour',
    ]);

    // Extract location
    String? location = _extractText(element, [
      '.local',
      '.location',
      '.endereco',
      '.address',
      '.onde',
      '.where',
      '.bairro',
    ]);

    // Extract description
    String? description = _extractText(element, [
      '.descricao',
      '.description',
      '.sobre',
      '.about',
      'p',
    ]);

    // Extract price
    String? price = _extractText(element, [
      '.preco',
      '.price',
      '.valor',
      '.ingresso',
      '.ticket',
    ]);

    // Extract link for more details
    String? detailUrl = element.querySelector('a')?.attributes['href'];

    // Parse date and time
    DateTime eventDateTime = _parseDateTime(dateStr, timeStr);

    // Generate unique ID
    String id = _generateId(name, eventDateTime);

    // Extract neighborhood from location
    String neighborhood = _extractNeighborhood(location ?? '');

    return BlocoEvent(
      id: id,
      name: name,
      dateTime: eventDateTime,
      description: description ?? 'Bloco de carnaval em Belo Horizonte.',
      address: location ?? 'Belo Horizonte, MG',
      neighborhood: neighborhood.isNotEmpty ? neighborhood : 'Centro',
      ticketPrice: price ?? _inferPrice(description),
      ticketUrl: detailUrl,
      tags: _extractTags(name, description),
    );
  }

  static List<BlocoEvent> _parseGenericStructure(
    Document document,
    String sourceUrl,
  ) {
    final List<BlocoEvent> events = [];

    // Look for links that might be event pages
    final links = document.querySelectorAll(
      'a[href*="programacao"], a[href*="bloco"], a[href*="evento"]',
    );

    for (final link in links) {
      final href = link.attributes['href'];
      final text = link.text.trim();

      if (text.isNotEmpty && text.length > 5 && href != null) {
        // Check if it looks like an event name
        if (_looksLikeEventName(text)) {
          final dateMatch = _extractDateFromUrl(href);

          events.add(
            BlocoEvent(
              id: _generateId(text, dateMatch ?? DateTime(2026, 2, 1)),
              name: text,
              dateTime: dateMatch ?? DateTime(2026, 2, 1, 16, 0),
              description:
                  'Bloco de carnaval em Belo Horizonte. Mais informacoes em breve!',
              address: 'Belo Horizonte, MG',
              neighborhood: 'Centro',
              ticketPrice: 'Consulte',
              ticketUrl: _makeAbsoluteUrl(href, sourceUrl),
              tags: _extractTags(text, null),
            ),
          );
        }
      }
    }

    return events;
  }

  static String? _extractText(Element element, List<String> selectors) {
    for (final selector in selectors) {
      final found = element.querySelector(selector);
      if (found != null) {
        final text = found.text.trim();
        if (text.isNotEmpty) return text;
      }
    }
    return null;
  }

  static DateTime _parseDateTime(String? dateStr, String? timeStr) {
    // Default to carnival season 2026
    int year = 2026;
    int month = 2;
    int day = 1;
    int hour = 16;
    int minute = 0;

    if (dateStr != null) {
      // Try various date formats using pre-compiled patterns
      final patterns = [_datePattern1, _datePattern2, _datePattern3];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(dateStr);
        if (match != null) {
          if (match.groupCount >= 2) {
            day = int.tryParse(match.group(1) ?? '') ?? day;
            final monthPart = match.group(2) ?? '';
            month = _parseMonth(monthPart);
            if (match.groupCount >= 3) {
              int? parsedYear = int.tryParse(match.group(3) ?? '');
              if (parsedYear != null) {
                year = parsedYear < 100 ? 2000 + parsedYear : parsedYear;
              }
            }
          }
          break;
        }
      }
    }

    if (timeStr != null) {
      final match = _timePattern.firstMatch(timeStr);
      if (match != null) {
        hour = int.tryParse(match.group(1) ?? '') ?? hour;
        minute = int.tryParse(match.group(2) ?? '') ?? 0;
      }
    }

    return DateTime(year, month, day, hour, minute);
  }

  static int _parseMonth(String monthStr) {
    return _monthMap[monthStr.toLowerCase()] ?? 2;
  }

  static String _extractNeighborhood(String location) {
    final neighborhoods = [
      'Centro',
      'Savassi',
      'Funcionarios',
      'Lourdes',
      'Santa Efigenia',
      'Floresta',
      'Barro Preto',
      'Lagoinha',
      'Pampulha',
      'Gameleira',
      'Dom Cabral',
      'Serra',
      'Sion',
      'Anchieta',
      'Carmo',
      'Cruzeiro',
      'Santo Antonio',
      'Cidade Jardim',
      'Buritis',
      'Belvedere',
    ];

    for (final neighborhood in neighborhoods) {
      if (location.toLowerCase().contains(neighborhood.toLowerCase())) {
        return neighborhood;
      }
    }
    return '';
  }

  static String _generateId(String name, DateTime dateTime) {
    final normalized = name.toLowerCase().replaceAll(_idNormalizePattern, '');
    return '${normalized}_${dateTime.millisecondsSinceEpoch}';
  }

  static String? _inferPrice(String? description) {
    if (description == null) return null;

    final lower = description.toLowerCase();
    if (lower.contains('gratuito') ||
        lower.contains('gratis') ||
        lower.contains('free')) {
      return 'Entrada Gratuita';
    }

    final match = _pricePattern.firstMatch(description);
    if (match != null) {
      return 'A partir de R\$ ${match.group(1)}';
    }

    return null;
  }

  static List<String> _extractTags(String name, String? description) {
    final tags = <String>[];
    final text = '${name.toLowerCase()} ${description?.toLowerCase() ?? ''}';

    final tagPatterns = {
      'Axe': ['axe', 'axé', 'micareta', 'trio eletrico'],
      'Samba': ['samba', 'pagode', 'bateria', 'escola de samba'],
      'Funk': ['funk', 'baile'],
      'Rock': ['rock', 'pop rock'],
      'Marchinhas': ['marchinha', 'carnaval tradicional'],
      'Forro': ['forro', 'forró', 'nordestino'],
      'Eletronica': ['eletronico', 'eletrônico', 'dj', 'techno'],
      'Gratuito': ['gratuito', 'gratis', 'free', 'entrada franca'],
      'Tradicional': ['tradicional', 'tradicao', 'historico'],
      'Familia': ['familia', 'crianca', 'infantil'],
    };

    for (final entry in tagPatterns.entries) {
      for (final pattern in entry.value) {
        if (text.contains(pattern)) {
          tags.add(entry.key);
          break;
        }
      }
    }

    return tags.take(4).toList();
  }

  static bool _looksLikeEventName(String text) {
    if (text.length < 5 || text.length > 100) return false;

    final keywords = [
      'bloco',
      'ensaio',
      'carnaval',
      'pre-carnaval',
      'axe',
      'samba',
    ];
    final lower = text.toLowerCase();

    for (final keyword in keywords) {
      if (lower.contains(keyword)) return true;
    }

    // Check if it starts with a capital letter (likely a name)
    if (text[0] == text[0].toUpperCase() && text[0] != text[0].toLowerCase()) {
      return true;
    }

    return false;
  }

  static DateTime? _extractDateFromUrl(String url) {
    // Try to extract date from URL patterns like /16-01-26/ or /2026-01-16/
    // Check 4-digit year pattern first
    var match = _urlDatePattern2.firstMatch(url);
    if (match != null) {
      try {
        final year = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final day = int.parse(match.group(3)!);
        return DateTime(year, month, day, 16, 0);
      } catch (_) {
        // Fall through to next pattern
      }
    }

    // Try 2-digit year pattern
    match = _urlDatePattern1.firstMatch(url);
    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = 2000 + int.parse(match.group(3)!);
        return DateTime(year, month, day, 16, 0);
      } catch (_) {
        // Return null if parsing fails
      }
    }

    return null;
  }

  static String _makeAbsoluteUrl(String href, String sourceUrl) {
    if (href.startsWith('http')) return href;

    final uri = Uri.parse(sourceUrl);
    if (href.startsWith('/')) {
      return '${uri.scheme}://${uri.host}$href';
    }
    return '${uri.scheme}://${uri.host}/${uri.pathSegments.take(uri.pathSegments.length - 1).join('/')}/$href';
  }
}
