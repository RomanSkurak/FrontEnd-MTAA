import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../api_service.dart';

class LoginTablet extends StatefulWidget {
  const LoginTablet({super.key});

  @override
  State<LoginTablet> createState() => _LoginTabletState();
}

class _LoginTabletState extends State<LoginTablet> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vyplň všetky polia')));
      return;
    }

    final success = await ApiService().login(email, password);
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');

      await prefs.setString('local_username', email);
      await prefs.setString(
        'local_password_hash',
        sha256.convert(utf8.encode(password)).toString(),
      );

      FirebaseAnalytics.instance.logEvent(name: 'login_success');

      Navigator.pushReplacementNamed(
        context,
        role == 'admin' ? '/admin' : '/home',
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prihlásenie zlyhalo')));
    }
  }

  void handleGuestLogin() async {
    final success = await ApiService().guestLogin();
    if (success) {
      FirebaseAnalytics.instance.logEvent(name: 'guest_login');
      Navigator.pushReplacementNamed(context, '/guest');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepodarilo sa prihlásiť ako hosť')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Row(
        children: [
          // Ľavý panel s grafikou alebo brandingom
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF4A2C7A),
              child: const Center(child: Icon(Icons.school, size: 160)),
            ),
          ),
          // Pravý panel – formulár
          Expanded(
            flex: 2,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Heslo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: handleLogin,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Login'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text('Nemáš účet? Registrovať sa'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: handleGuestLogin,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Pokračovať ako hosť'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
