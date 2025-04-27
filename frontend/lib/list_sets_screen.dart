import 'package:flutter/material.dart';
import 'models.dart';
import 'api_service.dart';

class ListOfSetsScreen extends StatefulWidget {
  const ListOfSetsScreen({Key? key}) : super(key: key);

  @override
  State<ListOfSetsScreen> createState() => _ListOfSetsScreenState();
}

class _ListOfSetsScreenState extends State<ListOfSetsScreen> {
  List<FlashcardSet> sets = [];

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    try {
      final loadedSets = await ApiService().fetchSets();
      setState(() => sets = loadedSets);
    } catch (e) {
      print('Error loading sets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back,
              color: theme.iconTheme.color,
              size: 32,
            ),
          ),
        ),
        title: Text(
          'List of your sets',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body:
          sets.isEmpty
              ? Center(
                child: Text(
                  "You don't have any flashcard sets yet",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              )
              : ListView.builder(
                itemCount: sets.length,
                itemBuilder: (context, index) {
                  final set = sets[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color:
                              theme.brightness == Brightness.dark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                        ),
                      ),
                      color: theme.cardColor,
                      elevation: 1.5,

                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/learn',
                            arguments: set.setId,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            height: 64,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  set.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 25),
                                  color: theme.iconTheme.color,
                                  onPressed: () async {
                                    final result = await Navigator.pushNamed(
                                      context,
                                      '/editset',
                                      arguments: set,
                                    );
                                    if (result == true) _loadSets();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: 48,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final result = await Navigator.pushNamed(context, '/create');
            if (result == true) _loadSets();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.iconTheme.color ?? Colors.black,
                  ),
                ),
                child: Icon(Icons.add, color: theme.iconTheme.color),
              ),
              const SizedBox(width: 10),
              Text('Create a New Set', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
