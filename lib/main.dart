// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/fcm_service.dart';
import 'theme/sc_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDBqe0Vv3CEetLqUCKpq5BJfC3_xzcFtQs',
      authDomain: 'safecar-6106b.firebaseapp.com',
      projectId: 'safecar-6106b',
      storageBucket: 'safecar-6106b.firebasestorage.app',
      messagingSenderId: '14108727840',
      appId: '1:14108727840:web:5b85b78a3a9a341236fa45',
      measurementId: 'G-7NCH4B2ZTX',
    ),
  );

  // No usamos "await" aquí a propósito: si Firebase Messaging tarda
  // (mala conexión, Play Services lento, etc.) la app ya no se queda
  // congelada en blanco esperando — arranca de inmediato y el FCM se
  // termina de configurar solo, en segundo plano.
  FcmService.init();

  runApp(const SafeCarAdminApp());
}

class SafeCarAdminApp extends StatelessWidget {
  const SafeCarAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Car Admin',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SC.bg,
      cardColor: SC.surface,
      colorScheme: const ColorScheme.dark(
        primary: SC.orange,
        secondary: SC.cyan,
        surface: SC.surface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: SC.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: SC.bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: SC.display(size: 17),
        iconTheme: const IconThemeData(color: SC.orange),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SC.orange,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SC.surface,
        selectedColor: SC.orange.withOpacity(0.2),
        labelStyle: SC.body(size: 12),
        side: const BorderSide(color: SC.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    );
  }
}