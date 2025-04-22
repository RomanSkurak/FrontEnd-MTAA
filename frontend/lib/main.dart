import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background callback
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final prefs = await SharedPreferences.getInstance();

    // Zapíš analytiku
    final count = prefs.getInt('task_count') ?? 0;
    prefs.setInt('task_count', count + 1);
    prefs.setString('last_task_time', DateTime.now().toIso8601String());

    // Zobraz notifikáciu
    const androidDetails = AndroidNotificationDetails(
      'studybro_channel',
      'StudyBro Reminder',
      channelDescription: 'Reminder to study flashcards',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      '📚 Nezabudni na učenie!',
      'Poď si zopakovať svoje flashcards!',
      notificationDetails,
    );

    print('✅ Background task executed.');
    return Future.value(true);
  });
}

//MAIN
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

  // Notifikácie
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  // Workmanager init
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  await Workmanager().registerPeriodicTask(
    "studyReminderTask",
    "reminderTask",
    frequency: Duration(hours: 6),
    initialDelay: Duration(minutes: 1), // na testovanie
  );

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
