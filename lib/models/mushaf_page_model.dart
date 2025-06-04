import 'ayet_model.dart';

class MushafPageModel {
  final List<AyetModel> ayahs;
  final int pageNumber;
  final String? pageInfo;

  MushafPageModel({
    required this.ayahs,
    this.pageNumber = 1,
    this.pageInfo,
  });

  // Sayfadaki toplam ayet sayısı
  int get totalAyahs => ayahs.length;

  // Sayfadaki farklı sure sayısı
  int get uniqueSurahs => ayahs.map((a) => a.surahNumber).toSet().length;

  // İlk ayet
  AyetModel? get firstAyah => ayahs.isNotEmpty ? ayahs.first : null;

  // Son ayet
  AyetModel? get lastAyah => ayahs.isNotEmpty ? ayahs.last : null;

  // Sayfanın boş olup olmadığı
  bool get isEmpty => ayahs.isEmpty;

  // JSON'dan model oluşturma
  factory MushafPageModel.fromJson(Map<String, dynamic> json) {
    final ayahsList = json['ayahs'] as List<dynamic>? ?? [];

    return MushafPageModel(
      ayahs: ayahsList.map((ayahJson) {
        if (ayahJson is Map<String, dynamic>) {
          // Hangi API formatında olduğunu kontrol et
          if (ayahJson.containsKey('surah')) {
            // AlQuran.cloud formatı
            return AyetModel.fromAlQuranCloudJson(ayahJson, null, null);
          } else {
            // Quran.com formatı
            final chapterId = ayahJson['chapter_id'] ?? 1;
            return AyetModel.fromJson(ayahJson, chapterId);
          }
        }
        // Fallback için boş ayet
        return AyetModel(
          number: 1,
          surahNumber: 1,
          arabic: '',
          turkish: '',
          audioUrl: '',
          globalNumber: 1,
        );
      }).toList(),
      pageNumber: json['pageNumber'] ?? 1,
      pageInfo: json['pageInfo'],
    );
  }

  // Model'i JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      'ayahs': ayahs.map((ayah) => ayah.toJson()).toList(),
      'pageNumber': pageNumber,
      'pageInfo': pageInfo,
      'totalAyahs': totalAyahs,
      'uniqueSurahs': uniqueSurahs,
    };
  }

  // Copy with metodu
  MushafPageModel copyWith({
    List<AyetModel>? ayahs,
    int? pageNumber,
    String? pageInfo,
  }) {
    return MushafPageModel(
      ayahs: ayahs ?? this.ayahs,
      pageNumber: pageNumber ?? this.pageNumber,
      pageInfo: pageInfo ?? this.pageInfo,
    );
  }

  // Equality override
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MushafPageModel && other.pageNumber == pageNumber;
  }

  @override
  int get hashCode => pageNumber.hashCode;

  @override
  String toString() {
    return 'MushafPageModel(pageNumber: $pageNumber, totalAyahs: $totalAyahs, uniqueSurahs: $uniqueSurahs)';
  }
}