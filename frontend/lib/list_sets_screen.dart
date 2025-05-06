import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'api_service.dart';
import 'connectivity_service.dart';
import 'models.dart';
import 'offline_models.dart';
import 'dart:typed_data';
import 'dart:convert';

class ListOfSetsScreen extends StatefulWidget {
  const ListOfSetsScreen({Key? key}) : super(key: key);

  @override
  State<ListOfSetsScreen> createState() => _ListOfSetsScreenState();
}

class _ListOfSetsScreenState extends State<ListOfSetsScreen> {
  /// online / offline dáta
  List<FlashcardSet> _sets = [];

  /// na zobrazenie loadera
  bool _loading = true;

  Uint8List? _decodeBase64(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    final cleaned = base64.replaceAll(RegExp(r'[^A-Za-z0-9+/=]+'), '');
    return base64Decode(cleaned);
  }

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    setState(() => _loading = true);

    final box = Hive.box<OfflineFlashcardSet>('offlineSets');
    final online = await ConnectivityService.isOnline();

    if (online) {
      try {
        debugPrint('🌐 Online – sťahujem zo servera');
        final remoteSets = await ApiService().fetchSets()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // tu triedenie
        await box.clear();

        /* -------- načítaj všetky flashcardy paralelne -------- */
        await Future.wait(
          remoteSets.map((set) async {
            final data = await ApiService().loadSetWithFlashcards(set.setId);

            final offlineCards = (data['cards'] as List).map((c) {
              return OfflineFlashcard(
                front: c['front_side'],
                back: c['back_side'],
                imageFront: _decodeBase64(c['image_front']),
                imageBack: _decodeBase64(c['image_back']),
              );
            }).toList();


            await box.add(
              OfflineFlashcardSet(
                setId:     set.setId,
                name:      set.name,
                isPublic:  set.isPublic,
                userId:    set.userId,
                createdAt: set.createdAt,
                updatedAt: set.updatedAt,
                flashcards: offlineCards,
              ),
            );
          }),
        );

        setState(() => _sets = remoteSets);
      } catch (e) {
        debugPrint('❌  Chyba pri sťahovaní: $e');
        /* ––– fallback na Hive, ak by server zlyhal ––– */
        _loadFromHive(box);
      }
    } else {
      debugPrint('📴 Offline – načítavam z Hive');
      _loadFromHive(box);
    }

    setState(() => _loading = false);
  }

  void _loadFromHive(Box<OfflineFlashcardSet> box) {
    final local = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); 
    _sets = local
        .map((s) => FlashcardSet(
              setId:     s.setId,
              name:      s.name,
              isPublic:  s.isPublic,
              userId:    s.userId,
              createdAt: s.createdAt,
              updatedAt: s.updatedAt,
            ))
        .toList();
  }


  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: t.scaffoldBackgroundColor,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back, color: t.iconTheme.color, size: 32),
          ),
        ),
        title: Text(
          'List of your sets',
          style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),

      /* ---------- BODY ---------- */
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sets.isEmpty
              ? Center(
                  child: Text(
                    "You don't have any flashcard sets yet",
                    style: t.textTheme.bodyMedium?.copyWith(color: t.hintColor),
                  ),
                )
              : ListView.builder(
                  itemCount: _sets.length,
                  itemBuilder: (ctx, i) {
                    final set = _sets[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: t.brightness == Brightness.dark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        color: t.cardColor,
                        elevation: 1.5,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pushNamed(ctx, '/learn', arguments: set.setId),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              height: 64,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(set.name,
                                      style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 25),
                                    color: t.iconTheme.color,
                                    onPressed: () async {
                                      final online = await ConnectivityService.isOnline();
                                      if (!online) {
                                        if (mounted) {
                                          await showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Error'),
                                              content: const Text('You are offline – editing is available only online.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return; 
                                      }
                                      final ok = await Navigator.pushNamed(ctx, '/editset', arguments: set);
                                      if (ok == true) _loadSets();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

      /* ---------- BOTTOM ---------- */
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 48),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final online = await ConnectivityService.isOnline();
            if (!online) {
              if (mounted) {
                await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Error'),
                    content: const Text('You are offline – creating a set requires connection.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
              return; // stop here
            }

            

            final created = await Navigator.pushNamed(context, '/create');
            if (created == true) _loadSets();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.iconTheme.color ?? Colors.black),
                ),
                child: Icon(Icons.add, color: t.iconTheme.color),
              ),
              const SizedBox(width: 10),
              Text('Create a New Set', style: t.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}