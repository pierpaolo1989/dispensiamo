import 'package:dispensiamo/service/text_recognition_service.dart';
import 'package:dispensiamo/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String imagePath;

  const ResultScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Risultato')),
      body: FutureBuilder<String>(
        future: TextRecognitionService.analyzeReceipt(imagePath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Testo riconosciuto:\n\n${snapshot.data}',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppColors.black,
                ),
              ),
            );
          }
          return const Center(child: Text('Errore durante l\'analisi'));
        },
      ),
    );
  }
}
