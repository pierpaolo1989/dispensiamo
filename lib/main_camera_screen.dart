import 'package:dispensiamo/camera_screen.dart';
import 'package:dispensiamo/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MainCameraScreen extends StatelessWidget {
  const MainCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.acidGreen,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 30,
                  color: AppColors.black,
                ),
              ),
              const Spacer(),
              const Text(
                'La tua spesa,\\nsempre sotto controllo.',
                style: TextStyle(
                  fontSize: 36,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Scansiona uno scontrino o aggiungi i prodotti alla tua dispensa.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 16,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CameraScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Scatta una foto'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Funzionalità di selezione immagine da implementare
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Color(0xFFE2E2E2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Seleziona dalla galleria'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
