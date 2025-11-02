import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/ocr_service.dart';
import '../services/qr_service.dart';
import '../data/models.dart'; // ✅ Thêm dòng này
import 'camera_scanner_page.dart';
import 'scanned_contact_preview_dialog.dart';

enum ScanMode { businessCard, qrCode }

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  ScanMode _mode = ScanMode.businessCard;
  final _ocrService = OcrService();
  final _qrService = QrService();
  final _imagePicker = ImagePicker();
  bool _isProcessing = false;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _scanWithCamera() async {
    // Temporarily disabled - use gallery upload instead
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Camera scanning coming soon. Please use gallery upload.',
        ),
        duration: Duration(seconds: 2),
      ),
    );

    // Automatically trigger image picker instead
    await _pickImage();
  }

  Future<void> _pickImage() async {
    try {
      debugPrint('📸 Starting image picker...');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('❌ No image selected');
        return;
      }

      debugPrint('✅ Image selected: ${image.path}');
      debugPrint('📏 Image size: ${await image.length()} bytes');

      setState(() => _isProcessing = true);

      if (_mode == ScanMode.businessCard) {
        debugPrint('🔄 Processing business card...');
        await _processBusinessCard(File(image.path));
      } else {
        debugPrint('⚠️ QR from image not implemented');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quét QR từ ảnh chưa được triển khai'),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _pickImage: $e');
      debugPrint('📚 Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processBusinessCard(File imageFile) async {
    try {
      debugPrint('🔧 Processing business card image...');

      final contactData = await _ocrService.extractContactFromImage(imageFile);
      debugPrint('✅ OCR completed, showing preview dialog...');
      debugPrint('📋 Contact data: $contactData');

      if (mounted) {
        // Show preview dialog instead of navigating directly
        final result = await showDialog<Contact?>(
          context: context,
          barrierDismissible: false,
          builder: (_) => ScannedContactPreviewDialog(scannedData: contactData),
        );

        if (result != null && mounted) {
          // Contact was saved, navigate back to contacts list
          debugPrint('✅ Contact saved, navigating back...');
          context.go('/contacts');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Contact "${result.name}" added successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _processBusinessCard: $e');
      debugPrint('📚 Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR failed: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _processQrCode(String qrData) {
    debugPrint('📱 Processing QR code data: $qrData');

    final contactData = _qrService.parseQrData(qrData);

    if (contactData == null) {
      debugPrint('❌ Invalid QR code format');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid QR code format. Please scan a vCard or contact QR code.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    debugPrint('✅ QR parsed, showing preview dialog...');
    debugPrint('📋 Contact data: $contactData');

    // Show preview dialog for QR data too
    showDialog<Contact?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ScannedContactPreviewDialog(scannedData: contactData),
    ).then((result) {
      if (result != null && mounted) {
        debugPrint('✅ Contact from QR saved, navigating back...');
        context.go('/contacts');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contact "${result.name}" added successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Scan Contact'), centerTitle: true),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Mode selector
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeButton(
                            icon: Icons.credit_card,
                            label: 'Business Card',
                            selected: _mode == ScanMode.businessCard,
                            onTap: () =>
                                setState(() => _mode = ScanMode.businessCard),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: const Color(0xFFE5E7EB),
                        ),
                        Expanded(
                          child: _ModeButton(
                            icon: Icons.qr_code_2,
                            label: 'QR Code',
                            selected: _mode == ScanMode.qrCode,
                            onTap: () =>
                                setState(() => _mode = ScanMode.qrCode),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Icon display
                Icon(
                  _mode == ScanMode.businessCard
                      ? Icons.credit_card_outlined
                      : Icons.qr_code_scanner,
                  size: 120,
                  color: const Color(0xFF64748B),
                ),

                const SizedBox(height: 16),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _mode == ScanMode.businessCard
                        ? 'Scan or upload a business card image to extract contact information'
                        : 'Scan or upload a QR code to import contact details',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Scan with camera
                      FilledButton.icon(
                        onPressed: _isProcessing ? null : _scanWithCamera,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_alt),
                        label: Text(
                          _mode == ScanMode.businessCard
                              ? 'Scan Business Card'
                              : 'Scan QR Code',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Upload from gallery
                      OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Upload from Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Tips section
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tips for best results:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _mode == ScanMode.businessCard
                                  ? '• Place card on flat surface\n'
                                        '• Ensure good lighting\n'
                                        '• Keep card edges visible\n'
                                        '• Avoid shadows and glare'
                                  : '• Center QR code in frame\n'
                                        '• Ensure good lighting\n'
                                        '• Hold camera steady\n'
                                        '• Keep appropriate distance',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0369A1),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : const Color(0xFF64748B),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
