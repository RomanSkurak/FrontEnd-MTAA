import 'package:flutter/material.dart';
import 'api_service.dart';
import 'main.dart';

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
    Navigator.of(context).pop();
  }

  bool _isValidCustomName() {
    final trimmed = _setNameController.text.trim();
    return trimmed.isNotEmpty && !trimmed.startsWith('Untitled set');
  }

  Future<void> _deleteSet() async {
    if (_setId != null) {
      await ApiService().deleteSet(_setId!);
    }
  }

  Future<bool> _onWillPop() async {
    final isLargeText = MyApp.of(context)?.isLargeText ?? false;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Discard changes?',
          style: TextStyle(fontSize: isLargeText ? 24 : 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You have unsaved changes. Do you really want to leave?',
          style: TextStyle(fontSize: isLargeText ? 20 : 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'No',
              style: TextStyle(fontSize: isLargeText ? 20 : 16),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Yes',
              style: TextStyle(fontSize: isLargeText ? 20 : 16),
            ),
          ),
        ],
      ),
    ) == true;

    if (shouldLeave) {
      await _deleteSet();
    }
    return shouldLeave;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color;
    final isLargeText = MyApp.of(context)?.isLargeText ?? false;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.appBarTheme.backgroundColor,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: () async {
                if (await _onWillPop()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: Icon(
                Icons.arrow_back,
                color: theme.iconTheme.color,
                size: 32,
              ),
            ),
          ),
          title: Text(
            'New set',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: isLargeText ? FontWeight.bold : FontWeight.w500,
              fontSize: isLargeText ? 34 : null,
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
                 style: TextStyle(
                  fontSize: isLargeText ? 24 : null,
                ),
                decoration: InputDecoration(
                  labelText: 'Enter set name',
                  labelStyle: TextStyle(color: textColor, fontSize: isLargeText ? 23 : null),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                buildCounter: (
                  BuildContext context, {
                  required int currentLength,
                  required bool isFocused,
                  required int? maxLength,
                }) {
                  return Text(
                    '$currentLength/$maxLength',
                    style: TextStyle(
                      fontSize: isLargeText ? 18 : null,
                      color: theme.hintColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              ...cards.asMap().entries.map((entry) {
                final card = entry.value;
                final front = (card['front'] as String?)?.trim() ?? '';
                final imageFront = card['image_front'];
                final displayName =
                    front.isNotEmpty ? front : (imageFront != null ? '[image]' : '');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: isLargeText ? 66 : 56,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: isLargeText ? 22 : 16),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, size: isLargeText ? 28 : 22),
                          color: theme.iconTheme.color,
                          onPressed: () async {
                            final flashcardId = card['flashcardId'];
                            if (flashcardId != null) {
                              final result = await Navigator.pushNamed(
                                context,
                                '/editcard',
                                arguments: flashcardId,
                              );
                              if (result == 'deleted') {
                                setState(() => cards.removeAt(entry.key));
                              } else if (result == true) {
                                final updated = await ApiService().getFlashcardById(flashcardId);
                                setState(() {
                                  cards[entry.key] = {
                                    'flashcardId': updated['flashcard_id'],
                                    'front': updated['front_side'] ?? '',
                                    'back': updated['back_side'] ?? '',
                                    'image_front': updated['image_front'],
                                  };
                                });
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
                  if (result is Map<String, dynamic>) {
                    setState(() {
                      cards.add({
                        'flashcardId': result['id'],
                        'front': result['front'],
                        'back': result['back'],
                        'image_front': result['image_front'],
                      });
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Card was added')),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: isLargeText ? 36 : 26, color: theme.iconTheme.color),
                      const SizedBox(width: 8),
                      Text(
                        'add card',
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: isLargeText ? 25 : 18),
                      ),
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
                          Navigator.of(context).pop(true);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Create set',
                    style: TextStyle(
                      fontSize: isLargeText ? 25 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (!_isValidCustomName())
                Text(
                  'You must change the set name',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: isLargeText ? 19 : 14,
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
