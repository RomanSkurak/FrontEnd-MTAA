import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'api_service.dart';
import 'statistics_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late IO.Socket socket;

  void connectSocket() {
    socket = IO.io(
      'http://10.0.2.2:3000', // pre emulátor; fyzické zariadenie: zadaj tvoju IP
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      },
    );

    socket.onConnect((_) {
      print('✅ Pripojený na WebSocket');
    });

    socket.on('newPublicSet', (data) {
      print('📬 Prišla realtime sada: ${data['title']}');

      // Zobrazenie SnackBar-u
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📚 Nový verejný set: ${data['title']}'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    });

    socket.onDisconnect((_) => print('❌ WebSocket odpojený'));
  }

  List<String> recentlyAdded = [];
  String username = 'Loading...';

  @override
  void initState() {
    super.initState();
    connectSocket();
    _loadUsername();
    _loadRecentSets();
  }

  Future<void> _loadUsername() async {
    final user = await ApiService().getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        username = user['name'] ?? 'User';
      });
    }
  }

  Future<void> _loadRecentSets() async {
    try {
      final sets = await ApiService().fetchSets();
      if (mounted) {
        setState(() {
          recentlyAdded = sets.take(4).map((set) => set.name).toList();
        });
      }
    } catch (e) {
      print('Error loading sets: $e');
    }
  }

  void _navigateToStatistics(BuildContext context) async {
    final stats = await ApiService().getStatistics();
    if (stats != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StatisticsScreen(stats: stats)),
      );
      _loadRecentSets();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load statistics")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
        child: Column(
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
                  style: const TextStyle(
                    fontSize: 20,
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
                    await Navigator.pushNamed(context, '/create');
                    _loadRecentSets();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
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
              ...recentlyAdded.map((title) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Text(title, style: const TextStyle(fontSize: 16)),
                );
              }),

            const Spacer(),

            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(FontAwesomeIcons.listUl, size: 30),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToStatistics(context),
                    child: Container(
                      width: 100,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(FontAwesomeIcons.chartColumn, size: 30),
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
