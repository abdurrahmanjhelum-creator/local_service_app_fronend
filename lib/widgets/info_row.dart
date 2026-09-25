import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isRating;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isRating = false,
    this.iconColor,
    this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultIconColor = isRating ? Colors.amber : Colors.grey[600];
    final effectiveIconColor = iconColor ?? defaultIconColor;

    return Row(
      children: [
        if (iconBackgroundColor != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: effectiveIconColor,
            ),
          )
        else
          Icon(
            icon,
            size: 20,
            color: effectiveIconColor,
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
