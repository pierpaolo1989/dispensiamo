import 'package:dispensiamo/l10n/app_strings.dart';
import 'package:dispensiamo/dispensa_screen.dart';
import 'package:dispensiamo/main_camera_screen.dart';
import 'package:dispensiamo/settings_screen.dart';
import 'package:dispensiamo/statistics_screen.dart';
import 'package:dispensiamo/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  int _selectedIndex = 0;
  int _pantryRevision = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onProductsImported(int count) {
    setState(() {
      _selectedIndex = 1;
      _pantryRevision++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).productsImported(count))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final widgetOptions = <Widget>[
      MainCameraScreen(onProductsImported: _onProductsImported),
      DispensaScreen(key: ValueKey(_pantryRevision)),
      const SettingsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_selectedIndex == 1)
            IconButton(
              tooltip: strings.spendingStatisticsTooltip,
              icon: const Icon(Icons.bar_chart_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const StatisticsScreen(),
                  ),
                );
              },
            ),
        ],
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.acidGreen,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 23,
                color: AppColors.black,
              ),
            ),
            const SizedBox(width: 12),
            Text([
              strings.home,
              strings.pantry,
              strings.settings,
            ][_selectedIndex]),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: widgetOptions,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: strings.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2_rounded),
              label: strings.pantry,
            ),
            NavigationDestination(
              icon: const Icon(Icons.tune_rounded),
              label: strings.settings,
            ),
          ],
        ),
      ),
    );
  }
}
