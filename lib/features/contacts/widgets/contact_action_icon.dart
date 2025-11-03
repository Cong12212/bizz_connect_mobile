import 'package:flutter/material.dart';

class ContactActionIcon extends StatelessWidget {
  const ContactActionIcon({
    required this.icon,
    required this.onTap,
    this.label,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF475569)),
            if (label != null) ...[
              const SizedBox(height: 2),
              Text(
                label!,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
