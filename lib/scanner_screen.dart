import 'package:dispensiamo/dispensa_screen.dart';
import 'package:dispensiamo/main_camera_screen.dart';
import 'package:dispensiamo/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  int _selectedIndex = 0;
  static final List<Widget> _widgetOptions = <Widget>[
    const MainCameraScreen(),
    const DispensaScreen(),
    const Center(
      child: Text(
        'Impostazioni',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('dispensiamo'),
        actions: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(right: 20),
            decoration: const BoxDecoration(
              color: AppColors.acidGreen,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Dispensa',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            label: 'Altro',
          ),
        ],
      ),
    );
  }
}
