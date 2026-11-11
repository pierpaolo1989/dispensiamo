import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:dispensiamo/model/receipt_ocr_result.dart';

class TextRecognitionService {
  static Future<ReceiptOcrResult> analyzeReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final lines = recognizedText.blocks
          .expand((block) => block.lines)
          .map(
            (line) => ReceiptOcrLine(
              text: line.text,
              left: line.boundingBox.left,
              top: line.boundingBox.top,
              width: line.boundingBox.width,
              height: line.boundingBox.height,
              confidence: line.confidence,
            ),
          )
          .toList();
      return ReceiptOcrResult(lines: lines);
    } finally {
      await textRecognizer.close();
    }
  }
}
