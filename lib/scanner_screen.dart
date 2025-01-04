import 'package:flutter/material.dart';
import 'camera_screen.dart';

class ReceiptScannerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scanner Scontrino')),
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
              child: Text('Scatta una foto'),
            ),
            ElevatedButton(
              onPressed: () {
                // Funzionalità di selezione immagine da implementare
              },
              child: Text('Seleziona dalla galleria'),
            ),
          ],
        ),
      ),
    );
  }
}
