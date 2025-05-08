import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _setNameController = TextEditingController();
  List<FlashcardSet> publicSets = [];

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
    final rawSets = await ApiService().getPublicSets();
    final sets =
        rawSets
            .map<FlashcardSet>((json) => FlashcardSet.fromJson(json))
            .toList();
    setState(() => publicSets = sets);
  }

  @override
  void initState() {
    super.initState();
    fetchPublicSets();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Admin Panel'),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Vytvor nový public set:', style: theme.textTheme.titleMedium),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Vytvoriť set'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: fetchPublicSets,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
              ),
              child: const Text('Zobraziť public sety'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: publicSets.length,
                itemBuilder: (context, index) {
                  final set = publicSets[index];
                  return ListTile(
                    title: Text(set.name),
                    subtitle: Text('Set ID: ${set.setId}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/editset',
                          arguments: set,
                        );
                        if (result == true) fetchPublicSets();
                      },
                    ),
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
