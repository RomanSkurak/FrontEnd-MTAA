import 'package:flutter/material.dart';
import 'api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _setNameController = TextEditingController();
  List<dynamic> publicSets = [];

  Future<void> createPublicSet() async {
    final name = _setNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Zadaj názov setu')));
      return;
    }

    try {
      final success = await ApiService().createPublicSet(name);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Set vytvorený')));
        _setNameController.clear();
        fetchPublicSets();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nepodarilo sa vytvoriť')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chyba: $e')));
    }
  }

  Future<void> fetchPublicSets() async {
    final sets = await ApiService().getPublicSets();
    setState(() {
      publicSets = sets;
    });
  }

  Future<void> _logout() async {
    await ApiService().logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void initState() {
    super.initState();
    fetchPublicSets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Odhlásiť sa',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Vytvor nový public set:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _setNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Názov setu',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: createPublicSet,
              child: const Text('Vytvoriť set'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: fetchPublicSets,
              child: const Text('Zobraziť public sety'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
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
