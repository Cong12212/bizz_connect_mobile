import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class ECardPreviewDialog extends StatefulWidget {
  const ECardPreviewDialog({
    required this.frontImage,
    required this.backImage,
    super.key,
  });

  final File frontImage;
  final File backImage;

  @override
  State<ECardPreviewDialog> createState() => _ECardPreviewDialogState();
}

class _ECardPreviewDialogState extends State<ECardPreviewDialog> {
  bool _showFront = true;
  bool _downloading = false;
  bool _savingToGallery = false;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  Future<void> _saveToGallery() async {
    if (!_isMobile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This feature is only available on mobile'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _savingToGallery = true);

    try {
      // Read image bytes
      final frontBytes = await widget.frontImage.readAsBytes();
      final backBytes = await widget.backImage.readAsBytes();

      // Save front image
      final frontResult = await ImageGallerySaverPlus.saveImage(
        frontBytes,
        quality: 100,
        name: 'business_card_front_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Small delay to ensure proper file system handling
      await Future.delayed(const Duration(milliseconds: 100));

      // Save back image
      final backResult = await ImageGallerySaverPlus.saveImage(
        backBytes,
        quality: 100,
        name: 'business_card_back_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        // ImageGallerySaverPlus returns the file path on success, null on failure
        final bool success =
            frontResult != null &&
            backResult != null &&
            frontResult.toString().isNotEmpty &&
            backResult.toString().isNotEmpty;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Business cards saved successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check your Photos/Gallery app',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          throw Exception('Failed to save images to gallery');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e\nImages may still be in Downloads folder'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingToGallery = false);
    }
  }

  Future<void> _downloadImages() async {
    if (!_isMobile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This feature is only available on mobile'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _downloading = true);

    try {
      // Share files using share_plus
      await Share.shareXFiles([
        XFile(widget.frontImage.path, name: 'business_card_front.png'),
        XFile(widget.backImage.path, name: 'business_card_back.png'),
      ], text: 'My Business Card');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business cards ready to save'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  const Text(
                    'E-Business Card',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Card preview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Side selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SideButton(
                            label: 'Front',
                            selected: _showFront,
                            onTap: () => setState(() => _showFront = true),
                          ),
                        ),
                        Expanded(
                          child: _SideButton(
                            label: 'Back',
                            selected: !_showFront,
                            onTap: () => setState(() => _showFront = false),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Card image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _showFront ? widget.frontImage : widget.backImage,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Save to Gallery button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _savingToGallery || !_isMobile
                          ? null
                          : _saveToGallery,
                      icon: _savingToGallery
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.photo_library),
                      label: Text(_isMobile ? 'Save to Photos' : 'Mobile Only'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Download/Share button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _downloading || !_isMobile
                          ? null
                          : _downloadImages,
                      icon: _downloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.share),
                      label: Text(
                        _isMobile ? 'Share Both Sides' : 'Mobile Only',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
