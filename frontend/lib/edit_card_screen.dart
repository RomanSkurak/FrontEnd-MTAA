import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import 'package:permission_handler/permission_handler.dart';

class EditCardScreen extends StatefulWidget {
  final int flashcardId;

  const EditCardScreen({super.key, required this.flashcardId});

  @override
  State<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends State<EditCardScreen>
    with SingleTickerProviderStateMixin {
  bool isFrontSide = true;

  String frontText = '';
  String backText = '';
  Uint8List? frontImage;
  Uint8List? backImage;

  String _originalFrontText = '';
  String _originalBackText = '';
  Uint8List? _originalFrontImage;
  Uint8List? _originalBackImage;

  late AnimationController _controller;
  late Animation<double> _animation;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(_controller);
    _loadFlashcardData();
  }

  Future<void> _loadFlashcardData() async {
    try {
      final data = await ApiService().getFlashcardById(widget.flashcardId);
      setState(() {
        frontText = data['front_side'] ?? '';
        backText = data['back_side'] ?? '';

        final frontBase64 = data['image_front'];
        final backBase64 = data['image_back'];

        if (frontBase64 != null && frontBase64.isNotEmpty) {
          final cleanedFront = frontBase64.replaceAll(
            RegExp(r'[^A-Za-z0-9+/=]+'),
            '',
          );
          frontImage = base64Decode(cleanedFront);
        }

        if (backBase64 != null && backBase64.isNotEmpty) {
          final cleanedBack = backBase64.replaceAll(
            RegExp(r'[^A-Za-z0-9+/=]+'),
            '',
          );
          backImage = base64Decode(cleanedBack);
        }
      });
    } catch (e) {
      debugPrint('Error loading flashcard: $e');
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isCardFilled() {
    return (frontText.trim().isNotEmpty || frontImage != null) &&
        (backText.trim().isNotEmpty || backImage != null);
  }

  bool _hasUnsavedChanges() {
    if (frontText.trim() != _originalFrontText.trim()) return true;
    if (backText.trim() != _originalBackText.trim()) return true;

    if ((frontImage == null && _originalFrontImage != null) ||
        (frontImage != null && _originalFrontImage == null)) {
      return true;
    }
    if (frontImage != null && _originalFrontImage != null) {
      if (!listEquals(frontImage, _originalFrontImage)) {
        return true;
      }
    }

    if ((backImage == null && _originalBackImage != null) ||
        (backImage != null && _originalBackImage == null)) {
      return true;
    }
    if (backImage != null && _originalBackImage != null) {
      if (!listEquals(backImage, _originalBackImage)) {
        return true;
      }
    }

    return false;
  }

  Future<bool> _confirmDiscardChanges() async {
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
              'You have unsaved changes. Do you want to leave without saving?',
            ),
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

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges()) return true;

    final discard = await _confirmDiscardChanges();
    return discard;
  }

  void _flipCard() {
    if (isFrontSide) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => isFrontSide = !isFrontSide);
  }

  Future<void> _editText() async {
    final controller = TextEditingController(
      text: isFrontSide ? frontText : backText,
    );

    final typedText = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 360,
              height: 540,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 8),
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      maxLines: null,
                      maxLength: 500,
                      expands: true,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed:
                            () =>
                                Navigator.pop(context, controller.text.trim()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (typedText != null) {
      setState(() {
        if (isFrontSide) {
          frontText = typedText;
          frontImage = null;
        } else {
          backText = typedText;
          backImage = null;
        }
      });
    }
  }

  bool isPickingImage = false;

  Future<void> _pickImage() async {
    if (isPickingImage) return;

    setState(() => isPickingImage = true);

    final status = await Permission.photos.request(); // iOS
    final androidStatus = await Permission.storage.request(); // Android

    if (!status.isGranted && !androidStatus.isGranted) {
      setState(() => isPickingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission to access gallery denied')),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          if (isFrontSide) {
            frontImage = bytes;
            frontText = '';
          } else {
            backImage = bytes;
            backText = '';
          }
        });
      }
    } catch (e) {
      debugPrint('Image picking failed: $e');
    } finally {
      setState(() => isPickingImage = false);
    }
  }

  Future<void> _confirmAndDeleteCard() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete card?'),
            content: const Text(
              'Are you sure you want to delete this card? This action cannot be undone.',
            ),
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
      final success = await ApiService().deleteFlashcard(widget.flashcardId);
      if (success && mounted) {
        Navigator.pop(context, 'deleted');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final cardFrontColor = isDark ? Colors.grey[800] : const Color(0xFFE1E1E1);
    final cardBackColor = isDark ? Colors.grey[700] : const Color(0xFFC1C1C1);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
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
              child: Icon(
                Icons.arrow_back,
                color: theme.iconTheme.color,
                size: 32,
              ),
            ),
          ),
          title: Text(
            isFrontSide ? 'Front side' : 'Back side',
            style: theme.textTheme.titleMedium,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _flipCard,
                child: SizedBox(
                  width: 360,
                  height: 540,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final isBack = _animation.value >= pi / 2;
                      final content =
                          isBack
                              ? (backImage != null
                                  ? Image.memory(
                                    backImage!,
                                    fit: BoxFit.contain,
                                  )
                                  : Text(
                                    backText,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: textColor,
                                    ),
                                  ))
                              : (frontImage != null
                                  ? Image.memory(
                                    frontImage!,
                                    fit: BoxFit.contain,
                                  )
                                  : Text(
                                    frontText,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: textColor,
                                    ),
                                  ));

                      return Transform(
                        alignment: Alignment.center,
                        transform:
                            Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(_animation.value),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBack ? cardBackColor : cardFrontColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform(
                                alignment: Alignment.center,
                                transform:
                                    isBack
                                        ? Matrix4.rotationY(pi)
                                        : Matrix4.identity(),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    24,
                                    24,
                                    48,
                                  ),
                                  child: content,
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                child: GestureDetector(
                                  onTap: _flipCard,
                                  child: Icon(
                                    Icons.sync,
                                    size: 28,
                                    color: textColor.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 38),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _editText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.grey[800] : Colors.grey[200],
                      foregroundColor: textColor,
                    ),
                    child: const Text('Change text'),
                  ),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.grey[800] : Colors.grey[200],
                      foregroundColor: textColor,
                    ),
                    child: const Text('Change image'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 60),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _isCardFilled()
                          ? () async {
                            String baseName =
                                frontText.trim().isNotEmpty
                                    ? (frontText.length > 15
                                        ? '${frontText.substring(0, 15)}...'
                                        : frontText)
                                    : '[image]';

                            final success = await ApiService().updateFlashcard(
                              flashcardId: widget.flashcardId,
                              frontText: frontText,
                              backText: backText,
                              frontImage: frontImage,
                              backImage: backImage,
                              name: baseName,
                            );

                            if (success && mounted) {
                              Navigator.pop(context, true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to update card'),
                                ),
                              );
                            }
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Update card'),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirmAndDeleteCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Delete card',
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
