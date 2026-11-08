import 'package:dispensiamo/l10n/app_strings.dart';
import 'package:dispensiamo/service/text_recognition_service.dart';
import 'package:dispensiamo/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String imagePath;

  const ResultScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.result)),
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
                strings.recognizedText(snapshot.data!),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppColors.black,
                ),
              ),
            );
          }
          return Center(child: Text(strings.analysisError));
        },
      ),
    );
  }
}
