import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'api_service.dart';

class _Flashcard {
  final String frontText;
  final String backText;
  final Uint8List? frontImage;
  final Uint8List? backImage;

  const _Flashcard({
    required this.frontText,
    required this.backText,
    this.frontImage,
    this.backImage,
  });
}

class LearningScreen extends StatefulWidget {
  final int setId;
  const LearningScreen({super.key, required this.setId});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  final List<_Flashcard> _cards = [];
  int _currentIndex = 0;
  bool _isFrontSide = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(_controller);
    _loadCards();
  }

  Uint8List? _decode(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    final cleaned = base64.replaceAll(RegExp(r'[^A-Za-z0-9+/=]+'), '');
    return base64Decode(cleaned);
  }

  Future<void> _loadCards() async {
    try {
      final data = await ApiService().loadSetWithFlashcards(widget.setId);
      final raw = data['cards'] as List<dynamic>;

      if (raw.isEmpty && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('This set has no flashcards.')));
        Navigator.pop(context);
        return;
      }

      for (final c in raw) {
        _cards.add(
          _Flashcard(
            frontText: c['front_side'] ?? '',
            backText: c['back_side'] ?? '',
            frontImage: _decode(c['image_front']),
            backImage: _decode(c['image_back']),
          ),
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cards: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFrontSide) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _isFrontSide = !_isFrontSide);
  }

  void _resetCardSide() {
    _isFrontSide = true;
    _controller.reset();
  }

  void _onKnewIt() {
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _cards.removeAt(_currentIndex);
        if (_cards.isEmpty) {
          _resetCardSide();
          return;
        }
        _currentIndex %= _cards.length;
        _resetCardSide();
      });
    });
  }

  void _onDidNotKnow() {
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _cards.length;
        _resetCardSide();
      });
    });
  }

  Widget _buildContent(bool isBack) {
    final c = _cards[_currentIndex];
    if (isBack) {
      return c.backImage != null
          ? Image.memory(c.backImage!, fit: BoxFit.contain, gaplessPlayback: true)
          : Text(
              c.backText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            );
    } else {
      return c.frontImage != null
          ? Image.memory(c.frontImage!, fit: BoxFit.contain, gaplessPlayback: true)
          : Text(
              c.frontText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_cards.isEmpty) {
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
          title: const Text(
            'Done!',
            style: TextStyle(fontSize: 22, color: Colors.black),
          ),
        ),
        body: const Center(
          child: Text(
            'You have completed all cards in this set.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

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
          '${_currentIndex + 1}/${_cards.length}',
          style: const TextStyle(fontSize: 22, color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _flipCard,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                      CurvedAnimation(parent: animation, curve: Curves.decelerate),
                    ),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  key: ValueKey(_cards[_currentIndex]),
                  width: 360,
                  height: 540,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, _) {
                      final isBack = _animation.value >= pi / 2;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_animation.value),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBack
                                ? const Color(0xFFC1C1C1)
                                : const Color(0xFFE1E1E1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform(
                                alignment: Alignment.center,
                                transform: isBack
                                    ? Matrix4.rotationY(pi)
                                    : Matrix4.identity(),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                                  child: _buildContent(isBack),
                                ),
                              ),
                              const Positioned(
                                bottom: 12,
                                child: Icon(Icons.sync, size: 28, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 48,
                  onPressed: _onDidNotKnow,
                  icon: const Icon(Icons.close, color: Colors.black),
                ),
                IconButton(
                  iconSize: 48,
                  onPressed: _onKnewIt,
                  icon: const Icon(Icons.check, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
