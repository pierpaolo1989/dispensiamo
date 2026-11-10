import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextRecognitionService {
  static Future<String> analyzeReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);

      final result = StringBuffer();
      for (final block in recognizedText.blocks) {
        result.writeln(block.text);
      }

      return result.toString();
    } finally {
      await textRecognizer.close();
    }
  }
}
