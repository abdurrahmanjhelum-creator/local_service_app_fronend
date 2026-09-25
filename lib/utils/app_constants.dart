import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'LocalServe';

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electrician': return Icons.electrical_services;
      case 'plumber': return Icons.plumbing;
      case 'ac repair': return Icons.ac_unit;
      case 'carpenter': return Icons.handyman;
      case 'painter': return Icons.format_paint;
      case 'cleaner': return Icons.cleaning_services;
      default: return Icons.home_repair_service;
    }
  }

  static String? getCategoryImage(String category) {
    switch (category.toLowerCase()) {
      case 'plumber':
        return 'assets/images/plumbing_icon.png';
      case 'electrician':
        return 'assets/images/electrical_icon.png';
      case 'ac repair':
        return 'assets/images/ac_cooling_icon.png';
      case 'cleaner':
        return 'assets/images/cleaner_icon.png';
      case 'painter':
        return 'assets/images/painting_icon.png';
      case 'carpenter':
        return 'assets/images/carpenter_icon.png';
      default:
        return null; // Return null for others to use fallback IconData
    }
  }
}
