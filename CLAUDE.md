# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter-based Quran memorization application ("Kuran Ezber") developed by KSU Electronic Mushaf Team. The app provides an interactive digital mushaf (Quran) experience with Arabic text, Turkish translations, audio playback, and memorization features.

## Key Development Commands

### Building and Running
```bash
# Run the app in development mode
flutter run

# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Code Quality
```bash
# Check linting rules
flutter analyze

# Format code
flutter format .

# Clean build artifacts
flutter clean
```

## Architecture Overview

### Core Structure
- **Provider Pattern**: Uses `KuranProvider` for state management with Flutter's `Provider` package
- **Service Layer**: `QuranApiService` handles all API interactions with AlQuran.cloud
- **Model Layer**: Data models for `SurahModel`, `AyetModel`, and `MushafPageModel`
- **Storage Layer**: `StorageHelper` manages local storage using SharedPreferences
- **Audio Management**: `AudioManager` handles Quran recitation playback

### Key Components

#### State Management (`lib/providers/kuran_provider.dart`)
- Central state management for the entire app
- Handles API calls, caching, bookmarks, and settings
- Implements offline-first architecture with background refresh
- Error handling with retry mechanisms and user-friendly messages

#### API Service (`lib/services/quran_api_service.dart`)
- Communicates with AlQuran.cloud API
- Supports Arabic text, Turkish translations, and audio URLs
- Handles multiple API endpoints for different data types
- Implements timeout and error handling

#### Models (`lib/models/`)
- `SurahModel`: Represents a Quran chapter with Turkish name mapping
- `AyetModel`: Represents a verse with Arabic text, translation, and audio URL
- `MushafPageModel`: Represents a page view of the Quran

#### Storage (`lib/utils/storage_helper.dart`)
- Manages local data persistence
- Handles caching, bookmarks, settings, and user preferences
- Implements cache expiration and cleanup

### Screen Architecture

#### Main Screens
- `sure_listesi.dart`: Main surah list screen (home screen)
- `interactive_mushaf_ekrani.dart`: Interactive mushaf reader with verse numbers
- `search_screen.dart`: Search functionality across the Quran
- `ayarlar_ekrani.dart`: Settings screen for app configuration

#### Widgets
- `ayet_item.dart`: Individual verse display widget
- `custom_app_bar.dart`: Customized app bar component
- `surah_card.dart`: Surah list item widget

### Features

#### Core Features
- **Offline-First**: Caches data locally, works without internet
- **Dual Language**: Arabic text with Turkish translations
- **Audio Support**: Verse-by-verse audio playback
- **Bookmarking**: Save favorite verses
- **Dark/Light Theme**: Theme switching support
- **Font Size Control**: Adjustable Arabic font sizes
- **Last Read Position**: Remembers reading progress

#### Technical Features
- **Caching Strategy**: Implements cache-first with background refresh
- **Error Handling**: Comprehensive error handling with retry logic
- **Network Detection**: Checks internet connectivity
- **Settings Persistence**: Saves user preferences locally

## Development Guidelines

### Font Management
- Uses custom Arabic fonts: `UthmanicHafs` and `Amiri`
- Fonts are located in `assets/fonts/`
- Font sizes are configurable through app settings

### API Integration
- Primary API: AlQuran.cloud (`api.alquran.cloud/v1`)
- Supports multiple editions: Arabic (quran-uthmani), Turkish (tr.diyanet), Audio (ar.alafasy)
- Implements timeout handling (10-15 seconds)
- Has fallback mechanisms for failed requests

### State Management Patterns
- Use `KuranProvider` for global state
- Call `notifyListeners()` after state changes
- Implement loading states and error handling
- Use async/await for API calls

### Error Handling
- Provide user-friendly error messages in Turkish
- Implement retry mechanisms with exponential backoff
- Use offline cache as fallback
- Log errors for debugging but don't expose technical details to users

### Storage Conventions
- Use `StorageHelper` for all persistent data
- Implement cache keys with versioning
- Handle storage errors gracefully
- Clean up old cache data periodically

### Testing
- Test files are located in `test/`
- Use `flutter test` to run unit tests
- Test both online and offline scenarios
- Test error conditions and edge cases

## Project Structure

```
lib/
├── main.dart                 # App entry point with theme configuration
├── constants/               # App constants and configuration
├── models/                  # Data models
├── providers/               # State management
├── screens/                 # UI screens
├── services/                # API and external services
├── utils/                   # Utility classes
└── widgets/                 # Reusable UI components
```

## Important Notes

- App is portrait-only (orientation locked)
- Turkish locale is set as default
- Text scaling is limited to 0.8-1.2x range
- Uses Material Design 3 with custom theming
- All strings should be in Turkish for user-facing content
- Audio files are cached for offline playback
- Bookmarks are stored with format `{surahNumber}_{ayahNumber}`

## Current Feature Branch

The current branch `feature/ayetNumaralari` appears to be working on verse numbering functionality in the interactive mushaf screen.