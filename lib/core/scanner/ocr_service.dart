import 'dart:io';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class OCRService {
  final String languageCode;

  OCRService({this.languageCode = 'eng'});

  Future<String> recognizeText(File imageFile) async {
    final lang = _getTesseractLanguage(languageCode);
    // Use FlutterTesseractOcr.extractText for simplicity and broad compatibility.
    // This internally handles image processing.
    return await FlutterTesseractOcr.extractText(imageFile.path, language: lang);
  }

  String _getTesseractLanguage(String langCode) {
    switch (langCode) {
      case 'bn':
        return 'ben'; // Tesseract code for Bengali
      default:
        return 'eng'; // Tesseract code for English
    }
  }

  // No dispose method is needed for the static Tesseract functions.
  void dispose() {}
}
