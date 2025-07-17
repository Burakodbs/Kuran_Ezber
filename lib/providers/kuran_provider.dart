import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/surah_model.dart';
import '../models/ayet_model.dart';
import '../services/quran_api_service.dart';
import '../utils/storage_helper.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

class KuranProvider with ChangeNotifier {
  List<SurahModel> _sureler = [];
  bool _yukleniyor = true;
  String _hata = '';
  final Map<String, bool> _yerIsaretleri = {};
  bool _translationGoster = AppConstants.defaultTranslationEnabled;
  double _arabicFontSize = AppConstants.defaultFontSize;
  String _selectedTranslation = AppConstants.defaultTranslationLanguage;
  bool _darkMode = AppConstants.defaultDarkMode;
  bool _isOnline = true;
  int _retryCount = 0;

  // Getters
  List<SurahModel> get sureler => _sureler;
  bool get yukleniyor => _yukleniyor;
  String get hata => _hata;
  bool get translationGoster => _translationGoster;
  double get arabicFontSize => _arabicFontSize;
  String get selectedTranslation => _selectedTranslation;
  bool get darkMode => _darkMode;
  bool get isOnline => _isOnline;

  KuranProvider() {
    _init();
  }

  /// Provider'ı başlat
  Future<void> _init() async {
    await StorageHelper.init();
    await _loadSettings();
    await loadYerIsaretleri();
    await sureleriYukle();
    await _checkFirstLaunch();
  }

  /// İlk açılış kontrolü
  Future<void> _checkFirstLaunch() async {
    final isFirst = await StorageHelper.isFirstLaunch();
    if (isFirst) {
      await StorageHelper.setFirstLaunch(false);
      // İlk açılış işlemleri burada yapılabilir
      debugPrint('First launch detected');
    }
    await StorageHelper.setLastOpenDate();
  }

  /// Ayarları yükle
  Future<void> _loadSettings() async {
    try {
      _translationGoster = await StorageHelper.getTranslationEnabled();
      _arabicFontSize = await StorageHelper.getFontSize();
      _selectedTranslation = await StorageHelper.getTranslationLanguage();
      _darkMode = await StorageHelper.getDarkMode();
      notifyListeners();
    } catch (e) {
      debugPrint('Settings load error: $e');
    }
  }

  /// Çeviri gösterimi açık/kapalı
  Future<void> toggleTranslation() async {
    _translationGoster = !_translationGoster;
    await StorageHelper.setTranslationEnabled(_translationGoster);
    notifyListeners();
  }

