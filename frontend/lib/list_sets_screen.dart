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
      setState(() {
        sets = loadedSets;
      });
    } catch (e) {
      print('Error loading sets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 32),
          ),
        ),
        title: const Text(
          'List of your sets',
          style: TextStyle(
            fontSize: 25,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: sets.isEmpty
          ? const Center(
              child: Text(
                "You don't have any flashcard sets yet",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : ListView.builder(
              itemCount: sets.length,
              itemBuilder: (context, index) {
                final set = sets[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.grey[200],
                    elevation: 1.5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 64,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              set.name,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 25),
                              color: Colors.black,
                              onPressed: () async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  '/editset',
                                  arguments: set,
                                );

                                if (result == true) {
                                  _loadSets();
                                }
                              },
                            ),
                          ],
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
            if (result == true) {
              _loadSets();
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black),
                ),
                child: const Icon(Icons.add, color: Colors.black),
              ),
              const SizedBox(width: 10),
              const Text(
                'Create a New Set',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
