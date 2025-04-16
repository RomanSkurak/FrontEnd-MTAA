import 'package:flutter/material.dart';
import 'api_service.dart';
import 'login_screen.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await ApiService().logout();

    // Po odhlásení presmeruj späť na login obrazovku
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Nastavenia')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _handleLogout(context),
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
