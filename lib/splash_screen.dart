import 'dart:async';

import 'package:dispensiamo/scanner_screen.dart';
import 'package:dispensiamo/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Timer _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ReceiptScannerScreen()),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.acidGreen,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 52,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'dispensiamo',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
