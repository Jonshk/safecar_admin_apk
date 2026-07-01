// lib/screens/main_nav_screen.dart
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'home_screen.dart';
import 'tow_screen.dart';
import 'bookings_screen.dart';
import 'orders_screen.dart';
import '../theme/sc_theme.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});
  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _idx = 0;

  late final _screens = [
    HomeScreen(onNavigate: (i) => setState(() => _idx = i)),
    const TowScreen(),
    const BookingsScreen(),
    const OrdersScreen(),
  ];

  static const _navItems = [
    (HugeIcons.strokeRoundedDashboardSquare01, 'Inicio'),
    (HugeIcons.strokeRoundedTowTruck, 'Grúas'),
    (HugeIcons.strokeRoundedWrench01, 'Reservas'),
    (HugeIcons.strokeRoundedPackage, 'Pedidos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SC.bg,
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: SC.surface,
          border: Border(top: BorderSide(color: SC.border)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final selected = i == _idx;
                final (icon, label) = _navItems[i];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _idx = i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: icon,
                          color: selected ? SC.orange : SC.textMuted,
                          size: 21,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: SC.body(
                            size: 9.5,
                            weight: selected ? FontWeight.w500 : FontWeight.w400,
                            color: selected ? SC.orange : SC.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}