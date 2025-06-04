class SurahModel {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  SurahModel({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  // Quran.com API için (eski)
  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      number: json['id'] ?? json['chapter_number'] ?? 0,
      name: json['name_arabic'] ?? '',
      englishName: json['name_simple'] ?? '',
      englishNameTranslation: json['translated_name']?['name'] ?? '',
      numberOfAyahs: json['verses_count'] ?? 0,
      revelationType: json['revelation_place'] ?? '',
    );
  }

  // AlQuran.cloud API için (yeni)
  factory SurahModel.fromAlQuranCloudJson(Map<String, dynamic> json) {
    return SurahModel(
      number: json['number'] ?? 0,
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      englishNameTranslation: json['englishNameTranslation'] ?? '',
      numberOfAyahs: json['numberOfAyahs'] ?? 0,
      revelationType: json['revelationType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
      'englishName': englishName,
      'englishNameTranslation': englishNameTranslation,
      'numberOfAyahs': numberOfAyahs,
      'revelationType': revelationType,
    };
  }

  // Copy with metodu
  SurahModel copyWith({
    int? number,
    String? name,
    String? englishName,
    String? englishNameTranslation,
    int? numberOfAyahs,
    String? revelationType,
  }) {
    return SurahModel(
      number: number ?? this.number,
      name: name ?? this.name,
      englishName: englishName ?? this.englishName,
      englishNameTranslation: englishNameTranslation ?? this.englishNameTranslation,
      numberOfAyahs: numberOfAyahs ?? this.numberOfAyahs,
      revelationType: revelationType ?? this.revelationType,
    );
  }

  // Equality override
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SurahModel && other.number == number;
  }

  @override
  int get hashCode => number.hashCode;

  @override
  String toString() {
    return 'SurahModel(number: $number, englishName: $englishName, numberOfAyahs: $numberOfAyahs)';
  }
}