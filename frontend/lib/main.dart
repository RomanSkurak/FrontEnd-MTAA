import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'offline_models.dart';

import 'Controllers/login_screen.dart';
import 'Controllers/register_screen.dart';
import 'Controllers/home_screen.dart';
import 'splash_screen.dart';
import 'Controllers/list_sets_screen.dart';
import 'Controllers/create_set_screen.dart';
import 'Controllers/new_card_screen.dart';
import 'Controllers/edit_card_screen.dart' as editCard;
import 'Controllers/edit_set_screen.dart' as editSet;
import 'Controllers/admin_screen.dart';
import 'Controllers/guest_screen.dart';
import 'models.dart';
import 'Controllers/setting_screen.dart';
import 'Controllers/learning_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

@pragma('vm:entry-point')
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
      '📚 Dont forget to Study!',
      'Come and review your flashcards!',
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

  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);

  Hive.registerAdapter(OfflineFlashcardSetAdapter());
  Hive.registerAdapter(OfflineFlashcardAdapter());

  await Hive.openBox<OfflineFlashcardSet>('offlineSets');

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

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  //await Workmanager().cancelAll(); // zruší všetky tasky
  await Workmanager().registerPeriodicTask(
    "studyReminderTask",
    "reminderTask",
    frequency: Duration(hours: 1),
    initialDelay: Duration(minutes: 1),
  );

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  // Zaznamenaj všetky Flutter chyby
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLargeText = false;

  bool get isLargeText => _isLargeText;

  void setLargeText(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isLargeText = value);
    prefs.setBool('largeText', value);
  }

  ThemeMode _themeMode = ThemeMode.system;

  void setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _themeMode = mode);
    prefs.setString('themeMode', mode.name);
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('themeMode');

    _isLargeText = prefs.getBool('largeText') ?? false;

    setState(() {
      if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'StudyBro',
      themeMode: _themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
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
          return const editSet.EditSetScreen(); // bez argumentov
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
