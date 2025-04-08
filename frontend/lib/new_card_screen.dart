import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:math';
import 'api_service.dart';

class NewCardScreen extends StatelessWidget {
  const NewCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final int setId = ModalRoute.of(context)!.settings.arguments as int;
    return NewCardScreenContent(setId: setId);
  }
}

class NewCardScreenContent extends StatefulWidget {
  final int setId;

  const NewCardScreenContent({super.key, required this.setId});

  @override
  State<NewCardScreenContent> createState() => _NewCardScreenContentState();
}

class _NewCardScreenContentState extends State<NewCardScreenContent>
    with SingleTickerProviderStateMixin {
  bool isFrontSide = true;
  String frontText = '';
  String backText = '';
  Uint8List? frontImage;
  Uint8List? backImage;

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
                        onPressed: () => Navigator.pop(context, controller.text.trim()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 32),
          ),
        ),
        title: Text(
          isFrontSide ? 'Front side' : 'Back side',
          style: const TextStyle(color: Colors.black, fontSize: 22),
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
                    final content = isBack
                        ? (backImage != null
                            ? Image.memory(backImage!, fit: BoxFit.contain)
                            : Text(backText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)))
                        : (frontImage != null
                            ? Image.memory(frontImage!, fit: BoxFit.contain)
                            : Text(frontText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)));

                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(_animation.value),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isBack ? const Color(0xFFC1C1C1) : const Color(0xFFE1E1E1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform(
                              alignment: Alignment.center,
                              transform: isBack ? Matrix4.rotationY(pi) : Matrix4.identity(),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                                child: content,
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              child: GestureDetector(
                                onTap: _flipCard,
                                child: const Icon(Icons.sync, size: 28, color: Colors.black54),
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
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Change text'),
                ),
                ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
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
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isCardFilled()
                    ? () async {
                        final int? cardId = await ApiService().saveCardToSet(
                          setId: widget.setId,
                          frontText: frontText,
                          backText: backText,
                          frontImage: frontImage,
                          backImage: backImage,
                        );

                        if (cardId != null) {
                          Navigator.pop(context, {
                            'id': cardId,
                            'front': frontText,
                            'back': backText,
                          });
                          debugPrint('🔁 Returning new card ID: $cardId');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to save card')),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Add card to set',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),

            ),
            const SizedBox(height: 8),
            if (!_isCardFilled())
              const Text(
                'You must fill both sides of the card',
                style: TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}
