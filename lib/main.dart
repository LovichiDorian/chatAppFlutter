import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart'; // généré par `flutterfire configure`
import 'constants.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/home_page.dart';
import 'pages/chat_page.dart';
import 'pages/profile_page.dart';
import 'viewmodel/auth_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.setLanguageCode('fr');
  await _initPushNotifications();
  runApp(const MyApp());
}

Future<void> _initPushNotifications() async {
  final messaging = FirebaseMessaging.instance;
  if (kIsWeb) {
    // On web, request permission; service worker already added under web/.
    await messaging.requestPermission();
  }
  // Android 13+ permission
  await messaging.requestPermission();

  // Set up foreground message handling (e.g., show a SnackBar/log)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // For now, just log; UI notifications can be added later.
    // debugPrint('FCM onMessage: \\${message.notification?.title}');
  });

  // Optionally handle when app opened via notification
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    // Navigate to a chat if deep link data provided in message.data
  });

  // Get or refresh the FCM token
  // For web you must provide the VAPID key from Firebase console.
  await messaging.getToken(vapidKey: kIsWeb ? Notifications.webVapidKey : null);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: MaterialApp(
        title: AppText.appTitle,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: AppColors.bg,
          appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          chipTheme: const ChipThemeData(showCheckmark: false),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          chipTheme: const ChipThemeData(showCheckmark: false),
        ),
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashPage(),
          '/login': (_) => const LoginPage(),
          '/signup': (_) => const SignupPage(),
          '/home': (_) => const _HomeGate(),
          '/chat': (_) => const ChatPage(),
          '/profile': (_) => const ProfilePage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Gate qui route vers Home si connecté sinon Login.
class _HomeGate extends StatelessWidget {
  const _HomeGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasData) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

// Demo counter removed in favor of real pages
