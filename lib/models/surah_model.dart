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

  // Türkçe sure isimleri mapping tablosu
  static const Map<String, String> _turkishSurahNames = {
    'Al-Fatiha': 'Fatiha',
    'Al-Baqarah': 'Bakara',
    'Ali \'Imran': 'Ali İmran',
    'An-Nisa': 'Nisa',
    'Al-Ma\'idah': 'Maide',
    'Al-An\'am': 'Enam',
    'Al-A\'raf': 'Araf',
    'Al-Anfal': 'Enfal',
    'At-Tawbah': 'Tevbe',
    'Yunus': 'Yunus',
    'Hud': 'Hud',
    'Yusuf': 'Yusuf',
    'Ar-Ra\'d': 'Rad',
    'Ibrahim': 'İbrahim',
    'Al-Hijr': 'Hicr',
    'An-Nahl': 'Nahl',
    'Al-Isra': 'İsra',
    'Al-Kahf': 'Kehf',
    'Maryam': 'Meryem',
    'Taha': 'Taha',
    'Al-Anbya': 'Enbiya',
    'Al-Hajj': 'Hac',
    'Al-Mu\'minun': 'Müminun',
    'An-Nur': 'Nur',
    'Al-Furqan': 'Furkan',
    'Ash-Shu\'ara': 'Şuara',
    'An-Naml': 'Neml',
    'Al-Qasas': 'Kasas',
    'Al-\'Ankabut': 'Ankebut',
    'Ar-Rum': 'Rum',
    'Luqman': 'Lokman',
    'As-Sajdah': 'Secde',
    'Al-Ahzab': 'Ahzab',
    'Saba': 'Sebe',
    'Fatir': 'Fatır',
    'Ya-Sin': 'Yasin',
    'As-Saffat': 'Saffat',
    'Sad': 'Sad',
    'Az-Zumar': 'Zümer',
    'Ghafir': 'Mümin',
    'Fussilat': 'Fussilet',
    'Ash-Shuraa': 'Şura',
    'Az-Zukhruf': 'Zuhruf',
    'Ad-Dukhan': 'Duhan',
    'Al-Jathiyah': 'Casiye',
    'Al-Ahqaf': 'Ahkaf',
    'Muhammad': 'Muhammed',
    'Al-Fath': 'Fetih',
    'Al-Hujurat': 'Hucurat',
    'Qaf': 'Kaf',
    'Adh-Dhariyat': 'Zariyat',
    'At-Tur': 'Tur',
    'An-Najm': 'Necm',
    'Al-Qamar': 'Kamer',
    'Ar-Rahman': 'Rahman',
    'Al-Waqi\'ah': 'Vakia',
    'Al-Hadid': 'Hadid',
    'Al-Mujadila': 'Mücadele',
    'Al-Hashr': 'Haşr',
    'Al-Mumtahanah': 'Mümtehine',
    'As-Saff': 'Saff',
    'Al-Jumu\'ah': 'Cuma',
    'Al-Munafiqun': 'Münafikun',
    'At-Taghabun': 'Teğabün',
    'At-Talaq': 'Talak',
    'At-Tahrim': 'Tahrim',
    'Al-Mulk': 'Mülk',
    'Al-Qalam': 'Kalem',
    'Al-Haqqah': 'Hakka',
    'Al-Ma\'arij': 'Mearic',
    'Nuh': 'Nuh',
    'Al-Jinn': 'Cin',
    'Al-Muzzammil': 'Müzzemmil',
    'Al-Muddaththir': 'Müddessir',
    'Al-Qiyamah': 'Kıyame',
    'Al-Insan': 'İnsan',
    'Al-Mursalat': 'Mürselat',
    'An-Naba': 'Nebe',
    'An-Nazi\'at': 'Naziat',
    'Abasa': 'Abese',
    'At-Takwir': 'Tekvir',
    'Al-Infitar': 'İnfitar',
    'Al-Mutaffifin': 'Mutaffifin',
    'Al-Inshiqaq': 'İnşikak',
    'Al-Buruj': 'Buruc',
    'At-Tariq': 'Tarık',
    'Al-A\'la': 'Ala',
    'Al-Ghashiyah': 'Gaşiye',
    'Al-Fajr': 'Fecr',
    'Al-Balad': 'Beled',
    'Ash-Shams': 'Şems',
    'Al-Layl': 'Leyl',
    'Ad-Duhaa': 'Duha',
    'Ash-Sharh': 'İnşirah',
    'At-Tin': 'Tin',
    'Al-\'Alaq': 'Alak',
    'Al-Qadr': 'Kadir',
    'Al-Bayyinah': 'Beyyine',
    'Az-Zalzalah': 'Zilzal',
    'Al-\'Adiyat': 'Adiyat',
    'Al-Qari\'ah': 'Karia',
    'At-Takathur': 'Tekasür',
    'Al-\'Asr': 'Asr',
    'Al-Humazah': 'Hümeze',
    'Al-Fil': 'Fil',
    'Quraysh': 'Kureyş',
    'Al-Ma\'un': 'Maun',
    'Al-Kawthar': 'Kevser',
    'Al-Kafirun': 'Kafirun',
    'An-Nasr': 'Nasr',
    'Al-Masad': 'Mesed',
    'Al-Ikhlas': 'İhlas',
    'Al-Falaq': 'Felak',
    'An-Nas': 'Nas',
  };

  // Türkçe sure adını al
  String get turkishName {
    return _turkishSurahNames[englishName] ?? englishName;
  }

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
    return 'SurahModel(number: $number, turkishName: $turkishName, numberOfAyahs: $numberOfAyahs)';
  }
}