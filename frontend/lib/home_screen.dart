import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'api_service.dart';
import 'statistics_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'main.dart';
import 'models.dart';
import 'connectivity_service.dart';
import 'package:hive/hive.dart';
import 'offline_models.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_analytics/firebase_analytics.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late IO.Socket socket;

  void connectSocket() {
    socket = IO.io('https://backend-mtaa.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('✅ Pripojený na WebSocket');
    });

    socket.on('newPublicSet', (data) {
      print('📬 Prišla realtime sada: ${data['title']}');

      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📚 New Public Set: ${data['title']}'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    });

    socket.onDisconnect((_) => print('❌ WebSocket odpojený'));
  }

  List<FlashcardSet> recentlyAdded = [];
  String username = 'Loading...';

  @override
  void initState() {
    super.initState();
    connectSocket();
    _loadUsername();
    _loadRecentSets();
  }

  bool _loading = true;

  Future<void> _loadUsername() async {
    final user = await ApiService().getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        username = user['name'] ?? 'User';
      });
    }
  }

  Uint8List? _decodeBase64(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    final cleaned = base64.replaceAll(RegExp(r'[^A-Za-z0-9+/=]+'), '');
    return base64Decode(cleaned);
  }

  Future<void> _loadRecentSets() async {
    setState(() => _loading = true);

    final online = await ConnectivityService.isOnline();
    final box = Hive.box<OfflineFlashcardSet>('offlineSets');

    if (online) {
      try {
        final remoteSets =
            await ApiService().fetchSets()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        await box.clear();

        await Future.wait(
          remoteSets.map((set) async {
            final fullSet = await ApiService().loadSetWithFlashcards(set.setId);

            final offlineFlashcards =
                (fullSet['cards'] as List).map((card) {
                  return OfflineFlashcard(
                    front: card['front_side'],
                    back: card['back_side'],
                    imageFront: _decodeBase64(card['image_front']),
                    imageBack: _decodeBase64(card['image_back']),
                  );
                }).toList();

            final offlineSet = OfflineFlashcardSet(
              setId: set.setId,
              name: set.name,
              isPublic: set.isPublic,
              userId: set.userId,
              createdAt: set.createdAt,
              updatedAt: set.updatedAt,
              flashcards: offlineFlashcards,
            );

            await box.add(offlineSet);
          }),
        );
        if (!mounted) return;
        setState(() {
          recentlyAdded = remoteSets.reversed.take(4).toList();
        });
      } catch (e) {
        print('❌ Chyba pri fetchnutí dát: $e');
        _loadFromHive(box);
      }
    } else {
      print('📴 Offline – Hive fallback');
      _loadFromHive(box);
    }

    setState(() => _loading = false);
  }

  void _loadFromHive(Box<OfflineFlashcardSet> box) {
    final local =
        box.values.toList()..sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        ); // zoradenie zostupne

    setState(() {
      recentlyAdded =
          local
              .map(
                (s) => FlashcardSet(
                  setId: s.setId,
                  name: s.name,
                  isPublic: s.isPublic,
                  userId: s.userId,
                  createdAt: s.createdAt,
                  updatedAt: s.updatedAt,
                ),
              )
              .take(4) // nemusíš už dávať reversed, lebo už sú zoradené správne
              .toList();
    });
  }

  void _navigateToStatistics(BuildContext context) async {
    try {
      //final stats = await ApiService().getStatistics();
      FirebaseAnalytics.instance.logEvent(name: 'statistics_opened');
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StatisticsScreen()),
      );

      _loadRecentSets();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Statistics are only available Online")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          username,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/settings');
                          },
                          icon: const Icon(Icons.settings, size: 28),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recently added:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final online = await ConnectivityService.isOnline();
                            if (!online) {
                              if (mounted) {
                                await showDialog(
                                  context: context,
                                  builder:
                                      (ctx) => AlertDialog(
                                        title: const Text('Offline'),
                                        content: const Text(
                                          'You are offline – creating a set requires internet connection.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(ctx).pop(),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                );
                              }
                              return;
                            }

                            final result = await Navigator.pushNamed(
                              context,
                              '/create',
                            );
                            await Future.delayed(
                              const Duration(milliseconds: 10),
                            );
                            if (!mounted) return;
                            if (result != null) {
                              _loadRecentSets();
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor:
                                theme.colorScheme.onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (recentlyAdded.isEmpty)
                      const Text('No sets yet.')
                    else
                      ...recentlyAdded.map((set) {
                        return InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/learn',
                              arguments: set.setId,
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    theme.brightness == Brightness.dark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                              ),
                            ),
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              set.name,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        );
                      }),

                    const Spacer(),

                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              theme.brightness == Brightness.dark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await Navigator.pushNamed(context, '/sets');
                              _loadRecentSets();
                            },
                            child: Container(
                              width: 100,
                              height: 70,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                FontAwesomeIcons.listUl,
                                size: 30,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _navigateToStatistics(context),
                            child: Container(
                              width: 100,
                              height: 70,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                FontAwesomeIcons.chartColumn,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
      ),
    );
  }
}
