import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'splash_screen.dart';
import 'list_sets_screen.dart';
import 'create_set_screen.dart';
import 'new_card_screen.dart';
import 'edit_set_screen.dart';
import 'edit_card_screen.dart';
import 'admin_screen.dart';
import 'guest_screen.dart';
import 'models.dart';
import 'setting_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.requestPermission();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📥 Push prišiel (foreground): ${message.notification?.title}');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print(
      '📬 Užívateľ klikol na notifikáciu (background): ${message.notification?.title}',
    );
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'StudyBro',
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/sets': (context) => const ListOfSetsScreen(),
        '/admin': (context) => const AdminScreen(),
        '/guest': (context) => const GuestScreen(),
        '/settings': (context) => const SettingScreen(),
        '/create': (context) => const CreateSetScreen(),
        '/newcard': (context) => NewCardScreen(),
        '/editset': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as FlashcardSet;
          return EditSetScreen(flashcardSet: args);
        },
        '/editcard': (context) {
          final flashcardId = ModalRoute.of(context)!.settings.arguments as int;
          return EditCardScreen(flashcardId: flashcardId);
        },
      },
    );
  }
}
