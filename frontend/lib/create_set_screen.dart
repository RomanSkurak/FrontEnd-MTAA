import 'package:flutter/material.dart';
import 'api_service.dart';

class CreateSetScreen extends StatefulWidget {
  const CreateSetScreen({super.key});

  @override
  State<CreateSetScreen> createState() => _CreateSetScreenState();
}

class _CreateSetScreenState extends State<CreateSetScreen> {
  final TextEditingController _setNameController = TextEditingController();
  List<Map<String, dynamic>> cards = [];
  int? _setId;
  bool _loading = true;
  String _originalName = '';

  @override
  void initState() {
    super.initState();
    _setNameController.addListener(() {
      setState(() {});
    });
    _createInitialSet();
  }

  Future<void> _createInitialSet() async {
    int counter = 1;
    int? createdId;
    String name;

    while (createdId == null && counter <= 100) {
      name = counter == 1 ? 'Untitled set' : 'Untitled set ($counter)';
      createdId = await ApiService().createSet(name: name, isPublic: false);

      if (createdId != null) {
        setState(() {
          _setId = createdId;
          _setNameController.text = name;
          _originalName = name;
          _loading = false;
        });
        return;
      }

      counter++;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to create set')),
    );
    Navigator.pop(context);
  }

  bool _isValidCustomName() {
    final trimmed = _setNameController.text.trim();
    return trimmed.isNotEmpty && !trimmed.startsWith('Untitled set');
  }

  Future<void> _deleteSetAndExit() async {
    if (_setId != null) {
      await ApiService().deleteSet(_setId!);
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<bool> _onWillPop() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Do you really want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      await _deleteSetAndExit();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: () => _onWillPop(),
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 32),
            ),
          ),
          title: const Text(
            'New set',
            style: TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.w500),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              TextField(
                controller: _setNameController,
                maxLength: 16,
                decoration: InputDecoration(
                  labelText: 'Set name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(height: 20),
              ...cards.asMap().entries.map((entry) {
                final card = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 56,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            card['front'] ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 22),
                          color: Colors.black,
                          onPressed: () async {
                            final flashcardId = card['flashcardId'];
                            if (flashcardId != null) {
                              final result = await Navigator.pushNamed(
                                context,
                                '/editcard',
                                arguments: flashcardId,
                              );

                              if (result == 'deleted') {
                                setState(() {
                                  cards.removeAt(entry.key);
                                });
                              } else if (result == true) {
                                try {
                                  final updated = await ApiService().getFlashcardById(flashcardId);
                                  setState(() {
                                    cards[entry.key] = {
                                      'flashcardId': updated['flashcard_id'],
                                      'front': updated['front_side'] ?? '',
                                      'back': updated['back_side'] ?? '',
                                    };
                                  });
                                } catch (e) {
                                  debugPrint('Error loading updated flashcard: $e');
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              InkWell(
                onTap: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    '/newcard',
                    arguments: _setId,
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    setState(() {
                      cards.add({
                        'flashcardId': result['id'],
                        'front': result['front'],
                        'back': result['back'],
                      });
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add, size: 26),
                      SizedBox(width: 8),
                      Text('add card', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_setId == null || !_isValidCustomName())
                      ? null
                      : () async {
                          final newName = _setNameController.text.trim();
                          if (newName != _originalName) {
                            await ApiService().updateSetName(_setId!, newName);
                          }
                          Navigator.pop(context, true);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Create set',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (!_isValidCustomName())
                const Text(
                  'You must change the set name',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
