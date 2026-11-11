class ReceiptOcrLine {
  const ReceiptOcrLine({
    required this.text,
    this.left,
    this.top,
    this.width,
    this.height,
    this.confidence,
  });

  final String text;
  final double? left;
  final double? top;
  final double? width;
  final double? height;
  final double? confidence;

  bool get hasPosition => left != null && top != null;
  double get centerY => top! + (height ?? 0) / 2;
}

class ReceiptOcrResult {
  const ReceiptOcrResult({required this.lines});

  factory ReceiptOcrResult.fromText(String text) => ReceiptOcrResult(
        lines: text
            .split(RegExp(r'[\r\n]+'))
            .map((line) => ReceiptOcrLine(text: line))
            .toList(),
      );

  final List<ReceiptOcrLine> lines;

  String get text => lines.map((line) => line.text).join('\n');
}
