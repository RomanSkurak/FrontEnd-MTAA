import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  //AUTORIZACIA
  Future<void> checkAuth() async {
    final token = await ApiService().getToken();
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');

    if (token == null || role == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    final isValid = await ApiService().verifyToken(token);
    if (isValid) {
      debugPrint('Halo vidis ma ?');
      await getAndSendFcmToken();

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (role == 'host') {
        Navigator.pushReplacementNamed(context, '/guest');
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
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
