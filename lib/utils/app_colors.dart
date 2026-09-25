import 'package:flutter/material.dart';

/// App Colors - Centralized color management for the application
class AppColors {
  AppColors._();

  // ==================== PRIMARY COLORS ====================
  static const Color primary = Color(0xFF1E3A8A); // Deep Royal Navy Blue
  static const Color primary10 = Color(0x1A1E3A8A);
  static const Color primary20 = Color(0x331E3A8A);
  static const Color primary30 = Color(0x4D1E3A8A);
  static const Color primary50 = Color(0x801E3A8A);
  static const Color primaryDark = Color(0xFF0F172A); // Slate Navy Dark
  static const Color primaryLight = Color(0xFF3B82F6);

  // ==================== SECONDARY COLORS ====================
  static const Color secondary = Color(0xFF0D9488); // Deep Teal Accent
  static const Color secondary10 = Color(0x1A0D9488);
  static const Color secondary20 = Color(0x330D9488);
  static const Color secondaryDark = Color(0xFF115E59);
  static const Color secondaryLight = Color(0xFF2DD4BF);

  // ==================== NEUTRAL COLORS ====================
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray50 = Color(0xFFF8FAFC);
  static const Color gray100 = Color(0xFFF1F5F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray600 = Color(0xFF475569);
  static const Color gray700 = Color(0xFF334155);
  static const Color gray800 = Color(0xFF1E293B);
  static const Color gray900 = Color(0xFF0F172A);

  // ==================== BACKGROUND COLORS ====================
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF8FAFC);
  static const Color backgroundTertiary = Color(0xFFF1F5F9);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // ==================== TEXT COLORS ====================
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFF94A3B8);
  static const Color textLink = Color(0xFF1E3A8A);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ==================== SEMANTIC COLORS ====================
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF065F46);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFF991B1B);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF92400E);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1E40AF);

  // ==================== BORDER COLORS ====================
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocus = Color(0xFF1E3A8A);
  static const Color borderError = Color(0xFFEF4444);
  static const Color borderSuccess = Color(0xFF10B981);
  static const Color divider = Color(0xFFE2E8F0);

  // ==================== NAVIGATION COLORS ====================
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navActive = Color(0xFF1E3A8A);
  static const Color navInactive = Color(0xFF94A3B8);
  static const Color navBorder = Color(0xFFE2E8F0);

  // ==================== CARD COLORS ====================
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color cardShadow = Color(0x0A000000);

  // ==================== STATUS COLORS ====================
  static const Color statusOnline = Color(0xFF10B981);
  static const Color statusOffline = Color(0xFF94A3B8);
  static const Color statusAway = Color(0xFFF59E0B);
  static const Color statusBusy = Color(0xFFEF4444);

  // ==================== GRADIENTS ====================
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF2DD4BF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Ultra-Premium "Executive Navy Luxe" Smooth Background Gradient
  /// Starts with a very sophisticated rich corporate Navy tint, smoothly fading into clean ice slate.
  static const LinearGradient appBackgroundGradient = LinearGradient(
    colors: [
      Color(0xFFE0F2FE), // Ice Sky/Aqua Soft Touch
      Color(0xFFF1F5F9), // Slate Clean Light Gray
      Color(0xFFFFFFFF), // Pure Corporate White
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient splashBackgroundGradient = LinearGradient(
    colors: [
      Color(0xFF02006C),
      Color(0xFF090088),
      Color(0xFF6A329F),
      Color(0xFFFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
