import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageHelper {
  static SharedPreferences? _prefs;

  /// SharedPreferences'ı başlat
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// SharedPreferences instance'ını al
  static Future<SharedPreferences> get _instance async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // ===================
  // GENERIC METHODS
  // ===================

  /// String değer kaydet
  static Future<bool> setString(String key, String value) async {
    try {
      final prefs = await _instance;
      return await prefs.setString(key, value);
    } catch (e) {
      debugPrint('StorageHelper setString error: $e');
      return false;
    }
  }

  /// String değer al
  static Future<String?> getString(String key, [String? defaultValue]) async {
    try {
      final prefs = await _instance;
      return prefs.getString(key) ?? defaultValue;
    } catch (e) {
      debugPrint('StorageHelper getString error: $e');
      return defaultValue;
    }
  }

  /// Integer değer kaydet
  static Future<bool> setInt(String key, int value) async {
    try {
      final prefs = await _instance;
      return await prefs.setInt(key, value);
    } catch (e) {
      debugPrint('StorageHelper setInt error: $e');
      return false;
    }
  }

  /// Integer değer al
  static Future<int?> getInt(String key, [int? defaultValue]) async {
    try {
      final prefs = await _instance;
      return prefs.getInt(key) ?? defaultValue;
    } catch (e) {
      debugPrint('StorageHelper getInt error: $e');
      return defaultValue;
    }
  }

  /// Boolean değer kaydet
  static Future<bool> setBool(String key, bool value) async {
    try {
      final prefs = await _instance;
      return await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('StorageHelper setBool error: $e');
      return false;
    }
  }

  /// Boolean değer al
  static Future<bool> getBool(String key, [bool defaultValue = false]) async {
    try {
      final prefs = await _instance;
      return prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      debugPrint('StorageHelper getBool error: $e');
      return defaultValue;
    }
  }

  /// Double değer kaydet
  static Future<bool> setDouble(String key, double value) async {
    try {
      final prefs = await _instance;
      return await prefs.setDouble(key, value);
    } catch (e) {
      debugPrint('StorageHelper setDouble error: $e');
      return false;
    }
  }

  /// Double değer al
  static Future<double?> getDouble(String key, [double? defaultValue]) async {
    try {
      final prefs = await _instance;
      return prefs.getDouble(key) ?? defaultValue;
    } catch (e) {
      debugPrint('StorageHelper getDouble error: $e');
      return defaultValue;
    }
  }

  /// String list kaydet
  static Future<bool> setStringList(String key, List<String> value) async {
    try {
      final prefs = await _instance;
      return await prefs.setStringList(key, value);
    } catch (e) {
      debugPrint('StorageHelper setStringList error: $e');
      return false;
    }
  }

  /// String list al
  static Future<List<String>> getStringList(String key, [List<String>? defaultValue]) async {
    try {
      final prefs = await _instance;
      return prefs.getStringList(key) ?? defaultValue ?? [];
    } catch (e) {
      debugPrint('StorageHelper getStringList error: $e');
      return defaultValue ?? [];
    }
  }

  /// JSON object kaydet
  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      return await setString(key, jsonString);
    } catch (e) {
      debugPrint('StorageHelper setJson error: $e');
      return false;
    }
  }

  /// JSON object al
  static Future<Map<String, dynamic>?> getJson(String key) async {
    try {
      final jsonString = await getString(key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('StorageHelper getJson error: $e');
      return null;
    }
  }

  /// Belirli bir key'i sil
  static Future<bool> remove(String key) async {
    try {
      final prefs = await _instance;
      return await prefs.remove(key);
    } catch (e) {
      debugPrint('StorageHelper remove error: $e');
      return false;
    }
  }

  /// Tüm verileri temizle
  static Future<bool> clear() async {
    try {
      final prefs = await _instance;
      return await prefs.clear();
    } catch (e) {
      debugPrint('StorageHelper clear error: $e');
      return false;
    }
  }

  /// Belirli bir key'in varlığını kontrol et
  static Future<bool> containsKey(String key) async {
    try {
      final prefs = await _instance;
      return prefs.containsKey(key);
    } catch (e) {
      debugPrint('StorageHelper containsKey error: $e');
      return false;
    }
  }

  /// Tüm key'leri al
  static Future<Set<String>> getKeys() async {
    try {
      final prefs = await _instance;
      return prefs.getKeys();
    } catch (e) {
      debugPrint('StorageHelper getKeys error: $e');
      return <String>{};
    }
  }

  // ===================
  // APP-SPECIFIC METHODS
  // ===================

  // Theme Settings
  static Future<bool> setDarkMode(bool isDark) async {
    return await setBool(AppConstants.keyTheme, isDark);
  }

  static Future<bool> getDarkMode() async {
    return await getBool(AppConstants.keyTheme, AppConstants.defaultDarkMode);
  }

  // Font Size
  static Future<bool> setFontSize(double fontSize) async {
    return await setDouble(AppConstants.keyFontSize, fontSize);
  }

  static Future<double> getFontSize() async {
    return await getDouble(AppConstants.keyFontSize, AppConstants.defaultFontSize) ?? AppConstants.defaultFontSize;
  }

  // Translation Settings
  static Future<bool> setTranslationEnabled(bool enabled) async {
    return await setBool(AppConstants.keyTranslation, enabled);
  }

  static Future<bool> getTranslationEnabled() async {
    return await getBool(AppConstants.keyTranslation, AppConstants.defaultTranslationEnabled);
  }

  static Future<bool> setTranslationLanguage(String language) async {
    return await setString('translation_language', language);
  }

  static Future<String> getTranslationLanguage() async {
    return await getString('translation_language', AppConstants.defaultTranslationLanguage) ?? AppConstants.defaultTranslationLanguage;
  }

  // Bookmarks
  static Future<bool> setBookmarks(List<String> bookmarks) async {
    return await setStringList(AppConstants.keyBookmarks, bookmarks);
  }

  static Future<List<String>> getBookmarks() async {
    return await getStringList(AppConstants.keyBookmarks);
  }

  static Future<bool> addBookmark(String bookmark) async {
    final bookmarks = await getBookmarks();
    if (!bookmarks.contains(bookmark)) {
      bookmarks.add(bookmark);
      return await setBookmarks(bookmarks);
    }
    return true;
  }

  static Future<bool> removeBookmark(String bookmark) async {
    final bookmarks = await getBookmarks();
    bookmarks.remove(bookmark);
    return await setBookmarks(bookmarks);
  }

  static Future<bool> isBookmarked(String bookmark) async {
    final bookmarks = await getBookmarks();
    return bookmarks.contains(bookmark);
  }

  // Last Read Position
  static Future<bool> setLastReadPosition(int surahNumber, int ayahNumber) async {
    final lastRead = {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return await setJson(AppConstants.keyLastRead, lastRead);
  }

  static Future<Map<String, int>?> getLastReadPosition() async {
    try {
      final data = await getJson(AppConstants.keyLastRead);
      if (data != null) {
        return {
          'surahNumber': data['surahNumber'] as int,
          'ayahNumber': data['ayahNumber'] as int,
        };
      }
      return null;
    } catch (e) {
      debugPrint('getLastReadPosition error: $e');
      return null;
    }
  }

  // Cache Management
  static Future<bool> setCacheData(String key, Map<String, dynamic> data) async {
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'version': AppConstants.cacheVersion,
    };
    return await setJson('${AppConstants.keyCache}_$key', cacheData);
  }

  static Future<Map<String, dynamic>?> getCacheData(String key) async {
    try {
      final cacheData = await getJson('${AppConstants.keyCache}_$key');
      if (cacheData != null) {
        final timestamp = cacheData['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        final expiration = AppConstants.cacheExpiration.inMilliseconds;

        // Cache süresi dolmuş mu kontrol et
        if (now - timestamp < expiration) {
          return cacheData['data'] as Map<String, dynamic>;
        } else {
          // Süresi dolmuş cache'i sil
          await remove('${AppConstants.keyCache}_$key');
        }
      }
      return null;
    } catch (e) {
      debugPrint('getCacheData error: $e');
      return null;
    }
  }

  static Future<bool> clearCache() async {
    try {
      final keys = await getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(AppConstants.keyCache));

      for (final key in cacheKeys) {
        await remove(key);
      }
      return true;
    } catch (e) {
      debugPrint('clearCache error: $e');
      return false;
    }
  }

  // Audio Settings
  static Future<bool> setAudioReciter(String reciter) async {
    return await setString('audio_reciter', reciter);
  }

  static Future<String> getAudioReciter() async {
    return await getString('audio_reciter', AppConstants.defaultAudioReciter) ?? AppConstants.defaultAudioReciter;
  }

  static Future<bool> setAudioQuality(String quality) async {
    return await setString('audio_quality', quality);
  }

  static Future<String> getAudioQuality() async {
    return await getString('audio_quality', '128') ?? '128';
  }

  // Statistics
  static Future<bool> incrementReadCount() async {
    final currentCount = await getInt('read_count', 0) ?? 0;
    return await setInt('read_count', currentCount + 1);
  }

  static Future<int> getReadCount() async {
    return await getInt('read_count', 0) ?? 0;
  }

  static Future<bool> setLastOpenDate() async {
    return await setInt('last_open_date', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<DateTime?> getLastOpenDate() async {
    final timestamp = await getInt('last_open_date');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // First Launch
  static Future<bool> setFirstLaunch(bool isFirst) async {
    return await setBool('is_first_launch', isFirst);
  }

  static Future<bool> isFirstLaunch() async {
    return await getBool('is_first_launch', true);
  }

  // Storage Info
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final keys = await getKeys();
      final totalKeys = keys.length;
      final cacheKeys = keys.where((key) => key.startsWith(AppConstants.keyCache)).length;
      final bookmarks = await getBookmarks();
      final lastRead = await getLastReadPosition();

      return {
        'totalKeys': totalKeys,
        'cacheKeys': cacheKeys,
        'bookmarksCount': bookmarks.length,
        'hasLastRead': lastRead != null,
        'isDarkMode': await getDarkMode(),
        'translationEnabled': await getTranslationEnabled(),
        'fontSize': await getFontSize(),
        'readCount': await getReadCount(),
        'isFirstLaunch': await isFirstLaunch(),
      };
    } catch (e) {
      debugPrint('getStorageInfo error: $e');
      return <String, dynamic>{};
    }
  }
}