import 'package:flutter/material.dart';

class ContactAvatar extends StatelessWidget {
  const ContactAvatar({required this.name, this.size = 56, super.key});

  final String name;
  final double size;

  String get initials {
    final parts = name.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((s) => s[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE2E8F0),
      ),
      child: Text(
        initials,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
    );
  }
}
