import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ocr_service.dart';
import '../data/models.dart';
import 'scanned_contact_preview_dialog.dart';

enum ScanStep { front, back, preview }

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  ScanStep _step = ScanStep.front;
  final _ocrService = OcrService();
  final _imagePicker = ImagePicker();

  bool _isProcessing = false;
  File? _frontImage;
  File? _backImage;
  Map<String, String?>? _frontData;
  Map<String, String?>? _backData;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      debugPrint('📸 Starting image picker for ${_step.name}...');

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('❌ No image selected');
        return;
      }

      debugPrint('✅ Image selected: ${image.path}');
      setState(() => _isProcessing = true);

      final imageFile = File(image.path);
      final extractedData = await _ocrService.extractContactFromImage(
        imageFile,
      );

      if (_step == ScanStep.front) {
        setState(() {
          _frontImage = imageFile;
          _frontData = extractedData;
          _step = ScanStep.back;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Front side scanned. Now scan the back side.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (_step == ScanStep.back) {
        setState(() {
          _backImage = imageFile;
          _backData = extractedData;
          _step = ScanStep.preview;
        });
      }
    } catch (e) {
      debugPrint('❌ Error in _pickImage: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _skipBackSide() {
    setState(() {
      _backImage = null;
      _backData = null;
      _step = ScanStep.preview;
    });
  }

  void _resetScan() {
    setState(() {
      _step = ScanStep.front;
      _frontImage = null;
      _backImage = null;
      _frontData = null;
      _backData = null;
    });
  }

  Map<String, String?> _mergeData() {
    final merged = <String, String?>{..._frontData ?? {}};

    // Merge back data, prioritizing non-empty values
    if (_backData != null) {
      _backData!.forEach((key, value) {
        if (value != null && value.trim().isNotEmpty) {
          if (merged[key] == null || merged[key]!.trim().isEmpty) {
            merged[key] = value;
          }
        }
      });
    }

    return merged;
  }

  Future<void> _showPreviewAndSave() async {
    final mergedData = _mergeData();

    final result = await showDialog<Contact?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ScannedContactPreviewDialog(scannedData: mergedData),
    );

    if (result != null && mounted) {
      debugPrint('✅ Contact saved, navigating back...');
      context.go('/contacts');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contact "${result.name}" added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Scan Business Card'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == ScanStep.front) {
              context.pop();
            } else {
              _resetScan();
            }
          },
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: _step == ScanStep.preview
                ? _buildPreviewStep()
                : _buildScanStep(),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildScanStep() {
    final isFront = _step == ScanStep.front;

    return Column(
      children: [
        // Step indicator
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _StepIndicator(
                number: 1,
                label: 'Front',
                active: _step == ScanStep.front,
                completed: _frontImage != null,
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color: _frontImage != null
                      ? Colors.green
                      : const Color(0xFFE5E7EB),
                ),
              ),
              _StepIndicator(
                number: 2,
                label: 'Back',
                active: _step == ScanStep.back,
                completed: _backImage != null,
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color: _backImage != null
                      ? Colors.green
                      : const Color(0xFFE5E7EB),
                ),
              ),
              _StepIndicator(
                number: 3,
                label: 'Review',
                active: _step == ScanStep.preview,
                completed: false,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Instruction
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF0284C7),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isFront
                      ? 'Scan the FRONT side of the business card'
                      : 'Scan the BACK side of the business card (or skip if not needed)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0369A1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Preview of captured image
        if ((isFront && _frontImage != null) ||
            (!isFront && _backImage != null))
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                isFront ? _frontImage! : _backImage!,
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Icon(
            Icons.credit_card_outlined,
            size: 120,
            color: const Color(0xFF64748B),
          ),

        const SizedBox(height: 32),

        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: Text('Take Photo of ${isFront ? "Front" : "Back"}'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Upload from Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              if (!isFront) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _skipBackSide,
                  child: const Text('Skip Back Side'),
                ),
              ],
            ],
          ),
        ),

        const Spacer(),

        // Tips
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFFA16207), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips for best results:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFA16207),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '• Place card on flat surface\n'
                      '• Ensure good lighting\n'
                      '• Keep card edges visible\n'
                      '• Avoid shadows and glare',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
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
    );
  }

  Widget _buildPreviewStep() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: const Row(
            children: [
              Icon(Icons.preview, color: Color(0xFF0284C7)),
              SizedBox(width: 12),
              Text(
                'Review Scanned Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Scanned images
              Row(
                children: [
                  if (_frontImage != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Front Side',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _frontImage!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_frontImage != null && _backImage != null)
                    const SizedBox(width: 12),
                  if (_backImage != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Back Side',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _backImage!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Extracted data summary
              const Text(
                'Extracted Information',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              ..._buildDataSummary(),
            ],
          ),
        ),

        // Actions
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetScan,
                    child: const Text('Scan Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _showPreviewAndSave,
                    child: const Text('Review & Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDataSummary() {
    final merged = _mergeData();
    final items = <Widget>[];

    void addItem(String label, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value.trim(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    addItem('Name', merged['name']);
    addItem('Email', merged['email']);
    addItem('Phone', merged['phone']);
    addItem('Company', merged['company']);
    addItem('Job Title', merged['job_title']);
    addItem('Address', merged['address_detail']);

    if (items.isEmpty) {
      return [
        const Text(
          'No data extracted. You can manually enter information in the next step.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontStyle: FontStyle.italic,
          ),
        ),
      ];
    }

    return items;
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.number,
    required this.label,
    required this.active,
    required this.completed,
  });

  final int number;
  final String label;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: completed
                ? Colors.green
                : active
                ? Colors.blue
                : const Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? Colors.blue : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
