import 'package:dispensiamo/service/text_recognition.dart';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String imagePath;

  ResultScreen({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Risultato')),
      body: FutureBuilder<String>(
        future: TextRecognitionService.analyzeReceipt(imagePath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Testo riconosciuto:\n\n${snapshot.data}',
                style: TextStyle(fontSize: 16),
              ),
            );
          }
          return Center(child: Text('Errore durante l\'analisi'));
        },
      ),
    );
  }
}
