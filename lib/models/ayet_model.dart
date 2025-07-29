import 'package:http/http.dart' as http;

class AyetModel {
  final int number; // Sure içindeki ayet numarası (1'den başlar)
  final int surahNumber;
  final String arabic;
  final String turkish;
  final String audioUrl;
  final int pageNumber;
  final int juzNumber;
  final int globalNumber; // 1-6236 arası mutlak ayet numarası

  AyetModel({
    required this.number,
    required this.surahNumber,
    required this.arabic,
    required this.turkish,
    required this.audioUrl,
    this.pageNumber = 1,
    this.juzNumber = 1,
    required this.globalNumber,
  });

  // Bookmark key için yardımcı getter
  String get bookmarkKey => '${surahNumber}_$number';

  // AlQuran.cloud API için factory constructor (geri uyumluluk için)
  factory AyetModel.fromAlQuranCloudJson(
      Map<String, dynamic> arabicJson,
      Map<String, dynamic>? turkishJson,
      Map<String, dynamic>? audioJson
      ) {
    final surahNumber = arabicJson['surah']?['number'] ?? 1;
    final ayahNumber = arabicJson['number'] ?? 1;
    final globalNumber = arabicJson['numberInQuran'] ?? _calculateGlobalNumber(surahNumber, ayahNumber);

    // Audio URL'sini al
    String audioUrl = '';
    if (audioJson != null) {
      // API'den gelen audio URL'sini kullan
      if (audioJson['audioSecondary'] != null && audioJson['audioSecondary'].isNotEmpty) {
        audioUrl = audioJson['audioSecondary'][0];
      } else if (audioJson['audio'] != null) {
        audioUrl = audioJson['audio'];
      }
    }

    // Eğer audio URL yoksa, global number ile oluştur
    if (audioUrl.isEmpty) {
      audioUrl = 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalNumber.mp3';
    }

    return AyetModel(
      number: ayahNumber,
      surahNumber: surahNumber,
      arabic: arabicJson['text'] ?? '',
      turkish: turkishJson?['text'] ?? '',
      pageNumber: arabicJson['page'] ?? 1,
      juzNumber: arabicJson['juz'] ?? 1,
      globalNumber: globalNumber,
      audioUrl: audioUrl,
    );
  }

  // AlQuran.cloud API için factory constructor (per-surah numbering ile)
  factory AyetModel.fromAlQuranCloudJsonWithIndex(
      Map<String, dynamic> arabicJson,
      Map<String, dynamic>? turkishJson,
      Map<String, dynamic>? audioJson,
      int surahSpecificNumber
      ) {
    final surahNumber = arabicJson['surah']?['number'] ?? 1;
    final globalNumber = arabicJson['numberInQuran'] ?? arabicJson['number'] ?? 1;

    // Audio URL'sini al
    String audioUrl = '';
    if (audioJson != null) {
      // API'den gelen audio URL'sini kullan
      if (audioJson['audioSecondary'] != null && audioJson['audioSecondary'].isNotEmpty) {
        audioUrl = audioJson['audioSecondary'][0];
      } else if (audioJson['audio'] != null) {
        audioUrl = audioJson['audio'];
      }
    }

    // Eğer audio URL yoksa, global number ile oluştur
    if (audioUrl.isEmpty) {
      audioUrl = 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalNumber.mp3';
    }

    return AyetModel(
      number: surahSpecificNumber, // Sure içindeki ayet numarası (1'den başlar)
      surahNumber: surahNumber,
      arabic: arabicJson['text'] ?? '',
      turkish: turkishJson?['text'] ?? '',
      pageNumber: arabicJson['page'] ?? 1,
      juzNumber: arabicJson['juz'] ?? 1,
      globalNumber: globalNumber,
      audioUrl: audioUrl,
    );
  }

  // Global ayet numarasını hesapla
  static int _calculateGlobalNumber(int surahNumber, int ayahNumber) {
    const surahAyahCounts = [
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

    int totalPreviousAyahs = 0;
    for (int i = 0; i < surahNumber - 1 && i < surahAyahCounts.length; i++) {
      totalPreviousAyahs += surahAyahCounts[i];
    }

    return totalPreviousAyahs + ayahNumber;
  }

  // Quran.com API için factory constructor (eski - geri uyumluluk için)
  factory AyetModel.fromJson(Map<String, dynamic> json, int chapterId) {
    String translation = '';
    if (json['translations'] != null &&
        json['translations'].isNotEmpty &&
        json['translations'][0]['text'] != null) {
      translation = json['translations'][0]['text'];
    }

    final verseNumber = json['verse_number'] ?? 0;
    final globalNumber = _calculateGlobalNumber(chapterId, verseNumber);

    return AyetModel(
      number: verseNumber,
      surahNumber: chapterId,
      arabic: json['text_uthmani'] ?? '',
      turkish: translation,
      globalNumber: globalNumber,
      audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalNumber.mp3',
    );
  }

  // Alternatif audio URL'lerini getir
  List<String> get alternativeAudioUrls => [
    'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalNumber.mp3',
    'https://cdn.islamic.network/quran/audio/64/ar.alafasy/$globalNumber.mp3',
    'https://cdn.alquran.cloud/media/audio/ayah/ar.alafasy/$globalNumber',
    'https://everyayah.com/data/AlAfasy_128kbps/$globalNumber.mp3',
    'https://cdn.islamic.network/quran/audio/128/ar.abdurrahmaansudais/$globalNumber.mp3',
    'https://cdn.islamic.network/quran/audio/128/ar.hudhaify/$globalNumber.mp3',
    'https://audio.qurancdn.com/ar.alafasy/$globalNumber.mp3',
  ];

  // Model'i JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'surahNumber': surahNumber,
      'arabic': arabic,
      'turkish': turkish,
      'audioUrl': audioUrl,
      'pageNumber': pageNumber,
      'juzNumber': juzNumber,
      'globalNumber': globalNumber,
    };
  }

  // Copy with metodu
  AyetModel copyWith({
    int? number,
    int? surahNumber,
    String? arabic,
    String? turkish,
    String? audioUrl,
    int? pageNumber,
    int? juzNumber,
    int? globalNumber,
  }) {
    return AyetModel(
      number: number ?? this.number,
      surahNumber: surahNumber ?? this.surahNumber,
      arabic: arabic ?? this.arabic,
      turkish: turkish ?? this.turkish,
      audioUrl: audioUrl ?? this.audioUrl,
      pageNumber: pageNumber ?? this.pageNumber,
      juzNumber: juzNumber ?? this.juzNumber,
      globalNumber: globalNumber ?? this.globalNumber,
    );
  }

  // Audio URL'sinin çalışıp çalışmadığını kontrol et
  Future<bool> validateAudioUrl() async {
    try {
      final response = await http.head(Uri.parse(audioUrl))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Çalışan bir audio URL'si bul
  Future<String?> findWorkingAudioUrl() async {
    // Önce mevcut URL'yi test et
    if (await validateAudioUrl()) {
      return audioUrl;
    }

    // Alternatif URL'leri dene
    for (final url in alternativeAudioUrls) {
      try {
        final response = await http.head(Uri.parse(url))
            .timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          return url;
        }
      } catch (e) {
        continue;
      }
    }

    return null; // Hiçbiri çalışmıyorsa null döndür
  }

  // Get all possible audio URLs for this ayah
  List<String> getAllAudioUrls() {
    final urls = <String>[audioUrl];
    urls.addAll(alternativeAudioUrls.where((url) => url != audioUrl));
    return urls;
  }

}