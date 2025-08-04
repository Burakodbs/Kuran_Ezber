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

  // Resmi Diyanet İşleri Başkanlığı sure isimleri ve ayet sayıları
  static const Map<String, String> _turkishSurahNames = {
    'Al-Faatiha': 'Fâtiha',
    'Al-Baqara': 'Bakara',
    'Aal-i-Imraan': 'Âl-i İmrân',
    'An-Nisaa': 'Nisâ',
    'Al-Maaida': 'Mâide',
    'Al-An\'aam': 'En\'âm',
    'Al-A\'raaf': 'A\'râf',
    'Al-Anfaal': 'Enfâl',
    'At-Tawba': 'Tevbe',
    'Yunus': 'Yunus',
    'Hud': 'Hûd',
    'Yusuf': 'Yusuf',
    'Ar-Ra\'d': 'Ra\'d',
    'Ibrahim': 'İbrahim',
    'Al-Hijr': 'Hicr',
    'An-Nahl': 'Nahl',
    'Al-Israa': 'İsrâ',
    'Al-Kahf': 'Kehf',
    'Maryam': 'Meryem',
    'Taa-Haa': 'Tâ-Hâ',
    'Al-Anbiyaa': 'Enbiyâ',
    'Al-Hajj': 'Hac',
    'Al-Muminoon': 'Mü\'minûn',
    'An-Noor': 'Nûr',
    'Al-Furqaan': 'Furkan',
    'Ash-Shu\'araa': 'Şuarâ',
    'An-Naml': 'Neml',
    'Al-Qasas': 'Kasas',
    'Al-Ankaboot': 'Ankebût',
    'Ar-Room': 'Rûm',
    'Luqman': 'Lokman',
    'As-Sajda': 'Secde',
    'Al-Ahzaab': 'Ahzâb',
    'Saba': 'Sebe\'',
    'Faatir': 'Fâtır',
    'Yaseen': 'Yâsin',
    'As-Saaffaat': 'Sâffât',
    'Saad': 'Sâd',
    'Az-Zumar': 'Zümer',
    'Ghafir': 'Mü\'min',
    'Fussilat': 'Fussilet',
    'Ash-Shura': 'Şûrâ',
    'Az-Zukhruf': 'Zuhruf',
    'Ad-Dukhaan': 'Duhân',
    'Al-Jaathiya': 'Câsiye',
    'Al-Ahqaf': 'Ahkaf',
    'Muhammad': 'Muhammed',
    'Al-Fath': 'Fetih',
    'Al-Hujuraat': 'Hucurât',
    'Qaaf': 'Kaf',
    'Adh-Dhaariyat': 'Zâriyât',
    'At-Tur': 'Tûr',
    'An-Najm': 'Necm',
    'Al-Qamar': 'Kamer',
    'Ar-Rahmaan': 'Rahmân',
    'Al-Waaqia': 'Vâkıa',
    'Al-Hadid': 'Hadid',
    'Al-Mujaadila': 'Mücâdele',
    'Al-Hashr': 'Haşr',
    'Al-Mumtahana': 'Mümtehine',
    'As-Saff': 'Saf',
    'Al-Jumu\'a': 'Cum\'a',
    'Al-Munaafiqoon': 'Münâfikûn',
    'At-Taghaabun': 'Teğabün',
    'At-Talaaq': 'Talâk',
    'At-Tahrim': 'Tahrim',
    'Al-Mulk': 'Mülk',
    'Al-Qalam': 'Kalem',
    'Al-Haaqqa': 'Hâkka',
    'Al-Ma\'aarij': 'Meâric',
    'Nooh': 'Nuh',
    'Al-Jinn': 'Cin',
    'Al-Muzzammil': 'Müzzemmil',
    'Al-Muddaththir': 'Müddessir',
    'Al-Qiyaama': 'Kıyamet',
    'Al-Insaan': 'İnsan',
    'Al-Mursalaat': 'Mürselât',
    'An-Naba': 'Nebe\'',
    'An-Naazi\'aat': 'Nâziât',
    'Abasa': 'Abese',
    'At-Takwir': 'Tekvir',
    'Al-Infitaar': 'İnfitâr',
    'Al-Mutaffifin': 'Mutaffifin',
    'Al-Inshiqaaq': 'İnşikak',
    'Al-Burooj': 'Bürûc',
    'At-Taariq': 'Târık',
    'Al-A\'laa': 'A\'lâ',
    'Al-Ghaashiya': 'Gâşiye',
    'Al-Fajr': 'Fecr',
    'Al-Balad': 'Beled',
    'Ash-Shams': 'Şems',
    'Al-Lail': 'Leyl',
    'Ad-Dhuhaa': 'Duhâ',
    'Ash-Sharh': 'İnşirâh',
    'At-Tin': 'Tin',
    'Al-Alaq': 'Alak',
    'Al-Qadr': 'Kadir',
    'Al-Bayyina': 'Beyyine',
    'Az-Zalzala': 'Zilzâl',
    'Al-Aadiyaat': 'Âdiyât',
    'Al-Qaari\'a': 'Kâria',
    'At-Takaathur': 'Tekâsür',
    'Al-Asr': 'Asr',
    'Al-Humaza': 'Hümeze',
    'Al-Fil': 'Fil',
    'Quraish': 'Kureyş',
    'Al-Maa\'oon': 'Mâûn',
    'Al-Kawthar': 'Kevser',
    'Al-Kaafiroon': 'Kâfirûn',
    'An-Nasr': 'Nasr',
    'Al-Masad': 'Tebbet',
    'Al-Ikhlaas': 'İhlâs',
    'Al-Falaq': 'Felâk',
    'An-Naas': 'Nâs',
  };

  // Resmi ayet sayıları (Diyanet İşleri Başkanlığı)
  static const Map<int, int> _officialAyahCounts = {
    1: 7, 2: 286, 3: 200, 4: 176, 5: 120, 6: 165, 7: 206, 8: 75, 9: 129, 10: 109,
    11: 123, 12: 111, 13: 43, 14: 52, 15: 99, 16: 128, 17: 111, 18: 110, 19: 98, 20: 135,
    21: 112, 22: 78, 23: 118, 24: 64, 25: 77, 26: 227, 27: 93, 28: 88, 29: 69, 30: 60,
    31: 34, 32: 30, 33: 73, 34: 54, 35: 45, 36: 83, 37: 182, 38: 88, 39: 75, 40: 85,
    41: 54, 42: 53, 43: 89, 44: 59, 45: 37, 46: 35, 47: 38, 48: 29, 49: 18, 50: 45,
    51: 60, 52: 49, 53: 62, 54: 55, 55: 78, 56: 96, 57: 29, 58: 22, 59: 24, 60: 13,
    61: 14, 62: 11, 63: 11, 64: 18, 65: 12, 66: 12, 67: 30, 68: 52, 69: 52, 70: 44,
    71: 28, 72: 28, 73: 20, 74: 56, 75: 40, 76: 31, 77: 50, 78: 40, 79: 46, 80: 42,
    81: 29, 82: 19, 83: 36, 84: 25, 85: 22, 86: 17, 87: 19, 88: 26, 89: 30, 90: 20,
    91: 15, 92: 21, 93: 11, 94: 8, 95: 8, 96: 19, 97: 5, 98: 8, 99: 8, 100: 11,
    101: 11, 102: 8, 103: 3, 104: 9, 105: 5, 106: 4, 107: 7, 108: 3, 109: 6, 110: 3,
    111: 5, 112: 4, 113: 5, 114: 6
  };

  // Türkçe sure adını al
  String get turkishName {
    return _turkishSurahNames[englishName] ?? englishName;
  }

  // Resmi ayet sayısını al
  int get officialAyahCount {
    return _officialAyahCounts[number] ?? numberOfAyahs;
  }

  // Ayet sayısını doğrula (API'den gelen sayı ile resmi sayı karşılaştırması)
  bool get isAyahCountValid {
    final official = _officialAyahCounts[number];
    return official == null || official == numberOfAyahs;
  }

  // Ayet sayısı uyarısı mesajı
  String? get ayahCountWarning {
    if (!isAyahCountValid) {
      final official = _officialAyahCounts[number];
      return 'Uyarı: API\'den gelen ayet sayısı ($numberOfAyahs) resmi sayıdan ($official) farklı.';
    }
    return null;
  }

  // Resmi Diyanet verilerine göre düzeltilmiş model
  SurahModel get corrected {
    return copyWith(
      numberOfAyahs: officialAyahCount,
    );
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