import 'package:flutter/material.dart';
import 'api_service.dart';
import 'login_screen.dart';
import 'main.dart'; // 👈 pridáme import kvôli MyApp.of(context)

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool isDarkMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    setState(() {
      isDarkMode = Theme.of(context).brightness == Brightness.dark;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    await ApiService().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _toggleTheme(bool value) {
    final mode = value ? ThemeMode.dark : ThemeMode.light;
    MyApp.of(context)?.setTheme(mode);
    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nastavenia')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: isDarkMode,
              onChanged: _toggleTheme,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _handleLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 252, 69, 56),
                foregroundColor: Colors.black,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
