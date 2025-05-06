import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:hive/hive.dart';
import 'offline_models.dart';
import 'connectivity_service.dart';

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
  // PRIDANÉ PRE ŠTATISTIKY
  late DateTime _sessionStart;
  int _correctCount = 0;
  int _totalCount = 0;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  final List<_Flashcard> _cards = [];
  int _currentIndex = 0;
  bool _isFrontSide = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // začiatok sedenia
    _sessionStart = DateTime.now();

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
    final isOnline = await ConnectivityService.isOnline();

    if (isOnline) {
      try {
        final data = await ApiService().loadSetWithFlashcards(widget.setId);
        final raw = data['cards'] as List<dynamic>;

        if (raw.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This set has no flashcards.')),
          );
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
    } else {
      final box = Hive.box<OfflineFlashcardSet>('offlineSets');
      final offlineSet = box.values.firstWhere(
        (s) => s.setId == widget.setId,
        orElse: () => OfflineFlashcardSet(
          setId: 0,
          name: '',
          isPublic: false,
          userId: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          flashcards: [],
        ),
      );

      if (offlineSet.flashcards.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This set has no flashcards.')),
          );
          Navigator.pop(context);
        }
        return;
      }

      for (final c in offlineSet.flashcards) {
        _cards.add(
          _Flashcard(
            frontText: c.front,
            backText: c.back,
            frontImage: c.imageFront,
            backImage: c.imageBack,
          ),
        );
      }

      setState(() => _isLoading = false);
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

  Future<void> _submitSession() async {
    final endTime = DateTime.now();
    try {
      await ApiService().submitLearningSession(
        startTime: _sessionStart,
        endTime: endTime,
        correct: _correctCount,
        total: _totalCount,
      );
      // prípadne zobraz snackBar alebo iná UX odozva
    } catch (e) {
      // log alebo upozorniť používateľa
      debugPrint('Error submitting session: $e');
    }
  }

  void _onKnewIt() {
    _correctCount++;
    _totalCount++;
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _cards.removeAt(_currentIndex);
        if (_cards.isEmpty) {
          _resetCardSide();
          _submitSession(); // ── po poslednej karte odošli session

          return;
        }
        _currentIndex %= _cards.length;
        _resetCardSide();
      });
    });
  }

  void _onDidNotKnow() {
    _totalCount++;
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _cards.length;
        if (_cards.isEmpty) {
          _submitSession(); // ── ak by cards prázdne (extra istota)
          return;
        }
        _resetCardSide();
      });
    });
  }

  Widget _buildContent(bool isBack) {
    final c = _cards[_currentIndex];
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(fontSize: 18);

    if (isBack) {
      return c.backImage != null
          ? Image.memory(
            c.backImage!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          )
          : Text(c.backText, textAlign: TextAlign.center, style: textStyle);
    } else {
      return c.frontImage != null
          ? Image.memory(
            c.frontImage!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          )
          : Text(c.frontText, textAlign: TextAlign.center, style: textStyle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final frontCardColor = isDark ? Colors.grey[850]! : const Color(0xFFE1E1E1);
    final backCardColor = isDark ? Colors.grey[700]! : const Color(0xFFC1C1C1);
    final iconColor = theme.iconTheme.color;
    final textStyle = theme.textTheme.bodyLarge;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_cards.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back, color: iconColor, size: 32),
            ),
          ),
          title: Text(
            'Done!',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'You have completed all cards in this set.',
            style: textStyle,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back, color: iconColor, size: 32),
          ),
        ),
        title: Text(
          '${_currentIndex + 1}/${_cards.length}',
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.decelerate,
                      ),
                    ),
                    child: FadeTransition(opacity: animation, child: child),
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
                        transform:
                            Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(_animation.value),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBack ? backCardColor : frontCardColor,
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
                                  child: _buildContent(isBack),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                child: Icon(
                                  Icons.sync,
                                  size: 28,
                                  color: iconColor?.withOpacity(0.6),
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
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 48,
                  onPressed: _onDidNotKnow,
                  icon: Icon(Icons.close, color: iconColor),
                ),
                IconButton(
                  iconSize: 48,
                  onPressed: _onKnewIt,
                  icon: Icon(Icons.check, color: iconColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
