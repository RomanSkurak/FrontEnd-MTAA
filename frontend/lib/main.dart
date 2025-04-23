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
import 'edit_card_screen.dart' as editCard;
import 'edit_set_screen.dart' as editSet;
import 'admin_screen.dart';
import 'guest_screen.dart';
import 'models.dart';
import 'setting_screen.dart';
import 'learning_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final prefs = await SharedPreferences.getInstance();

    final count = prefs.getInt('task_count') ?? 0;
    prefs.setInt('task_count', count + 1);
    prefs.setString('last_task_time', DateTime.now().toIso8601String());

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

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  await Workmanager().registerPeriodicTask(
    "studyReminderTask",
    "reminderTask",
    frequency: Duration(hours: 6),
    initialDelay: Duration(minutes: 1), 
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
          final args = ModalRoute.of(context)!.settings.arguments as FlashcardSet;
          return editSet.EditSetScreen(flashcardSet: args); 
        },
        '/editcard': (context) {
          final flashcardId = ModalRoute.of(context)!.settings.arguments as int;
          return editCard.EditCardScreen(flashcardId: flashcardId);
        },
        '/learn': (context) {                         
          final setId = ModalRoute.of(context)!.settings.arguments as int;
          return LearningScreen(setId: setId);
        },
      },
    );
  }
}
