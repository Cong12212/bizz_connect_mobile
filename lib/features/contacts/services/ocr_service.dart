import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<Map<String, String?>> extractContactFromImage(File imageFile) async {
    try {
      debugPrint('🔍 OCR: Starting text recognition...');
      debugPrint('📁 OCR: Image path: ${imageFile.path}');
      debugPrint('📏 OCR: File size: ${await imageFile.length()} bytes');

      final inputImage = InputImage.fromFile(imageFile);
      debugPrint('✅ OCR: InputImage created successfully');

      final recognizedText = await _textRecognizer.processImage(inputImage);
      debugPrint(
        '📝 OCR: Recognized text length: ${recognizedText.text.length} chars',
      );
      debugPrint('📄 OCR: Full text:\n${recognizedText.text}');
      debugPrint('📊 OCR: Blocks count: ${recognizedText.blocks.length}');

      final result = _parseBusinessCard(recognizedText.text);
      debugPrint('✨ OCR: Parsed result: $result');

      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ OCR Error: $e');
      debugPrint('📚 OCR Stack trace: $stackTrace');
      throw Exception('OCR failed: $e');
    }
  }

  Map<String, String?> _parseBusinessCard(String text) {
    debugPrint('🔧 Parsing business card text...');

    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    debugPrint('📋 Total lines: ${lines.length}');

    String? name;
    String? email;
    String? phone;
    String? company;
    String? address;
    final otherLines = <String>[];

    // Regex patterns
    final emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    );
    final phoneRegex = RegExp(
      r'(\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}',
    );

    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      debugPrint('  Line $i: "$trimmed"');

      // Extract email
      if (email == null && emailRegex.hasMatch(trimmed)) {
        email = emailRegex.firstMatch(trimmed)?.group(0);
        debugPrint('  ✉️ Found email: $email');
        continue;
      }

      // Extract phone
      if (phone == null && phoneRegex.hasMatch(trimmed)) {
        phone = phoneRegex.firstMatch(trimmed)?.group(0);
        debugPrint('  📞 Found phone: $phone');
        continue;
      }

      // First non-email, non-phone line is likely the name
      if (name == null && !trimmed.contains('@') && trimmed.length < 50) {
        name = trimmed;
        debugPrint('  👤 Found name: $name');
        continue;
      }

      // Second line might be company/position
      if (company == null && name != null) {
        company = trimmed;
        debugPrint('  🏢 Found company: $company');
        continue;
      }

      otherLines.add(trimmed);
    }

    // Remaining lines could be address
    if (otherLines.isNotEmpty) {
      address = otherLines.join(', ');
      debugPrint('  📍 Address: $address');
    }

    final result = {
      'name': name ?? 'Unknown',
      'email': email,
      'phone': phone,
      'company': company,
      'address': address,
      'notes': 'Scanned from business card',
    };

    debugPrint('✅ Parsing complete: $result');
    return result;
  }

  void dispose() {
    debugPrint('🗑️ OCR: Disposing text recognizer');
    _textRecognizer.close();
  }
}
