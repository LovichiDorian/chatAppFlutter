import 'package:flutter/material.dart';

class AppColors {
  static const primary = Colors.deepPurple;
  static const accent = Colors.deepPurpleAccent;
  static const bg = Color(0xFFF6F6F6);
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

/// Notifications-related constants.
class Notifications {
  /// Web Push VAPID key from Firebase Console > Project Settings > Cloud Messaging.
  /// If null, getToken() on web may return null and push notifications won't work.
  /// Replace with your key like:
  /// "BPr...your-public-vapid-key...".
  static const String? webVapidKey = null;
}
