import 'dart:convert';
import 'package:flutter/foundation.dart';

class QrService {
  /// Parse vCard or JSON format from QR code
  /// Returns null if QR data is not valid contact format
  Map<String, String?>? parseQrData(String qrData) {
    debugPrint('🔍 QR Service: Parsing QR data...');
    debugPrint('📄 QR Data: $qrData');

    // Check if it's vCard format (BEGIN:VCARD)
    if (qrData.toUpperCase().contains('BEGIN:VCARD')) {
      debugPrint('✅ Detected vCard format');
      return _parseVCard(qrData);
    }

    // Check if it's JSON format
    if (qrData.trim().startsWith('{')) {
      debugPrint('✅ Detected JSON format');
      return _parseJson(qrData);
    }

    // Check if it's URL with contact info (some QR generators use this)
    if (qrData.startsWith('http') || qrData.startsWith('https')) {
      debugPrint('⚠️ Detected URL format - trying to extract contact info');
      return _parseUrl(qrData);
    }

    debugPrint('❌ Invalid QR format - not a contact card');
    return null; // Invalid format
  }

  Map<String, String?> _parseVCard(String vcard) {
    final lines = vcard.split('\n');
    String? name;
    String? email;
    String? phone;
    String? company;
    String? title;
    String? address;
    String? url;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.startsWith('FN:')) {
        name = trimmed.substring(3);
        debugPrint('  📝 Found name: $name');
      } else if (trimmed.startsWith('N:')) {
        // Format: N:LastName;FirstName;MiddleName;Prefix;Suffix
        if (name == null) {
          final parts = trimmed.substring(2).split(';');
          name = parts.where((p) => p.isNotEmpty).join(' ');
          debugPrint('  📝 Found name from N field: $name');
        }
      } else if (trimmed.startsWith('EMAIL')) {
        email = trimmed.split(':').last;
        debugPrint('  ✉️ Found email: $email');
      } else if (trimmed.startsWith('TEL')) {
        phone = trimmed.split(':').last;
        debugPrint('  📞 Found phone: $phone');
      } else if (trimmed.startsWith('ORG:')) {
        company = trimmed.substring(4);
        debugPrint('  🏢 Found company: $company');
      } else if (trimmed.startsWith('TITLE:')) {
        title = trimmed.substring(6);
        debugPrint('  💼 Found title: $title');
      } else if (trimmed.startsWith('ADR')) {
        address = trimmed.split(':').last.replaceAll(';', ', ');
        debugPrint('  📍 Found address: $address');
      } else if (trimmed.startsWith('URL:')) {
        url = trimmed.substring(4);
        debugPrint('  🌐 Found URL: $url');
      }
    }

    if (name == null || name.isEmpty) {
      debugPrint('❌ vCard missing required field: name');
      return {'name': 'Unknown', 'notes': 'Invalid vCard - missing name'};
    }

    return {
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'job_title': title,
      'address': address,
      'website_url': url,
      'notes': 'Scanned from QR code (vCard)',
    };
  }

  Map<String, String?> _parseJson(String json) {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;

      debugPrint('📊 Parsed JSON: $data');

      // Validate required fields
      if (!data.containsKey('name') || data['name'].toString().isEmpty) {
        debugPrint('❌ JSON missing required field: name');
        return {
          'name': 'Unknown',
          'notes': 'Invalid JSON - missing name field',
        };
      }

      return {
        'name': data['name']?.toString(),
        'email': data['email']?.toString(),
        'phone': data['phone']?.toString(),
        'company': data['company']?.toString(),
        'job_title':
            data['job_title']?.toString() ?? data['jobTitle']?.toString(),
        'address': data['address']?.toString(),
        'linkedin_url':
            data['linkedin_url']?.toString() ?? data['linkedinUrl']?.toString(),
        'website_url':
            data['website_url']?.toString() ?? data['websiteUrl']?.toString(),
        'notes': 'Scanned from QR code (JSON)',
      };
    } catch (e) {
      debugPrint('❌ JSON parsing error: $e');
      return {'name': 'Invalid JSON', 'notes': 'Error parsing QR code: $e'};
    }
  }

  Map<String, String?>? _parseUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Check if URL has contact-related query parameters
      final params = uri.queryParameters;

      if (params.isEmpty) {
        debugPrint('⚠️ URL has no query parameters');
        return null;
      }

      // Try to extract contact info from URL params
      String? name = params['name'] ?? params['fn'];
      String? email = params['email'];
      String? phone = params['phone'] ?? params['tel'];

      if (name == null || name.isEmpty) {
        debugPrint('❌ URL missing name parameter');
        return null;
      }

      return {
        'name': name,
        'email': email,
        'phone': phone,
        'company': params['company'] ?? params['org'],
        'job_title': params['title'] ?? params['job_title'],
        'website_url': params['url'] ?? params['website'],
        'notes': 'Scanned from QR code (URL)',
      };
    } catch (e) {
      debugPrint('❌ URL parsing error: $e');
      return null;
    }
  }
}
