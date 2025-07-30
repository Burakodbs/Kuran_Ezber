class AudioUrlHelper {
  /// Ahmed Taleb Hameed için sure bazlı audio URL'i oluştur
  static String getAhmedTalebHameedUrl(int surahNumber) {
    final surahNumberStr = surahNumber.toString().padLeft(3, '0');
    return 'https://archive.org/download/HaramainHameed/$surahNumberStr.mp3';
  }
  
  /// Standard ayah bazlı audio URL'i oluştur
  static String getStandardAyahUrl(String reciterCode, int globalAyahNumber) {
    return 'https://cdn.islamic.network/quran/audio/128/$reciterCode/$globalAyahNumber.mp3';
  }
  
  /// Reciter tipine göre uygun URL'i getir
  static String getAudioUrl(String reciterCode, int surahNumber, int globalAyahNumber) {
    if (reciterCode == 'ahmed_taleb_hameed') {
      return getAhmedTalebHameedUrl(surahNumber);
    } else {
      return getStandardAyahUrl(reciterCode, globalAyahNumber);
    }
  }
  
  /// Alternatif URL'leri getir
  static List<String> getAlternativeUrls(String reciterCode, int surahNumber, int globalAyahNumber) {
    final urls = <String>[];
    
    if (reciterCode == 'ahmed_taleb_hameed') {
      urls.add(getAhmedTalebHameedUrl(surahNumber));
      // Fallback'ler
      urls.add(getStandardAyahUrl('ar.alafasy', globalAyahNumber));
      urls.add(getStandardAyahUrl('ar.ahmedajamy', globalAyahNumber));
    } else {
      urls.add(getStandardAyahUrl(reciterCode, globalAyahNumber));
      urls.add(getStandardAyahUrl('ar.alafasy', globalAyahNumber));
      urls.add(getAhmedTalebHameedUrl(surahNumber));
    }
    
    return urls;
  }
}