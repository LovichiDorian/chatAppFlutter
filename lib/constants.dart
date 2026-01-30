import 'package:flutter/material.dart';

/// Palette de couleurs moderne avec dégradés
class AppColors {
  // Couleurs principales - Palette moderne violet/indigo
  static const primary = Color(0xFF6366F1); // Indigo vibrant
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDark = Color(0xFF4F46E5);
  
  // Couleurs secondaires - Accent cyan/teal
  static const secondary = Color(0xFF06B6D4); // Cyan moderne
  static const secondaryLight = Color(0xFF22D3EE);
  static const secondaryDark = Color(0xFF0891B2);
  
  // Couleurs d'accent
  static const accent = Color(0xFFF472B6); // Rose/pink pour accents
  static const accentLight = Color(0xFFF9A8D4);
  
  // Couleurs de surface
  static const surface = Color(0xFFFAFAFC);
  static const surfaceLight = Colors.white;
  static const surfaceDark = Color(0xFF1E1E2E);
  
  // Texte
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);
  
  // États
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  
  // Gradients
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF8B5CF6)],
  );
  
  static const gradientSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, Color(0xFF06B6D4)],
  );
  
  static const gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFFA855F7)],
  );
  
  static const gradientBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF8FAFC),
      Color(0xFFEEF2FF),
      Color(0xFFF0F9FF),
    ],
  );
  
  static const gradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1E1E2E),
      Color(0xFF2D2D44),
    ],
  );

  // Couleurs de bulles de chat
  static const bubbleSent = primary;
  static const bubbleReceived = Color(0xFFF1F5F9);
}

class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class AppRadius {
  static const xs = 6.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const full = 999.0;
}

class AppShadows {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get glow => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
}

class AppText {
  static const appTitle = 'ChatApp';
  static const appTagline = 'Connectez-vous, échangez, partagez';
}

class FirestorePaths {
  static const users = 'users';
  static String user(String uid) => '$users/$uid';
  static const chats = 'chats';
  static String chat(String chatId) => '$chats/$chatId';
  static String messages(String chatId) => '${chat(chatId)}/messages';
}
