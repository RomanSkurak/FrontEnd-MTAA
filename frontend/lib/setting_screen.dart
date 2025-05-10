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
    final myApp = MyApp.of(context);
    final isLargeText = myApp?.isLargeText ?? false;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
          size: isLargeText ? 40 : 30),
          onPressed: () => Navigator.pop(context, true),
        ),
        centerTitle: true,
        title: Text(
          'Nastavenia',
          style: TextStyle(
            fontSize: isLargeText ? 35 : 25,
            fontWeight: isLargeText ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  fontSize: isLargeText ? 25 : 16,
                  fontWeight: isLargeText ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              value: isDarkMode,
              onChanged: _toggleTheme,
            ),
            SwitchListTile(
               title: Text(
                'Improve readability',
                style: TextStyle(
                  fontSize: isLargeText ? 25 : 16,
                  fontWeight: isLargeText ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              value: isLargeText,
              onChanged: (value) {
                myApp?.setLargeText(value);
                setState(() {});
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _handleLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 252, 69, 56),
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(
                  vertical: isLargeText ? 20 : 12,
                  horizontal: isLargeText ? 40 : 24,
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: isLargeText ? 25 : 16,
                  fontWeight: isLargeText ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
