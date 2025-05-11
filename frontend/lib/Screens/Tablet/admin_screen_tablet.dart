import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../models.dart';

class AdminScreenTablet extends StatefulWidget {
  const AdminScreenTablet({super.key});

  @override
  State<AdminScreenTablet> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreenTablet> {
  final TextEditingController _setNameController = TextEditingController();
  List<FlashcardSet> publicSets = [];

  Future<void> createPublicSet() async {
    final name = _setNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the name of the set')),
      );
      return;
    }

    try {
      final success = await ApiService().createPublicSet(name);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Set created')));
        _setNameController.clear();
        fetchPublicSets();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to create')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create a new public set:',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _setNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Set name',
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: createPublicSet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('Create a set'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: fetchPublicSets,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                  ),
                  child: const Text('View public sets'),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      publicSets.isEmpty
                          ? Center(
                            child: Text(
                              'No sets to display.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          )
                          : ListView.builder(
                            itemCount: publicSets.length,
                            itemBuilder: (context, index) {
                              final set = publicSets[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
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
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
