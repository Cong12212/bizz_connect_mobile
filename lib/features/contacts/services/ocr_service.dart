import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Always returns normalized keys:
  /// name, jobTitle, company, email, phone,
  /// addressDetail, cityCode, stateCode, countryCode,
  /// linkedinUrl, websiteUrl, notes
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
      debugPrint('📊 OCR: Blocks count: ${recognizedText.blocks.length}');
      debugPrint('📄 OCR: Full text:\n${recognizedText.text}');

      final lines = recognizedText.text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      final labeled = _parseLabeledFormat(lines);
      final raw = labeled ?? _parseHeuristicFormat(lines);
      final normalized = _normalize(raw);

      debugPrint('✨ OCR: Normalized result: $normalized');
      return normalized;
    } catch (e, st) {
      debugPrint('❌ OCR Error: $e');
      debugPrint('📚 OCR Stack trace: $st');
      throw Exception('OCR failed: $e');
    }
  }

  void dispose() {
    _textRecognizer.close();
  }

  // -------------------- PARSE: labeled format --------------------
  Map<String, String?>? _parseLabeledFormat(List<String> lines) {
    final data = <String, String?>{
      'name': null,
      'email': null,
      'phone': null,
      'mobile': null,
      'company': null,
      'position': null,
      'website': null,
      'address': null,
      'linkedin': null,
      'notes': 'Scanned from business card',
    };

    bool hasLabels = false;

    final emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
    );
    final phoneRegex = RegExp(
      r'(\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}',
    );
    final urlRegex = RegExp(
      r"(https?:\/\/)?([\w\.-]+)\.[a-zA-Z]{2,}(\/[\w\-\.\~:\?#@\!\$&'()\*\+,;=\/]*)?",
    );

    String afterLabel(String line, int cut) =>
        line.substring(cut).trim().replaceAll(RegExp(r'^\-+|\-+$'), '');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();

      if (lower.startsWith('name:')) {
        data['name'] = afterLabel(line, 5);
        hasLabels = true;
      } else if (lower.startsWith('company:')) {
        data['company'] = afterLabel(line, 8);
        hasLabels = true;
      } else if (lower.startsWith('position:')) {
        data['position'] = afterLabel(line, 9);
        hasLabels = true;
      } else if (lower.startsWith('title:')) {
        data['position'] = afterLabel(line, 6);
        hasLabels = true;
      } else if (lower.startsWith('email:')) {
        data['email'] = afterLabel(line, 6);
        hasLabels = true;
      } else if (lower.startsWith('phone:')) {
        data['phone'] = afterLabel(line, 6);
        hasLabels = true;
      } else if (lower.startsWith('mobile:')) {
        data['mobile'] = afterLabel(line, 7);
        hasLabels = true;
      } else if (lower.startsWith('website:')) {
        data['website'] = afterLabel(line, 8);
        hasLabels = true;
      } else if (lower.startsWith('linkedin:')) {
        data['linkedin'] = afterLabel(line, 9);
        hasLabels = true;
      } else if (lower.startsWith('address:')) {
        final parts = <String>[afterLabel(line, 8)];
        for (var j = i + 1; j < lines.length; j++) {
          final next = lines[j].trim();
          if (_looksLikeLabel(next.toLowerCase())) break;
          parts.add(next);
        }
        data['address'] = parts.where((e) => e.trim().isNotEmpty).join(', ');
        hasLabels = true;
      } else {
        // unlabeled supplements
        if (data['email'] == null && emailRegex.hasMatch(line)) {
          data['email'] = emailRegex.firstMatch(line)?.group(0);
        }
        if (data['phone'] == null && phoneRegex.hasMatch(line)) {
          data['phone'] = phoneRegex.firstMatch(line)?.group(0);
        }
        if (data['website'] == null && urlRegex.hasMatch(line)) {
          data['website'] = urlRegex.firstMatch(line)?.group(0);
        }
        if (data['linkedin'] == null && lower.contains('linkedin')) {
          final m = urlRegex.firstMatch(line);
          data['linkedin'] = m?.group(0) ?? line;
        }
      }
    }

    if (!hasLabels) return null;
    if (data['position'] != null) data['jobTitle'] = data['position'];
    return data;
  }

  bool _looksLikeLabel(String lower) {
    const labels = [
      'name:',
      'company:',
      'position:',
      'title:',
      'email:',
      'phone:',
      'mobile:',
      'website:',
      'address:',
      'linkedin:',
    ];
    return labels.any((l) => lower.startsWith(l));
  }

  // -------------------- PARSE: heuristic format --------------------
  Map<String, String?> _parseHeuristicFormat(List<String> lines) {
    String? name;
    String? email;
    String? phone;
    String? mobile;
    String? company;
    String? position;
    String? address;
    String? website;
    String? linkedin;

    final emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
    );
    final phoneRegex = RegExp(
      r'(\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}',
    );
    final urlRegex = RegExp(
      r"(https?:\/\/)?([\w\.-]+)\.[a-zA-Z]{2,}(\/[\w\-\.\~:\?#@\!\$&'()\*\+,;=\/]*)?",
    );

    for (final line in lines) {
      if (email == null) {
        final m = emailRegex.firstMatch(line);
        if (m != null) email = m.group(0);
      }
      if (phone == null) {
        final m = phoneRegex.firstMatch(line);
        if (m != null) phone = m.group(0);
      }
      if (website == null) {
        final m = urlRegex.firstMatch(line);
        if (m != null) website = m.group(0);
      }
      if (linkedin == null && line.toLowerCase().contains('linkedin')) {
        final m = urlRegex.firstMatch(line);
        linkedin = m?.group(0) ?? line;
      }
    }

    String _titleCase(String s) => s
        .split(RegExp(r'\s+'))
        .map(
          (w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');

    for (final line in lines.take(4)) {
      final words = line
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      if (words.length >= 2 && words.length <= 4) {
        final allTitle =
            words
                .where((w) => RegExp(r"^[A-ZÀ-Ỳ][a-zà-ỳ'’-]+$").hasMatch(w))
                .length ==
            words.length;
        if (allTitle) {
          name = _titleCase(line);
          break;
        }
      }
    }

    final companyHints = RegExp(
      r'(company|co\.?,?\s*ltd|jsc|inc\.?|corp\.?)',
      caseSensitive: false,
    );
    final foundCompany = lines.firstWhere(
      (l) => companyHints.hasMatch(l),
      orElse: () => '',
    );
    if (foundCompany.isNotEmpty) company = foundCompany;

    final positionHints = RegExp(
      r'\b(CEO|CTO|COO|CFO|CMO|CIO|Director|Manager|Lead|Head|Supervisor|Specialist|Engineer|Developer|Designer|Consultant|Sales|Marketing|HR|Accountant|Analyst|Founder|Co[-\s]?Founder)\b',
      caseSensitive: false,
    );
    final foundPos = lines.firstWhere(
      (l) => positionHints.hasMatch(l),
      orElse: () => '',
    );
    if (foundPos.isNotEmpty) position = foundPos;

    final addressHints = RegExp(
      r'(đường|p\.|phường|q\.|quận|tp\.|thành phố|street|st\.|road|rd\.|city|state|country)',
      caseSensitive: false,
    );
    final foundAddr = lines.reversed.firstWhere(
      (l) => l.length > 12 && (addressHints.hasMatch(l) || l.contains(',')),
      orElse: () => '',
    );
    if (foundAddr.isNotEmpty) address = foundAddr;

    return {
      'name': name,
      'email': email,
      'phone': phone ?? mobile,
      'mobile': mobile,
      'company': company,
      'position': position,
      'website': website,
      'linkedin': linkedin,
      'address': address,
      'notes': 'Scanned from business card',
    };
  }

  // -------------------- NORMALIZE → final schema --------------------
  Map<String, String?> _normalize(Map<String, String?> raw) {
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = raw[k];
        if (v != null && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    String? cleanPhone(String? p) {
      if (p == null) return null;
      var v = p.replaceAll(RegExp(r'[^0-9+]'), '');
      if (v.startsWith('0')) v = '+84${v.substring(1)}';
      if (v.startsWith('84') && !v.startsWith('+')) v = '+$v';
      return v;
    }

    String? firstUrl(String? s) {
      if (s == null) return null;
      final r = RegExp(
        r"(https?:\/\/)?([\w\.-]+)\.[a-zA-Z]{2,}(\/[\w\-\.\~:\?#@\!\$&'()\*\+,;=\/]*)?",
      );
      final m = r.firstMatch(s);
      if (m == null) return s.trim();
      final u = m.group(0)!.trim();
      return u.startsWith('http') ? u : 'https://$u';
    }

    final addressRaw = pick(['address', 'addressDetail', 'address_detail']);
    final addr = _normalizeAddress(addressRaw);

    return {
      'name': pick(['name']),
      'jobTitle': pick(['jobTitle', 'position', 'title']),
      'company': pick(['company', 'org', 'organization']),
      'email': pick(['email', 'mail']),
      'phone': cleanPhone(pick(['phone', 'mobile', 'tel'])),
      'addressDetail': addr.addressDetail,
      'cityCode': addr.cityCode,
      'stateCode': addr.stateCode,
      'countryCode': addr.countryCode,
      'linkedinUrl': firstUrl(
        pick(['linkedin', 'linkedinUrl', 'linkedin_url']),
      ),
      'websiteUrl': firstUrl(pick(['website', 'websiteUrl', 'website_url'])),
      'notes': pick(['notes']) ?? 'Scanned from business card',
    };
  }

  _Addr _normalizeAddress(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return _Addr.nulls();
    }
    final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    final tokens = text.split(RegExp(r'[,\|]')).map((s) => s.trim()).toList();

    String? cityCode;
    String? stateCode;
    String? countryCode;

    for (var i = tokens.length - 1; i >= 0; i--) {
      final t = tokens[i];
      if (RegExp(r'^[A-Z]{2,3}$').hasMatch(t)) {
        if (countryCode == null) {
          countryCode = t; // e.g. VN/US/JP/SG
          continue;
        }
        if (stateCode == null) {
          stateCode = t; // e.g. SG/CA/NY
          continue;
        }
        if (cityCode == null) {
          cityCode = t; // e.g. HCM/HAN
          continue;
        }
      }
    }

    var addressDetail = text;
    final codeSet = {
      cityCode,
      stateCode,
      countryCode,
    }.whereType<String>().toSet();
    if (codeSet.isNotEmpty) {
      addressDetail = tokens
          .where((t) => !codeSet.contains(t))
          .join(', ')
          .trim();
    }
    if (addressDetail.isEmpty) addressDetail = text;

    return _Addr(
      addressDetail: addressDetail,
      cityCode: cityCode,
      stateCode: stateCode,
      countryCode: countryCode,
    );
  }
}

class _Addr {
  final String? addressDetail;
  final String? cityCode;
  final String? stateCode;
  final String? countryCode;

  _Addr({
    required this.addressDetail,
    required this.cityCode,
    required this.stateCode,
    required this.countryCode,
  });

  factory _Addr.nulls() => _Addr(
    addressDetail: null,
    cityCode: null,
    stateCode: null,
    countryCode: null,
  );
}
