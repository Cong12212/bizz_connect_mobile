import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class CameraScannerPage extends StatefulWidget {
  const CameraScannerPage({super.key, required this.isQrMode});

  final bool isQrMode;

  @override
  State<CameraScannerPage> createState() => _CameraScannerPageState();
}

class _CameraScannerPageState extends State<CameraScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  bool _isProcessing = false;
  bool _flashOn = false;

  @override
  void reassemble() {
    super.reassemble();
    if (_controller != null) {
      _controller!.pauseCamera();
      _controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() => _controller = controller);

    controller.scannedDataStream.listen((scanData) {
      if (_isProcessing) return;
      if (scanData.code == null || scanData.code!.isEmpty) return;

      setState(() => _isProcessing = true);
      _controller?.pauseCamera();
      Navigator.pop(context, scanData.code);
    });
  }

  Future<void> _toggleFlash() async {
    if (_controller != null) {
      await _controller!.toggleFlash();
      final status = await _controller!.getFlashStatus();
      setState(() => _flashOn = status ?? false);
    }
  }

  Future<void> _flipCamera() async {
    await _controller?.flipCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.isQrMode ? 'Scan QR Code' : 'Scan Business Card'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: _flipCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          // QR Scanner view
          if (widget.isQrMode)
            QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.white,
                borderRadius: 12,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 250,
              ),
            )
          else
            // For business card mode, show placeholder
            Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  'Camera view for business card',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

          // Overlay with instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.isQrMode
                        ? 'Point camera at QR code'
                        : 'Position business card in frame',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!widget.isQrMode) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isProcessing ? null : _captureImage,
                      icon: const Icon(Icons.camera),
                      label: const Text('Capture'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureImage() async {
    setState(() => _isProcessing = true);
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please use "Upload from Gallery" for business cards',
            ),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
