import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  /// Funkcia na hešovanie hesla pomocou SHA-256 (offline login)
  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  //AUTORIZACIA
  Future<void> checkAuth() async {
    final token = await ApiService().getToken();
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    final username = prefs.getString('local_username');
    final passwordHash = prefs.getString('local_password_hash');

    // 1. Online overenie tokenu
    if (token != null && role != null) {
      try {
        final isValid = await ApiService().verifyToken(token);
        if (isValid) {
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else if (role == 'host') {
            Navigator.pushReplacementNamed(context, '/guest');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Online token overenie zlyhalo: $e');
        // pokračujeme ďalej
      }
    }

    // 2. Offline fallback login – ak sú uložené údaje
    if (username != null && passwordHash != null) {
      debugPrint('🔌 Offline login: prihlásený ako $username');
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // 3. Inak ideš na LoginScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  //FCM TOKEN
  Future<void> getAndSendFcmToken() async {
    try {
      debugPrint('ZÍSKAVAM FCM token...');
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM token je: $fcmToken');

      if (fcmToken != null) {
        final jwtToken = await ApiService().getToken();
        if (jwtToken != null) {
          await ApiService().sendTokenToBackend(fcmToken, jwtToken);
        }
      }
    } catch (e) {
      print('Chyba pri získavaní alebo odosielaní FCM tokenu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
