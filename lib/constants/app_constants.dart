class AppConstants {
  // API endpoints
  static const String baseUrl = 'http://api.alquran.cloud/v1';
  static const String turkishEdition = 'tr.diyanet';
  static const String arabicEdition = 'quran-uthmani';
  static const String audioEdition = 'ar.ahmedajamy';

  // Alternative API URLs
  static const String backupApiUrl = 'https://api.quran.com/api/v4';
  static const String audioBaseUrl = 'https://archive.org/download/HaramainHameed/';

  // Cache settings
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 50; // MB
  static const String cacheVersion = 'v1.0';

  // UI settings
  static const double defaultFontSize = 22.0;
  static const double minFontSize = 16.0;
  static const double maxFontSize = 32.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);

  // Audio settings
  static const Duration audioTimeout = Duration(seconds: 15);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const List<String> supportedAudioFormats = ['mp3', 'ogg'];

  // App settings
  static const String appVersion = '2.0.0';
  static const String developer = 'Burak Odabaş';
  static const int currentDbVersion = 1;

  // Pagination
  static const int itemsPerPage = 20;
  static const int maxSearchResults = 100;

  // Local storage keys
  static const String keyBookmarks = 'bookmarks';
  static const String keyLastRead = 'last_read';
  static const String keySettings = 'settings';
  static const String keyCache = 'cache';
  static const String keyTheme = 'theme_mode';
  static const String keyFontSize = 'font_size';
  static const String keyTranslation = 'translation_enabled';

  // Default values
  static const bool defaultTranslationEnabled = false;
  static const bool defaultDarkMode = false;
  static const String defaultTranslationLanguage = 'tr.diyanet';
  static const String defaultAudioReciter = 'ahmed_taleb_hameed';
  
  // Audio reciters
  static const Map<String, String> audioReciters = {
    'ahmed_taleb_hameed': 'Ahmed Taleb Hameed',
    'ar.alafasy': 'Mishary Rashid Alafasy',
    'ar.ahmedajamy': 'Ahmed ibn Ali al-Ajamy',
    'ar.abdurrahmaansudais': 'Abdul Rahman Al-Sudais',
    'ar.saadalghamdi': 'Saad Al-Ghamdi',
  };

  // Network retry settings
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Surah counts (1-114)
  static const List<int> surahAyahCounts = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, // 1-10
    123, 111, 43, 52, 99, 128, 111, 110, 98, 135, // 11-20
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60, // 21-30
    34, 30, 73, 54, 45, 83, 182, 88, 75, 85, // 31-40
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45, // 41-50
    60, 49, 62, 55, 78, 96, 29, 22, 24, 13, // 51-60
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44, // 61-70
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42, // 71-80
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20, // 81-90
    15, 21, 11, 8, 8, 19, 5, 8, 8, 11, // 91-100
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3, // 101-110
    5, 4, 5, 6 // 111-114
  ];

  // Popular surahs for quick access
  static const List<int> popularSurahs = [1, 2, 3, 4, 18, 36, 55, 67, 112, 113, 114];

  // Juz information
  static const int totalJuz = 30;
  static const int totalPages = 604;
  static const int totalSurahs = 114;
  static const int totalAyahs = 6236;
}