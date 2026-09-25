import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';

class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;
  final Color? color;
  final bool useContainer;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 24,
    this.color,
    this.useContainer = true,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = AppConstants.getCategoryImage(category);
    final iconData = AppConstants.getCategoryIcon(category);
    
    Widget content;
    
    if (assetPath != null) {
      content = Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        // If the asset is a simple transparent icon, we can tint it if needed
        // but usually custom category icons are colorful and shouldn't be tinted.
      );
    } else {
      content = Icon(
        iconData,
        size: size,
        color: color ?? AppColors.primary,
      );
    }

    if (!useContainer) return content;

    return Container(
      padding: EdgeInsets.all(size * 0.4),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: content,
    );
  }
}
