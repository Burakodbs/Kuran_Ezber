import 'package:flutter/material.dart';

class AppColors {
  // Ana Renkler
  static const Color primary = Color(0xFF1B4F3A);
  static const Color primaryDark = Color(0xFF0D2E21);
  static const Color secondary = Color(0xFF2E7D32);
  static const Color accent = Color(0xFF4CAF50);

  // Açık Tema Renkleri
  static const Color lightBackground = Color(0xFFF8F8F8);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;
  static const Color lightText = Colors.black87;
  static const Color lightTextSecondary = Colors.black54;

  // Koyu Tema Renkleri
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2D2D2D);
  static const Color darkText = Colors.white;
  static const Color darkTextSecondary = Colors.white70;

  // Durum Renkleri
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFEB3B);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Özel Renkler
  static const Color audioPlaying = Color(0xFF4CAF50);
  static const Color audioPlayingBackground = Color(0xFF4CAF50);
  static const Color selectedAyah = Color(0xFF1B4F3A);
  static const Color hoveredAyah = Color(0xFFFFEB3B);
  static const Color bookmarked = Color(0xFFF44336);

  // Gradient Renkleri
  static const List<Color> primaryGradient = [
    Color(0xFF1B4F3A),
    Color(0xFF2E7D32),
  ];

  static const List<Color> primaryGradientDark = [
    Color(0xFF0D2E21),
    Color(0xFF1B4F3A),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF4CAF50),
    Color(0xFF66BB6A),
  ];

  // Opaklık Değerleri
  static const double opacity10 = 0.1;
  static const double opacity20 = 0.2;
  static const double opacity30 = 0.3;
  static const double opacity50 = 0.5;
  static const double opacity70 = 0.7;
  static const double opacity80 = 0.8;
  static const double opacity90 = 0.9;

  // Gölge Renkleri
  static Color shadowLight = Colors.black.withOpacity(0.1);
  static Color shadowMedium = Colors.black.withOpacity(0.2);
  static Color shadowHeavy = Colors.black.withOpacity(0.3);

  // Özel Renkler (Context'e göre)
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : lightCard;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkText
        : lightText;
  }

  static Color getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  static List<Color> getPrimaryGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryGradientDark
        : primaryGradient;
  }

  // Ayet durumuna göre renkler
  static Color getAyahBackgroundColor(BuildContext context, {
    bool isPlaying = false,
    bool isSelected = false,
    bool isHovered = false,
  }) {
    final theme = Theme.of(context);

    if (isPlaying) {
      return primary.withOpacity(0.15);
    } else if (isSelected) {
      return primary.withOpacity(0.08);
    } else if (isHovered) {
      return warning.withOpacity(0.1);
    }

    return getCardColor(context);
  }

  static Color getAyahBorderColor(BuildContext context, {
    bool isSelected = false,
    bool isHovered = false,
  }) {
    if (isSelected || isHovered) {
      return primary;
    }
    return Theme.of(context).dividerColor;
  }

  static Color getAyahTextColor(BuildContext context, {
    bool isPlaying = false,
  }) {
    if (isPlaying) {
      return primary;
    }
    return getTextColor(context);
  }

  // Surah Card renkleri
  static List<Color> getSurahCardGradient(BuildContext context) {
    return getPrimaryGradient(context);
  }

  // Audio durumu renkleri
  static Color getAudioButtonColor(bool isPlaying) {
    return isPlaying ? audioPlaying : primary;
  }

  // Bookmark renkleri
  static Color getBookmarkColor(bool isBookmarked) {
    return isBookmarked ? bookmarked : primary;
  }

  // Tema bazlı renk seçiciler
  static ColorScheme getLightColorScheme() {
    return ColorScheme.fromSwatch().copyWith(
      primary: primary,
      secondary: secondary,
      surface: lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightText,
    );
  }

  static ColorScheme getDarkColorScheme() {
    return ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
      primary: accent,
      secondary: Color(0xFF66BB6A),
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkText,
    );
  }
}