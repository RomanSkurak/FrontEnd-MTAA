import 'package:flutter/material.dart';
import 'api_service.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await ApiService().logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _navigateToStatistics(BuildContext context) async {
    final stats = await ApiService().getStatistics();
    if (stats != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StatisticsScreen(stats: stats)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load statistics")),
      );
    }
  }

  void _navigateToSets(BuildContext context) {
    Navigator.pushNamed(context, '/sets');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _navigateToStatistics(context),
              child: const Text("Statistics"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _navigateToSets(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go to My Sets',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
