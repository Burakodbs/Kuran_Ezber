import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
      // Önce HTTP tabanlı kontrol yap
      final httpConnected = await _checkHttpConnection();
      if (httpConnected) {
        _isOnline = true;
        return true;
      }
      
      // HTTP başarısızsa DNS lookup dene
      final hosts = ['8.8.8.8', 'google.com', 'cloudflare.com'];
      
      for (final host in hosts) {
        try {
          final result = await InternetAddress.lookup(host)
              .timeout(const Duration(seconds: 3));
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            _isOnline = true;
            return true;
          }
        } catch (e) {
          debugPrint('DNS lookup failed for $host: $e');
          continue;
        }
      }
      
      _isOnline = false;
      return false;
    } catch (e) {
      debugPrint('Internet connection check failed: $e');
      _isOnline = false;
      return false;
    }
  }

  /// HTTP tabanlı bağlantı kontrolü
  Future<bool> _checkHttpConnection() async {
    try {
      final response = await http.head(
        Uri.parse('https://api.alquran.cloud/v1/meta'),
        headers: {'User-Agent': 'KuranEzber/1.0'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('HTTP connection check failed: $e');
      return false;
    }
  }

  /// Hata tipine göre kullanıcı dostu mesaj döndür
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Debug için tam hata mesajını yazdır
    debugPrint('Error occurred: $error');
    debugPrint('Error string: $errorString');

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
    } else if (errorString.contains('format') ||
        errorString.contains('json') ||
        errorString.contains('parsing')) {
      return 'Veri formatı hatası. Lütfen tekrar deneyin.';
    } else if (errorString.contains('certificate') ||
        errorString.contains('handshake') ||
        errorString.contains('ssl') ||
        errorString.contains('tls')) {
      return 'Güvenlik sertifikası hatası. İnternet bağlantınızı kontrol edin.';
    } else if (errorString.contains('cache') ||
        errorString.contains('storage') ||
        errorString.contains('database')) {
      return 'Önbellek hatası. Lütfen cache\'i temizleyin.';
    } else if (errorString.contains('permission') ||
        errorString.contains('access denied')) {
      return 'Erişim izni hatası. Uygulama ayarlarını kontrol edin.';
    } else if (errorString.contains('host') ||
        errorString.contains('dns') ||
        errorString.contains('resolve')) {
      return 'Sunucu adresine ulaşılamıyor. DNS ayarlarınızı kontrol edin.';
    } else if (errorString.contains('interrupted') ||
        errorString.contains('cancelled')) {
      return 'İşlem iptal edildi. Lütfen tekrar deneyin.';
    } else {
      // Beklenmeyen hata durumunda daha ayrıntılı bilgi ver
      debugPrint('Unexpected error pattern: $errorString');
      return '${AppStrings.unexpectedError}\nHata: ${error.toString().length > 100 ? '${error.toString().substring(0, 100)}...' : error.toString()}';
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

      // Cache boşsa, internet bağlantısını kontrol et
      final hasConnection = await _checkInternetConnection();
      if (!hasConnection) {
        // İnternet yoksa ve cache de boşsa, offline mesajı göster
        _hata = '${AppStrings.networkError}\n\nÖnce internet bağlantısı ile uygulamayı açmanız gerekiyor.';
        _yukleniyor = false;
        notifyListeners();
        return;
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

  /// Sureleri cache'e kaydet (ayet sayısı doğrulaması ile)
  Future<void> _cacheSureler(List<SurahModel> sureler) async {
    try {
      // Ayet sayılarını Diyanet verilerine göre düzelt
      final correctedSureler = sureler.map((s) {
        if (!s.isAyahCountValid) {
          debugPrint('Sure ${s.number} (${s.turkishName}) ayet sayısı düzeltiliyor: ${s.numberOfAyahs} -> ${s.officialAyahCount}');
          return s.corrected;
        }
        return s;
      }).toList();

      final surahJsonList = correctedSureler.map((s) => s.toJson()).toList();
      await StorageHelper.setCacheData('sureler', {
        'data': surahJsonList,
        'count': correctedSureler.length,
        'validationInfo': {
          'correctedCount': correctedSureler.where((s) => !sureler.firstWhere((orig) => orig.number == s.number).isAyahCountValid).length,
          'lastValidated': DateTime.now().toIso8601String(),
        }
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

  /// Cache'i güvenli bir şekilde temizle
  Future<void> clearCacheAndReload() async {
    try {
      await StorageHelper.clearCache();
      _sureler = [];
      _hata = '';
      notifyListeners();
      await sureleriYukle();
    } catch (e) {
      debugPrint('Cache clear error: $e');
      _hata = 'Cache temizleme hatası: ${_getErrorMessage(e)}';
      notifyListeners();
    }
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
        final ayahs = jsonList.asMap().entries.map((entry) {
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
        
        return ayahs;
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