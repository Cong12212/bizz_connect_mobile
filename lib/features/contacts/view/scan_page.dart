import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner, size: 96),
              const SizedBox(height: 12),
              const Text('Scan business card / QR (coming soon)'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  // TODO: integrate camera/OCR. Temporarily mock scan data:
                  final mock = {
                    'name': 'Nguyen Van A',
                    'company': 'ABC Co.',
                    'email': 'a.nguyen@abc.co',
                    'phone': '+84 912 345 678',
                    'address': 'HCMC',
                    'notes': 'From trade show',
                  };
                  // navigate to create contact form, can pass via query/extra
                  context.go('/contacts/new', extra: mock);
                },
                child: const Text('Mock scan & add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
