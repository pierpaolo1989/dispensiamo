import 'package:dispensiamo/camera_screen.dart';
import 'package:flutter/material.dart';

class MainCameraScreen extends StatelessWidget {
  const MainCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraScreen()),
                );
              },
              child: const Text('Scatta una foto'),
            ),
            ElevatedButton(
              onPressed: () {
                // Funzionalità di selezione immagine da implementare
              },
              child: const Text('Seleziona dalla galleria'),
            ),
          ],
        ),
      ),
    );
  }
}
