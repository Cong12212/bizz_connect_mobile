import 'package:flutter/material.dart';

class ActionIconButton extends StatelessWidget {
  const ActionIconButton({
    required this.icon,
    required this.onTap,
    this.label,
    this.showCaption = true,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final bool showCaption;

  @override
  Widget build(BuildContext context) {
    final iconBtn = IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      tooltip: label,
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(10),
        minimumSize: const Size(40, 40),
      ),
    );

    if (!showCaption || (label == null)) return iconBtn;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconBtn,
        Text(
          label!,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
