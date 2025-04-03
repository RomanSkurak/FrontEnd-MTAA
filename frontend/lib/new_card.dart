import 'package:flutter/material.dart';
import 'dart:math';

class NewCardScreen extends StatefulWidget {
  const NewCardScreen({Key? key}) : super(key: key);

  @override
  State<NewCardScreen> createState() => _NewCardScreenState();
}

class _NewCardScreenState extends State<NewCardScreen>
    with SingleTickerProviderStateMixin {
  bool isFrontSide = true;

  final TextEditingController frontController = TextEditingController();
  final TextEditingController backController = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: pi).animate(_controller);

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    frontController.dispose();
    backController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (isFrontSide) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      isFrontSide = !isFrontSide;
    });
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
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 22,
          ),
        ),
      ),

      body: SingleChildScrollView(
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

                    return Transform(
                      alignment: Alignment.center,
                      transform:
                          Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(_animation.value),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
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
                                padding: const EdgeInsets.all(24),
                                child: TextField(
                                  controller:
                                      isBack ? backController : frontController,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText:
                                        isBack
                                            ? 'Back side content'
                                            : 'Front side content',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              child: GestureDetector(
                                onTap: _flipCard,
                                child: const Icon(
                                  Icons.sync,
                                  size: 28,
                                  color: Colors.black54,
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
                  onPressed: () {
                    // change text - zatiaľ nepoužité
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Change text'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // change image - zatiaľ nepoužité
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Change image'),
                ),
              ],
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // Add card button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              final cardContent =
                  '${frontController.text.trim()} | ${backController.text.trim()}';

              Navigator.pop(context, cardContent); // pošli späť
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Add card to set',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
