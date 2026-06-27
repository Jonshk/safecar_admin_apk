// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/tow_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/orders_screen.dart';

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
      home: const MainNavScreen(),
    );
  }

  ThemeData _buildTheme() {
    const bgColor = Color(0xFF0D0D0D);
    const cardColor = Color(0xFF1A1A1A);
    const goldColor = Color(0xFFD4AF37);
    const textColor = Color(0xFFF5F5F5);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      cardColor: cardColor,
      colorScheme: const ColorScheme.dark(
        primary: goldColor,
        secondary: goldColor,
        surface: cardColor,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textColor,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: goldColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: goldColor),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF111111),
        selectedItemColor: goldColor,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldColor,
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: goldColor.withOpacity(0.2),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: textColor),
        side: const BorderSide(color: Colors.white12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});
  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _idx = 0;

  final _screens = const [
    HomeScreen(),
    TowScreen(),
    BookingsScreen(),
    OrdersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_rounded), label: 'Grúas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.build_circle_rounded), label: 'Reservas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_rounded), label: 'Pedidos'),
        ],
      ),
    );
  }
}
