import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bizz_connect_mobile/features/settings/data/models/business_card_models.dart';
import 'package:bizz_connect_mobile/features/settings/data/models/company_models.dart';

class BusinessCardGenerator {
  static const double cardWidth = 1050; // 3.5 inches * 300 DPI
  static const double cardHeight = 600; // 2 inches * 300 DPI

  // Optional background image path
  final String? backgroundImagePath;

  BusinessCardGenerator({this.backgroundImagePath});

  Future<List<File>> generateCardImages(
    BusinessCard card,
    Company? company,
  ) async {
    final frontImage = await _generateFrontSide(card, company);
    final backImage = await _generateBackSide(card, company);

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final frontFile = File(
      '${tempDir.path}/business_card_front_$timestamp.png',
    );
    final backFile = File('${tempDir.path}/business_card_back_$timestamp.png');

    await frontFile.writeAsBytes(frontImage);
    await backFile.writeAsBytes(backImage);

    return [frontFile, backFile];
  }

  Future<Uint8List> _generateFrontSide(
    BusinessCard card,
    Company? company,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Draw background image or gradient
    await _drawBackground(canvas, paint);

    // Add semi-transparent overlay for better text readability
    paint.shader = null;
    paint.color = Colors.black.withOpacity(0.3);
    canvas.drawRect(Rect.fromLTWH(0, 0, cardWidth, cardHeight), paint);

    // Company logo area (top left)
    if (company != null) {
      _drawLabelValue(
        canvas,
        'Company:',
        company.name,
        40,
        60,
        const TextStyle(
          color: Color(0xFFBFDBFE),
          fontSize: 24,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
        const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      );
    }

    // Main content (bottom left)
    double y = cardHeight - 200;

    // Name with label on same line
    _drawLabelValue(
      canvas,
      'Name:',
      card.fullName,
      40,
      y,
      const TextStyle(
        color: Color(0xFFBFDBFE),
        fontSize: 28,
        fontWeight: FontWeight.w500,
      ),
      const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );

    y += 50;

    // Job Title with label on same line
    if (card.jobTitle != null) {
      _drawLabelValue(
        canvas,
        'Position:',
        card.jobTitle!,
        40,
        y,
        const TextStyle(
          color: Color(0xFFBFDBFE),
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        const TextStyle(color: Colors.white, fontSize: 22),
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(cardWidth.toInt(), cardHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _generateBackSide(
    BusinessCard card,
    Company? company,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Background with subtle gradient
    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(cardWidth, cardHeight),
      [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
    );
    paint.shader = gradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, cardWidth, cardHeight), paint);

    // Left side accent bar
    paint.shader = null;
    paint.color = const Color(0xFF3B82F6);
    canvas.drawRect(Rect.fromLTWH(0, 0, 20, cardHeight), paint);

    // Decorative elements
    paint.color = const Color(0xFF3B82F6).withOpacity(0.1);
    canvas.drawCircle(Offset(cardWidth - 100, 100), 150, paint);
    canvas.drawCircle(Offset(cardWidth - 200, cardHeight - 100), 100, paint);

    double y = 80;
    const leftMargin = 80.0;
    const textColor = Color(0xFF1F2937);
    const labelColor = Color(0xFF6B7280);
    const lineHeight = 70.0;

    // Contact section header
    _drawText(
      canvas,
      'CONTACT INFORMATION',
      leftMargin,
      y,
      const TextStyle(
        color: Color(0xFF3B82F6),
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );

    y += 60;

    // Phone
    if (card.phone != null) {
      _drawContactField(
        canvas,
        'Phone',
        card.phone!,
        leftMargin,
        y,
        textColor,
        labelColor,
      );
      y += lineHeight;
    }

    // Mobile
    if (card.mobile != null && card.mobile != card.phone) {
      _drawContactField(
        canvas,
        'Mobile',
        card.mobile!,
        leftMargin,
        y,
        textColor,
        labelColor,
      );
      y += lineHeight;
    }

    // Email
    if (card.email.isNotEmpty) {
      _drawContactField(
        canvas,
        'Email',
        card.email,
        leftMargin,
        y,
        textColor,
        labelColor,
      );
      y += lineHeight;
    }

    // Website
    if (card.website != null) {
      _drawContactField(
        canvas,
        'Website',
        card.website!,
        leftMargin,
        y,
        textColor,
        labelColor,
      );
      y += lineHeight;
    }

    // Draw QR Code on the right side
    await _drawQRCode(canvas, card, company);

    // Address section at bottom
    String? addressText = _formatAddress(card, company);
    if (addressText != null) {
      y = cardHeight - 160;
      _drawText(
        canvas,
        'ADDRESS',
        leftMargin,
        y,
        const TextStyle(
          color: Color(0xFF3B82F6),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      );
      y += 40;
      _drawText(
        canvas,
        addressText,
        leftMargin,
        y,
        const TextStyle(color: textColor, fontSize: 18, height: 1.4),
        maxWidth: (cardWidth / 2) - leftMargin - 40,
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(cardWidth.toInt(), cardHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // Generate QR code data with all contact information
  Future<void> _drawQRCode(
    Canvas canvas,
    BusinessCard card,
    Company? company,
  ) async {
    // Create comprehensive JSON data for QR code
    final qrData = {
      'name': card.fullName,
      'jobTitle': card.jobTitle,
      'company': company?.name,
      'email': card.email,
      'phone': card.phone,
      'mobile': card.mobile,
      'website': card.website,
      'addressDetail': card.address?.addressDetail,
      'cityCode': card.address?.city?.code,
      'cityName': card.address?.city?.name,
      'stateCode': card.address?.state?.code,
      'stateName': card.address?.state?.name,
      'countryCode': card.address?.country?.code,
      'countryName': card.address?.country?.name,
      'notes': 'Scanned from business card',
    };

    // Remove null values
    qrData.removeWhere((key, value) => value == null);

    final qrString = jsonEncode(qrData);
    debugPrint('QR Code Data: $qrString');

    try {
      final qrSize = 220.0;
      final qrX = cardWidth - qrSize - 60;
      final qrY = 80.0;

      // Draw white background for QR code
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(qrX - 15, qrY - 15, qrSize + 30, qrSize + 30),
          const Radius.circular(12),
        ),
        bgPaint,
      );

      // Create QR painter
      final qrPainter = QrPainter(
        data: qrString,
        version: QrVersions.auto,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF1F2937),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF1F2937),
        ),
        gapless: true,
      );

      // Paint QR code on canvas
      canvas.save();
      canvas.translate(qrX, qrY);
      qrPainter.paint(canvas, Size(qrSize, qrSize));
      canvas.restore();

      // Draw "Scan Me" label below QR code
      _drawText(
        canvas,
        'Scan to save contact',
        qrX,
        qrY + qrSize + 25,
        const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );

      debugPrint('✅ QR code drawn successfully');
    } catch (e) {
      debugPrint('❌ Error drawing QR code: $e');
    }
  }

  // Draw background image or default gradient
  Future<void> _drawBackground(Canvas canvas, Paint paint) async {
    if (backgroundImagePath != null) {
      try {
        final file = File(backgroundImagePath!);
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: cardWidth.toInt(),
          targetHeight: cardHeight.toInt(),
        );
        final frame = await codec.getNextFrame();
        canvas.drawImageRect(
          frame.image,
          Rect.fromLTWH(
            0,
            0,
            frame.image.width.toDouble(),
            frame.image.height.toDouble(),
          ),
          Rect.fromLTWH(0, 0, cardWidth, cardHeight),
          paint,
        );
      } catch (e) {
        _drawDefaultGradient(canvas, paint);
      }
    } else {
      _drawDefaultGradient(canvas, paint);
    }
  }

  void _drawDefaultGradient(Canvas canvas, Paint paint) {
    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(cardWidth, cardHeight),
      [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
    );
    paint.shader = gradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, cardWidth, cardHeight), paint);
  }

  void _drawContactField(
    Canvas canvas,
    String label,
    String value,
    double x,
    double y,
    Color textColor,
    Color labelColor,
  ) {
    _drawText(
      canvas,
      label,
      x,
      y,
      TextStyle(color: labelColor, fontSize: 16, fontWeight: FontWeight.w600),
    );

    _drawText(
      canvas,
      value,
      x,
      y + 28,
      TextStyle(color: textColor, fontSize: 20),
    );
  }

  void _drawLabelValue(
    Canvas canvas,
    String label,
    String value,
    double x,
    double y,
    TextStyle labelStyle,
    TextStyle valueStyle,
  ) {
    final labelSpan = TextSpan(text: label, style: labelStyle);
    final labelPainter = TextPainter(
      text: labelSpan,
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(canvas, Offset(x, y));

    final valueX = x + labelPainter.width + 12;
    _drawText(canvas, value, valueX, y, valueStyle);
  }

  void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y,
    TextStyle style, {
    double? maxWidth,
  }) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: maxWidth != null ? 3 : 1,
    );
    textPainter.layout(maxWidth: maxWidth ?? double.infinity);
    textPainter.paint(canvas, Offset(x, y));
  }

  String? _formatAddress(BusinessCard card, Company? company) {
    final parts = <String>[];

    final detail = card.address?.addressDetail;
    final city = card.address?.city?.name;
    final state = card.address?.state?.name;
    final country = card.address?.country?.name;

    if (detail != null && detail.trim().isNotEmpty) parts.add(detail.trim());
    if (city != null && city.trim().isNotEmpty) parts.add(city.trim());
    if (state != null && state.trim().isNotEmpty) parts.add(state.trim());
    if (country != null && country.trim().isNotEmpty) parts.add(country.trim());

    return parts.isEmpty ? null : parts.join(', ');
  }
}
