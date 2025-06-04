import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah_model.dart';
import '../models/ayet_model.dart';
import '../services/quran_api_service.dart';

class KuranProvider with ChangeNotifier {
  List<SurahModel> _sureler = [];
  bool _yukleniyor = true;
  String _hata = '';
  final Map<String, bool> _yerIsaretleri = {};
  bool _translationGoster = false;
  double _arabicFontSize = 22.0;
  String _selectedTranslation = 'tr.diyanet';
  bool _darkMode = false;

  // Getters
  List<SurahModel> get sureler => _sureler;
  bool get yukleniyor => _yukleniyor;
  String get hata => _hata;
  bool get translationGoster => _translationGoster;
  double get arabicFontSize => _arabicFontSize;
  String get selectedTranslation => _selectedTranslation;
  bool get darkMode => _darkMode;

  KuranProvider() {
    _loadSettings();
    sureleriYukle();
    loadYerIsaretleri();
  }

  /// Ayarları SharedPreferences'tan yükle
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _translationGoster = prefs.getBool('translation_goster') ?? false;
      _arabicFontSize = prefs.getDouble('arabic_font_size') ?? 22.0;
      _selectedTranslation = prefs.getString('selected_translation') ?? 'tr.diyanet';
      _darkMode = prefs.getBool('dark_mode') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Ayarlar yüklenirken hata: $e');
    }
  }

  /// Ayarları SharedPreferences'a kaydet
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('translation_goster', _translationGoster);
      await prefs.setDouble('arabic_font_size', _arabicFontSize);
      await prefs.setString('selected_translation', _selectedTranslation);
      await prefs.setBool('dark_mode', _darkMode);
    } catch (e) {
      debugPrint('Ayarlar kaydedilirken hata: $e');
    }
  }

  /// Çeviri gösterimi açık/kapalı
  Future<void> toggleTranslation() async {
    _translationGoster = !_translationGoster;
    await _saveSettings();
    notifyListeners();
  }

  /// Dark mode açık/kapalı
  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    await _saveSettings();
    notifyListeners();
  }

  /// Arapça font boyutunu ayarla
  Future<void> setArabicFontSize(double size) async {
    if (size >= 16.0 && size <= 32.0) {
      _arabicFontSize = size;
      await _saveSettings();
      notifyListeners();
    }
  }

  /// Çeviri dilini değiştir
  Future<void> setTranslation(String translation) async {
    _selectedTranslation = translation;
    await _saveSettings();
    notifyListeners();
  }

  /// Sureleri API'den yükle
  Future<void> sureleriYukle() async {
    try {
      _yukleniyor = true;
      _hata = '';
      notifyListeners();

      // Önce cache'den kontrol et
      final cachedSureler = await _loadCachedSureler();
      if (cachedSureler.isNotEmpty) {
        _sureler = cachedSureler;
        _yukleniyor = false;
        notifyListeners();
      }

      // API'den fresh veri çek
      final freshSureler = await QuranApiService.getSurahList();

      if (freshSureler.isNotEmpty) {
        _sureler = freshSureler;
        await _cacheSureler(freshSureler);
      }

      _hata = '';
    } catch (e) {
      _hata = 'Sure listesi yüklenirken hata: ${e.toString()}';
      debugPrint(_hata);

      // Eğer cache'de veri varsa onu kullan
      if (_sureler.isEmpty) {
        final cachedSureler = await _loadCachedSureler();
        if (cachedSureler.isNotEmpty) {
          _sureler = cachedSureler;
          _hata = 'Çevrimdışı veriler kullanılıyor';
        }
      }
    } finally {
      _yukleniyor = false;
      notifyListeners();
    }
  }

  /// Sureleri cache'e kaydet
  Future<void> _cacheSureler(List<SurahModel> sureler) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final surahJsonList = sureler.map((s) => s.toJson()).toList();
      await prefs.setString('cached_sureler', jsonEncode(surahJsonList));
      await prefs.setInt('cache_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Cache kaydetme hatası: $e');
    }
  }

  /// Cache'den sureleri yükle
  Future<List<SurahModel>> _loadCachedSureler() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_sureler');
      final cacheTimestamp = prefs.getInt('cache_timestamp') ?? 0;

      // Cache 24 saatten eskiyse geçersiz say
      final now = DateTime.now().millisecondsSinceEpoch;
      final dayInMillis = 24 * 60 * 60 * 1000;

      if (cachedData != null && (now - cacheTimestamp) < dayInMillis) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList.map((json) => SurahModel.fromAlQuranCloudJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Cache yükleme hatası: $e');
    }
    return [];
  }

  /// Yer işareti ekle/çıkar
  Future<void> toggleYerIsareti(String ayetKey) async {
    _yerIsaretleri[ayetKey] = !(_yerIsaretleri[ayetKey] ?? false);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('yer_isareti_$ayetKey', _yerIsaretleri[ayetKey]!);
    } catch (e) {
      debugPrint('Yer işareti kaydetme hatası: $e');
    }
  }

  /// Yer işaretlerini yükle
  Future<void> loadYerIsaretleri() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      _yerIsaretleri.clear();
      for (var key in keys) {
        if (key.startsWith('yer_isareti_')) {
          final ayetKey = key.replaceFirst('yer_isareti_', '');
          _yerIsaretleri[ayetKey] = prefs.getBool(key) ?? false;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Yer işaretleri yükleme hatası: $e');
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

  /// Son okunan pozisyonu kaydet
  Future<void> saveLastReadPosition(int surahNumber, int ayahNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_read_surah', surahNumber);
      await prefs.setInt('last_read_ayah', ayahNumber);
      await prefs.setInt('last_read_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Son okuma pozisyonu kaydetme hatası: $e');
    }
  }

  /// Son okunan pozisyonu getir
  Future<Map<String, int>?> getLastReadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final surahNumber = prefs.getInt('last_read_surah');
      final ayahNumber = prefs.getInt('last_read_ayah');

      if (surahNumber != null && ayahNumber != null) {
        return {
          'surahNumber': surahNumber,
          'ayahNumber': ayahNumber,
        };
      }
    } catch (e) {
      debugPrint('Son okuma pozisyonu yükleme hatası: $e');
    }
    return null;
  }

  /// Belirli bir sureyi detaylı olarak yükle
  Future<List<AyetModel>> loadSurahDetails(int surahNumber) async {
    try {
      return await QuranApiService.getSurahWithTranslationAndAudio(surahNumber);
    } catch (e) {
      debugPrint('Sure detayları yükleme hatası: $e');
      throw Exception('Sure detayları yüklenemedi: $e');
    }
  }

  /// Hata mesajını temizle
  void clearError() {
    _hata = '';
    notifyListeners();
  }

  /// Provider'ı temizle
  @override
  void dispose() {
    super.dispose();
  }
}