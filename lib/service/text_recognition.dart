import 'package:google_ml_kit/google_ml_kit.dart';

class TextRecognitionService {
  static Future<String> analyzeReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = GoogleMlKit.vision.textDetector();
    final recognizedText = await textRecognizer.processImage(inputImage);

    final result = StringBuffer();
    for (TextBlock block in recognizedText.blocks) {
      result.writeln(block.text);
    }

    textRecognizer.close();
    return result.toString();
  }
}
