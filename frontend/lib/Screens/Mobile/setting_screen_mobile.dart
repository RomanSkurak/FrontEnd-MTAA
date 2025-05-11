import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../Controllers/login_screen.dart';
import '../../main.dart';

class SettingScreenMobile extends StatefulWidget {
  const SettingScreenMobile({super.key});

  @override
  State<SettingScreenMobile> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreenMobile> {
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
    final theme = Theme.of(context);
    final myApp = MyApp.of(context);
    final isLargeText = myApp?.isLargeText ?? false;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: isLargeText ? 40 : 30),
          onPressed: () => Navigator.pop(context, true),
        ),
        centerTitle: true,
        title: Text(
          'Settings',
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

            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final deleted = await ApiService().resetStatistics();
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Deleted session(s)',
                        style: TextStyle(fontSize: isLargeText ? 20 : 16),
                      ),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to reset statistics: $e',
                        style: TextStyle(fontSize: isLargeText ? 20 : 16),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeText ? 24 : 16,
                  vertical: isLargeText ? 18 : 12,
                ),
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: Text(
                'Reset Statistics',
                style: TextStyle(fontSize: isLargeText ? 20 : 16),
              ),
            ),
            const SizedBox(height: 500),
            ElevatedButton(
              onPressed: () => _handleLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 250, 22, 6),
                foregroundColor: const Color.fromARGB(255, 253, 253, 253),
                padding: EdgeInsets.symmetric(
                  vertical: isLargeText ? 20 : 12,
                  horizontal: isLargeText ? 40 : 24,
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: isLargeText ? 25 : 18,
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
