import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ayet_model.dart';
import '../models/surah_model.dart';
import '../models/mushaf_page_model.dart';

class QuranApiService {
  static const String _baseUrl = 'http://api.alquran.cloud/v1';
  static const String _turkishEdition = 'tr.diyanet';
  static const String _arabicEdition = 'quran-uthmani';
  static const String _audioEdition = 'ar.alafasy';

  /// Tüm surelerin listesini getirir
  static Future<List<SurahModel>> getSurahList() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/surah'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 200 && data['data'] != null) {
          final surahs = data['data'] as List;
          return surahs.map((json) => SurahModel.fromAlQuranCloudJson(json)).toList();
        } else {
          throw Exception('API yanıtında hata: ${data['status']}');
        }
      } else {
        throw Exception('Sûre listesi yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ağ hatası: $e');
    }
  }

  /// Belirli bir sureyi Arapça, Türkçe ve Audio ile birlikte getirir
  static Future<List<AyetModel>> getSurahWithTranslationAndAudio(int surahNumber) async {
    try {
      // Önce Arapça ve Türkçe edisyonları al
      final textResponse = await http.get(
        Uri.parse('$_baseUrl/surah/$surahNumber/editions/$_arabicEdition,$_turkishEdition'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (textResponse.statusCode != 200) {
        throw Exception('Sure metni yüklenemedi: ${textResponse.statusCode}');
      }

      final textData = json.decode(textResponse.body);

      if (textData['code'] != 200 || textData['data'] == null) {
        throw Exception('API yanıtında hata: ${textData['status']}');
      }

      // Şimdi audio edisyonunu al
      final audioResponse = await http.get(
        Uri.parse('$_baseUrl/surah/$surahNumber/$_audioEdition'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      List<Map<String, dynamic>> audioAyahs = [];
      if (audioResponse.statusCode == 200) {
        final audioData = json.decode(audioResponse.body);
        if (audioData['code'] == 200 && audioData['data'] != null) {
          audioAyahs = List<Map<String, dynamic>>.from(audioData['data']['ayahs']);
        }
      }

      // Text edisyonlarını işle
      final editions = textData['data'] as List;

      final arabicEdition = editions.firstWhere(
            (e) => e['identifier'] == _arabicEdition,
        orElse: () => editions.first,
      );

      final turkishEdition = editions.where(
            (e) => e['identifier'] == _turkishEdition,
      ).isNotEmpty ? editions.firstWhere(
            (e) => e['identifier'] == _turkishEdition,
      ) : null;

      final arabicAyahs = arabicEdition['ayahs'] as List;
      final turkishAyahs = turkishEdition?['ayahs'] as List?;

      return arabicAyahs.asMap().entries.map((entry) {
        final index = entry.key;
        final arabicAyah = entry.value;
        
        // Eşleşen Türkçe ayeti bul
        Map<String, dynamic>? matchingTurkish;
        if (turkishAyahs != null) {
          final turkishMatches = turkishAyahs.where(
                (turkishAyah) => turkishAyah['number'] == arabicAyah['number'],
          );
          matchingTurkish = turkishMatches.isNotEmpty ? turkishMatches.first : null;
        }

        // Eşleşen audio ayeti bul
        Map<String, dynamic>? matchingAudio;
        if (audioAyahs.isNotEmpty) {
          final audioMatches = audioAyahs.where(
                (audioAyah) => audioAyah['number'] == arabicAyah['number'],
          );
          matchingAudio = audioMatches.isNotEmpty ? audioMatches.first : null;
        }

        return AyetModel.fromAlQuranCloudJsonWithIndex(
            arabicAyah,
            matchingTurkish,
            matchingAudio,
            index + 1 // Sure içindeki ayet numarası (1'den başlar)
        );
      }).toList();
    } catch (e) {
      throw Exception('Sure yükleme hatası: $e');
    }
  }

  /// Belirli bir surenin sayfa numaralarını getirir
  static Future<List<int>> getSurahPageNumbers(int surahNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/surah/$surahNumber/editions/$_arabicEdition'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 200 && data['data'] != null) {
          final surahData = data['data'][0];
          final ayahs = surahData['ayahs'] as List;

          if (ayahs.isNotEmpty) {
            final firstPage = ayahs.first['page'] as int? ?? 1;
            final lastPage = ayahs.last['page'] as int? ?? 1;

            return List.generate(
              lastPage - firstPage + 1,
                  (index) => firstPage + index,
            );
          }
        }
      }

      return [1];
    } catch (e) {
      return [1];
    }
  }

  /// Belirli bir sayfadaki ayetleri getirir
  static Future<MushafPageModel> getMushafPage(int pageNumber) async {
    try {
      int estimatedJuz = ((pageNumber - 1) ~/ 20) + 1;
      if (estimatedJuz > 30) estimatedJuz = 30;

      final response = await http.get(
        Uri.parse('$_baseUrl/juz/$estimatedJuz/editions/$_arabicEdition,$_turkishEdition'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 200 && data['data'] != null) {
          final editions = data['data'] as List;

          final arabicEdition = editions.firstWhere(
                (e) => e['identifier'] == _arabicEdition,
            orElse: () => editions.first,
          );

          final turkishEdition = editions.where(
                (e) => e['identifier'] == _turkishEdition,
          ).isNotEmpty ? editions.firstWhere(
                (e) => e['identifier'] == _turkishEdition,
          ) : null;

          final arabicAyahs = arabicEdition['ayahs'] as List;
          final turkishAyahs = turkishEdition?['ayahs'] as List?;

          final pageAyahs = arabicAyahs.where((ayah) {
            return ayah['page'] == pageNumber;
          }).toList();

          return MushafPageModel(
            ayahs: pageAyahs.asMap().entries.map((entry) {
              final index = entry.key;
              final arabicAyah = entry.value;
              
              Map<String, dynamic>? matchingTurkish;
              if (turkishAyahs != null) {
                final turkishMatches = turkishAyahs.where(
                      (turkishAyah) =>
                  turkishAyah['number'] == arabicAyah['number'] &&
                      turkishAyah['surah']['number'] == arabicAyah['surah']['number'],
                );
                matchingTurkish = turkishMatches.isNotEmpty ? turkishMatches.first : null;
              }

              // Sayfa içindeki ayetlerde sure içindeki pozisyonu bul
              final surahNumber = arabicAyah['surah']['number'];
              final globalAyahNumber = arabicAyah['number'];
              
              // Sure başlangıç pozisyonunu hesapla
              int surahSpecificNumber = 1;
              if (surahNumber > 1) {
                int previousAyahs = 0;
                for (int i = 1; i < surahNumber; i++) {
                  previousAyahs += _getSurahAyahCount(i);
                }
                surahSpecificNumber = globalAyahNumber - previousAyahs;
              } else {
                surahSpecificNumber = globalAyahNumber;
              }

              return AyetModel.fromAlQuranCloudJsonWithIndex(
                arabicAyah, 
                matchingTurkish, 
                null,
                surahSpecificNumber
              );
            }).toList(),
            pageNumber: pageNumber,
          );
        }
      }

      throw Exception('Sayfa $pageNumber yüklenemedi: ${response.statusCode}');
    } catch (e) {
      throw Exception('Sayfa yükleme hatası: $e');
    }
  }

  /// Belirli bir ayet için audio URL'sini al
  static Future<String?> getAyahAudioUrl(int surahNumber, int ayahNumber) async {
    try {
      final globalAyahNumber = _calculateGlobalAyahNumber(surahNumber, ayahNumber);

      final response = await http.get(
        Uri.parse('$_baseUrl/ayah/$globalAyahNumber/$_audioEdition'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          final ayahData = data['data'];
          if (ayahData['audioSecondary'] != null &&
              ayahData['audioSecondary'].isNotEmpty) {
            return ayahData['audioSecondary'][0];
          } else if (ayahData['audio'] != null) {
            return ayahData['audio'];
          }
        }
      }

      return 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalAyahNumber.mp3';
    } catch (e) {
      return null;
    }
  }

  /// Global ayet numarasını hesapla (1-6236)
  static int _calculateGlobalAyahNumber(int surahNumber, int ayahNumber) {
    int totalAyahs = 0;

    for (int i = 1; i < surahNumber; i++) {
      totalAyahs += _getSurahAyahCount(i);
    }

    return totalAyahs + ayahNumber;
  }

  /// Sure ayet sayılarının listesi (1-114)
  static int _getSurahAyahCount(int surahNumber) {
    const ayahCounts = [
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

    if (surahNumber >= 1 && surahNumber <= 114) {
      return ayahCounts[surahNumber - 1];
    }
    return 0;
  }

  /// Alternatif audio URL'leri
  static List<String> getAlternativeAudioUrls(int globalAyahNumber) {
    return [
      'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalAyahNumber.mp3',
      'https://cdn.islamic.network/quran/audio/64/ar.alafasy/$globalAyahNumber.mp3',
      'https://cdn.alquran.cloud/media/audio/ayah/ar.alafasy/$globalAyahNumber',
      'https://cdn.islamic.network/quran/audio/128/ar.abdurrahmaansudais/$globalAyahNumber.mp3',
    ];
  }

  /// Audio URL'sinin çalışıp çalışmadığını test et
  static Future<bool> testAudioUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Mevcut tüm çeviri edisyonlarını listeler
  static Future<List<Map<String, dynamic>>> getAvailableTranslations() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/edition/type/translation'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 200 && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}