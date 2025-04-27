import 'package:flutter/material.dart';
import 'api_service.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  List<dynamic> publicSets = [];

  @override
  void initState() {
    super.initState();
    fetchPublicSets();
  }

  Future<void> fetchPublicSets() async {
    try {
      final sets = await ApiService().getPublicSets();
      setState(() {
        publicSets = sets;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chyba pri načítaní setov: $e')));
    }
  }

  Future<void> _logout() async {
    await ApiService().logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Mode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: fetchPublicSets,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  foregroundColor: theme.colorScheme.onSecondaryContainer,
                ),
                child: const Text('Zobraziť public sety'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dostupné verejné sety:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            Expanded(
              child:
                  publicSets.isEmpty
                      ? const Center(child: Text('Žiadne sety k dispozícii'))
                      : ListView.builder(
                        itemCount: publicSets.length,
                        itemBuilder: (context, index) {
                          final set = publicSets[index];
                          return ListTile(
                            title: Text(set['name']),
                            subtitle: Text('Set ID: ${set['set_id']}'),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
