import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';

class EditSetScreen extends StatefulWidget {
  final FlashcardSet flashcardSet;

  const EditSetScreen({super.key, required this.flashcardSet});

  @override
  State<EditSetScreen> createState() => _EditSetScreenState();
}

class _EditSetScreenState extends State<EditSetScreen> {
  final TextEditingController _setNameController = TextEditingController();
  List<Map<String, dynamic>> cards = [];
  bool _loading = true;
  late int _setId;

  late String _originalName;

  @override
  void initState() {
    super.initState();
    _setId = widget.flashcardSet.setId;
    _originalName = widget.flashcardSet.name;
    _setNameController.text = _originalName;

    _setNameController.addListener(() {
      setState(() {});
    });

    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    try {
      final result = await ApiService().loadSetWithFlashcards(_setId);
      final List<dynamic> fetchedCards = result['cards'];

      setState(() {
        cards = fetchedCards.map<Map<String, dynamic>>((f) => {
              'flashcardId': f['flashcard_id'],
              'front': f['front_side'] ?? '',
              'back': f['back_side'] ?? '',
            }).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading flashcards: $e");
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  bool _isValidCustomName() {
    final trimmed = _setNameController.text.trim();
    return trimmed.isNotEmpty;
  }

  bool _hasUnsavedChanges() {
    return _setNameController.text.trim() != _originalName.trim();
  }

  Future<void> _confirmAndDeleteSet() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete set?'),
        content: const Text(
            'Are you sure you want to delete this set? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final success = await ApiService().deleteSet(_setId);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete set')),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges()) {
      return true;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard name change?'),
        content: const Text(
            'You have unsaved changes to the set name. Do you want to leave without saving the new name?'),
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

    return (shouldDiscard == true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
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
              onTap: () async {
                final canPop = await _onWillPop();
                if (canPop && mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 32),
            ),
          ),
          title: const Text(
            'Edit set',
            style: TextStyle(
              fontSize: 22,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
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
                            final result = await Navigator.pushNamed(
                              context,
                              '/editcard',
                              arguments: card['flashcardId'],
                            );

                            if (result == 'deleted') {
                              _loadFlashcards();
                            } else if (result == true) {
                              try {
                                final updated = await ApiService().getFlashcardById(card['flashcardId']);
                                setState(() {
                                  cards[entry.key] = {
                                    'flashcardId': updated['flashcard_id'],
                                    'front': updated['front_side'] ?? '',
                                    'back': updated['back_side'] ?? '',
                                  };
                                });
                              } catch (e) {
                                debugPrint("Error loading the updated card: $e");
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
                    final front = result['front'] ?? '';
                    final back = result['back'] ?? '';
                    final id = result['id'];

                    setState(() {
                      cards.add({'flashcardId': id, 'front': front, 'back': back});
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
                      Text('Add card', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 60),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: !_isValidCustomName()
                      ? null
                      : () async {
                          final newName = _setNameController.text.trim();
                          if (newName != _originalName) {
                            await ApiService().updateSetName(_setId, newName);
                          }
                          Navigator.pop(context, true);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    elevation: 3,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update set',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _confirmAndDeleteSet();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    elevation: 3,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Delete set',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
