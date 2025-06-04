import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/kuran_provider.dart';
import 'screens/sure_listesi.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => KuranProvider()),
      ],
      child: KuranEzberApp(),
    ),
  );
}

class KuranEzberApp extends StatelessWidget {
  const KuranEzberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<KuranProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'Kuran Ezber - KSU Electronic Mushaf',
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: Color(0xFF1B4F3A),
            scaffoldBackgroundColor: Color(0xFFF8F8F8),
            cardColor: Colors.white,
            appBarTheme: AppBarTheme(
              backgroundColor: Color(0xFF1B4F3A),
              foregroundColor: Colors.white,
              elevation: 1,
              centerTitle: false,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B4F3A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF1B4F3A), width: 2),
              ),
            ),
            fontFamily: 'Poppins',
            colorScheme: ColorScheme.fromSwatch().copyWith(
              primary: Color(0xFF1B4F3A),
              secondary: Color(0xFF2E7D32),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Color(0xFF0D2E21),
            scaffoldBackgroundColor: Color(0xFF121212),
            cardColor: Color(0xFF1E1E1E),
            appBarTheme: AppBarTheme(
              backgroundColor: Color(0xFF0D2E21),
              foregroundColor: Colors.white,
              elevation: 1,
              centerTitle: false,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0D2E21),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Color(0xFF1E1E1E),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF4CAF50), width: 2),
              ),
            ),
            fontFamily: 'Poppins',
            colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
              primary: Color(0xFF4CAF50),
              secondary: Color(0xFF66BB6A),
            ),
          ),
          themeMode: provider.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: SureListesi(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}