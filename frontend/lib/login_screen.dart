import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

    final api = ApiService();
    final success = await api.login(email, password);

    if (success) {
      // TODO: Presmerovanie do domovskej obrazovky
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role');
      // po úspešnom login response
      await prefs.setString('local_username', email);
      await prefs.setString(
        'local_password_hash',
        sha256.convert(utf8.encode(password)).toString(),
      );

      FirebaseAnalytics.instance.logEvent(name: 'login_success');

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Úspešné prihlásenie')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prihlásenie zlyhalo')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 💡 Získaj aktuálnu tému
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 96),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
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
                child: const Text('Login'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('Nemáš účet? Registrovať sa'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final response = await ApiService().guestLogin();
                  if (response) {
                    Navigator.pushReplacementNamed(context, '/guest');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nepodarilo sa prihlásiť ako hosť'),
                      ),
                    );
                  }
                },
                child: const Text('Pokračovať ako hosť'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