  /// Dark mode açık/kapalı
  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    await StorageHelper.setDarkMode(_darkMode);
    notifyListeners();
  }

  /// Arapça font boyutunu ayarla
  Future<void> setArabicFontSize(double size) async {
    if (size >= AppConstants.minFontSize && size <= AppConstants.maxFontSize) {
      _arabicFontSize = size;
      await StorageHelper.setFontSize(size);
      notifyListeners();
    }
  }

  /// Çeviri dilini değiştir
  Future<void> setTranslation(String translation) async {
    _selectedTranslation = translation;
    await StorageHelper.setTranslationLanguage(translation);
    notifyListeners();
  }

  /// İnternet bağlantısını kontrol et
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      return _isOnline;
    } catch (e) {
      _isOnline = false;
      return false;
    }
  }

  /// Hata tipine göre kullanıcı dostu mesaj döndür
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return AppStrings.timeoutError;
    } else if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return AppStrings.networkError;
    } else if (errorString.contains('404') || errorString.contains('not found')) {
      return AppStrings.notFoundError;
    } else if (errorString.contains('500') ||
        errorString.contains('server') ||
        errorString.contains('502') ||
        errorString.contains('503')) {
      return AppStrings.serverError;
    } else {
      return AppStrings.unexpectedError;
    }
  }

  /// Sureleri API'den yükle
  Future<void> sureleriYukle() async {
    try {
      _yukleniyor = true;
      _hata = '';
      _retryCount = 0;
      notifyListeners();

      // Önce cache'den kontrol et
      final cachedSureler = await _loadCachedSureler();
      if (cachedSureler.isNotEmpty) {
        _sureler = cachedSureler;
        _yukleniyor = false;
        notifyListeners();

        // Arka planda fresh veri çekmeye devam et
        _loadFreshSurelerInBackground();
        return;
      }

      // İnternet bağlantısını kontrol et
      final hasConnection = await _checkInternetConnection();
      if (!hasConnection) {
        throw Exception(AppStrings.networkError);
      }

      // API'den fresh veri çek
      await _loadFreshSureler();

    } catch (e) {
      await _handleSureLoadError(e);
    }
  }

  /// Fresh sureleri arka planda yükle
  Future<void> _loadFreshSurelerInBackground() async {
    try {
      final hasConnection = await _checkInternetConnection();
      if (hasConnection) {
        final freshSureler = await QuranApiService.getSurahList();
        if (freshSureler.isNotEmpty) {
          _sureler = freshSureler;
          await _cacheSureler(freshSureler);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Background refresh error: $e');
      // Background refresh hatası kullanıcıya gösterilmez
    }
  }

  /// Fresh sureleri yükle
  Future<void> _loadFreshSureler() async {
    final freshSureler = await QuranApiService.getSurahList();

    if (freshSureler.isNotEmpty) {
      _sureler = freshSureler;
      await _cacheSureler(freshSureler);
      _hata = '';
    } else {
      throw Exception('Empty response from API');
    }

    _yukleniyor = false;
    notifyListeners();
  }

  /// Sure yükleme hatasını işle
  Future<void> _handleSureLoadError(dynamic error) async {
    final errorMessage = _getErrorMessage(error);

    // Eğer cache'de veri varsa onu kullan
    if (_sureler.isEmpty) {
      final cachedSureler = await _loadCachedSureler();
      if (cachedSureler.isNotEmpty) {
        _sureler = cachedSureler;
        _hata = '${AppStrings.offlineMode} - $errorMessage';
      } else {
        _hata = errorMessage;
      }
    } else {
      _hata = errorMessage;
    }

    _yukleniyor = false;
    notifyListeners();
  }

  /// Retry mekanizması ile sure yükleme
  Future<void> retrySureleriYukle() async {
    if (_retryCount < AppConstants.maxRetryAttempts) {
      _retryCount++;

      // Exponential backoff
      await Future.delayed(
          Duration(seconds: AppConstants.retryDelay.inSeconds * _retryCount)
      );

      await sureleriYukle();
    } else {
      _hata = 'Maksimum deneme sayısına ulaşıldı. Lütfen daha sonra tekrar deneyin.';
      notifyListeners();
    }
  }

  /// Sureleri cache'e kaydet
  Future<void> _cacheSureler(List<SurahModel> sureler) async {
    try {
      final surahJsonList = sureler.map((s) => s.toJson()).toList();
      await StorageHelper.setCacheData('sureler', {
        'data': surahJsonList,
        'count': sureler.length,
      });
    } catch (e) {
      debugPrint('Cache save error: $e');
    }
  }

  /// Cache'den sureleri yükle
  Future<List<SurahModel>> _loadCachedSureler() async {
    try {
      final cachedData = await StorageHelper.getCacheData('sureler');

      if (cachedData != null && cachedData['data'] != null) {
        final List<dynamic> jsonList = cachedData['data'];
        return jsonList.map((json) => SurahModel.fromAlQuranCloudJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Cache load error: $e');
    }
    return [];
  }

  /// Yer işareti ekle/çıkar
  Future<void> toggleYerIsareti(String ayetKey) async {
    final wasBookmarked = _yerIsaretleri[ayetKey] ?? false;
    _yerIsaretleri[ayetKey] = !wasBookmarked;
    notifyListeners();

    try {
      if (_yerIsaretleri[ayetKey]!) {
        await StorageHelper.addBookmark(ayetKey);
      } else {
        await StorageHelper.removeBookmark(ayetKey);
      }
    } catch (e) {
      // Rollback on error
      _yerIsaretleri[ayetKey] = wasBookmarked;
      notifyListeners();
      debugPrint('Bookmark toggle error: $e');
    }
  }

  /// Yer işaretlerini yükle
  Future<void> loadYerIsaretleri() async {
    try {
      final bookmarks = await StorageHelper.getBookmarks();

      _yerIsaretleri.clear();
      for (final bookmark in bookmarks) {
        _yerIsaretleri[bookmark] = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Bookmarks load error: $e');
    }
  }

  /// Yer işareti kontrolü
  bool isBookmarked(String ayetKey) {
    return _yerIsaretleri[ayetKey] ?? false;
  }

  /// Tüm yer işaretlerini getir
  List<String> getBookmarkedAyahs() {
    return _yerIsaretleri.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  /// Belirli bir sure için yer işaretli ayetleri getir
  List<String> getBookmarkedAyahsForSurah(int surahNumber) {
    return getBookmarkedAyahs()
        .where((key) => key.startsWith('${surahNumber}_'))
        .toList();
  }

  /// Tüm yer işaretlerini temizle
  Future<void> clearAllBookmarks() async {
    try {
      _yerIsaretleri.clear();
      await StorageHelper.setBookmarks([]);
      notifyListeners();
    } catch (e) {
      debugPrint('Clear bookmarks error: $e');
    }
  }

  /// Son okunan pozisyonu kaydet
  Future<void> saveLastReadPosition(int surahNumber, int ayahNumber) async {
    try {
      await StorageHelper.setLastReadPosition(surahNumber, ayahNumber);
      await StorageHelper.incrementReadCount();
    } catch (e) {
      debugPrint('Save last read position error: $e');
    }
  }

  /// Son okunan pozisyonu getir
  Future<Map<String, int>?> getLastReadPosition() async {
    try {
      return await StorageHelper.getLastReadPosition();
    } catch (e) {
      debugPrint('Get last read position error: $e');
      return null;
    }
  }

  /// Belirli bir sureyi detaylı olarak yükle
  Future<List<AyetModel>> loadSurahDetails(int surahNumber) async {
    try {
      // Önce cache'i kontrol et
      final cachedAyahs = await _loadCachedSurahDetails(surahNumber);
      if (cachedAyahs.isNotEmpty) {
        // Arka planda fresh veri yükle
        _loadFreshSurahDetailsInBackground(surahNumber);
        return cachedAyahs;
      }

      // İnternet bağlantısını kontrol et
      final hasConnection = await _checkInternetConnection();
      if (!hasConnection) {
        throw Exception(AppStrings.networkError);
      }

      // API'den yükle
      final ayahs = await QuranApiService.getSurahWithTranslationAndAudio(surahNumber);

      // Cache'e kaydet
      await _cacheSurahDetails(surahNumber, ayahs);

      return ayahs;
    } catch (e) {
      debugPrint('Load surah details error: $e');

      // Cache'den tekrar dene
      final cachedAyahs = await _loadCachedSurahDetails(surahNumber);
      if (cachedAyahs.isNotEmpty) {
        return cachedAyahs;
      }

      throw Exception(_getErrorMessage(e));
    }
  }

  /// Fresh sure detaylarını arka planda yükle
  Future<void> _loadFreshSurahDetailsInBackground(int surahNumber) async {
    try {
      final hasConnection = await _checkInternetConnection();
      if (hasConnection) {
        final freshAyahs = await QuranApiService.getSurahWithTranslationAndAudio(surahNumber);
        await _cacheSurahDetails(surahNumber, freshAyahs);
      }
    } catch (e) {
      debugPrint('Background surah refresh error: $e');
    }
  }

  /// Sure detaylarını cache'e kaydet
  Future<void> _cacheSurahDetails(int surahNumber, List<AyetModel> ayahs) async {
    try {
      final ayahJsonList = ayahs.map((a) => a.toJson()).toList();
      await StorageHelper.setCacheData('surah_$surahNumber', {
        'ayahs': ayahJsonList,
        'count': ayahs.length,
      });
    } catch (e) {
      debugPrint('Cache surah details error: $e');
    }
  }

  /// Cache'den sure detaylarını yükle
  Future<List<AyetModel>> _loadCachedSurahDetails(int surahNumber) async {
    try {
      final cachedData = await StorageHelper.getCacheData('surah_$surahNumber');

      if (cachedData != null && cachedData['ayahs'] != null) {
        final List<dynamic> jsonList = cachedData['ayahs'];
        return jsonList.asMap().entries.map((entry) {
          final index = entry.key;
          final json = entry.value;
          return AyetModel(
            number: index + 1, // Sure içindeki ayet numarası (1'den başlar)
            surahNumber: json['surahNumber'],
            arabic: json['arabic'],
            turkish: json['turkish'],
            audioUrl: json['audioUrl'],
            pageNumber: json['pageNumber'] ?? 1,
            juzNumber: json['juzNumber'] ?? 1,
            globalNumber: json['globalNumber'],
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Load cached surah details error: $e');
    }
    return [];
  }

  /// Cache'i temizle
  Future<void> clearCache() async {
    try {
      await StorageHelper.clearCache();
      _sureler.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Clear cache error: $e');
    }
  }

  /// Storage bilgilerini al
  Future<Map<String, dynamic>> getStorageInfo() async {
    return await StorageHelper.getStorageInfo();
  }

  /// Hata mesajını temizle
  void clearError() {
    _hata = '';
    notifyListeners();
  }

  /// Uygulama istatistiklerini al
  Future<Map<String, dynamic>> getAppStatistics() async {
    try {
      final readCount = await StorageHelper.getReadCount();
      final bookmarksCount = getBookmarkedAyahs().length;
      final lastOpen = await StorageHelper.getLastOpenDate();
      final storageInfo = await getStorageInfo();

      return {
        'readCount': readCount,
        'bookmarksCount': bookmarksCount,
        'lastOpenDate': lastOpen?.toIso8601String(),
        'totalSurahs': _sureler.length,
        'cacheKeys': storageInfo['cacheKeys'],
        'isOnline': _isOnline,
      };
    } catch (e) {
      debugPrint('Get app statistics error: $e');
      return <String, dynamic>{};
    }
  }

  /// Provider'ı temizle
  @override
  void dispose() {
    super.dispose();
  }
}