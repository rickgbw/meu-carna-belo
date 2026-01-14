# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Meu Carna BH is a Flutter app for discovering carnival street parties (blocos) in Belo Horizonte, Brazil. The app scrapes event data from Google Sheets, stores it locally with Hive, and provides location-based features.

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Build for release
flutter build apk --release           # Android
flutter build ios --release           # iOS
flutter build web --release           # Web

# Run tests
flutter test                          # All tests
flutter test test/widget_test.dart    # Single test file

# Code analysis
flutter analyze

# Generate app icons (after changing assets/icon/)
dart run flutter_launcher_icons
```

## Architecture

```
lib/
├── main.dart              # App entry with animated SplashScreen
├── data/blocos_data.dart  # Static fallback event data for offline mode
├── models/bloco_event.dart # Immutable event model with copyWith()
├── screens/
│   ├── home_screen.dart   # Main list with search/filter/sort
│   └── event_detail_screen.dart
├── services/
│   ├── carnival_scraper.dart  # HTML scraping from Google Sheets
│   ├── sync_manager.dart      # ChangeNotifier state management + Hive caching
│   ├── location_service.dart  # GPS wrapper using geolocator
│   └── geocoding_service.dart # Address to coordinates conversion
├── theme/carnival_theme.dart  # Colors, gradients, typography (Poppins/Pacifico)
└── widgets/
    ├── event_card.dart    # Reusable event list item
    └── sync_modal.dart    # Sync status indicator
```

## Key Patterns

- **State Management**: Provider pattern via `SyncManager extends ChangeNotifier`
- **Data Flow**: SyncManager initializes on app start, fetches from web or falls back to static data
- **Caching**: Hive for event storage, SharedPreferences for sync timestamps
- **Web Scraping**: CarnivalScraper handles CORS proxies (web) vs direct HTTP (mobile)
- **Geocoding**: Rate-limited (300ms delay) batch conversion of addresses to coordinates

## Data Sources

The app fetches events from a Google Sheet (URL in `carnival_scraper.dart`). When offline or on failure, it uses hardcoded data from `data/blocos_data.dart`.

## UI Conventions

- All user-facing strings are in Portuguese
- Carnival color palette: purple (#6A1B9A), pink (#E91E63), orange (#FF9800)
- Past events display at 50% opacity with gray background
- Distance shown when user grants location permission
