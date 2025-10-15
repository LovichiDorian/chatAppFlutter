import 'package:flutter/material.dart';

class AppColors {
  // Couleur principale: blanc
  static const primary = Colors.white;
  // Couleur secondaire: bleu Flutter (brand)
  static const secondary = Color(0xFF0175C2);
  static const accent = secondary;
  static const bg = Colors.white;
}

class AppSpacing {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppText {
  static const appTitle = 'ChatApp';
}

class FirestorePaths {
  static const users = 'users';
  static String user(String uid) => '$users/$uid';
  static const chats = 'chats';
  static String chat(String chatId) => '$chats/$chatId';
  static String messages(String chatId) => '${chat(chatId)}/messages';
}
