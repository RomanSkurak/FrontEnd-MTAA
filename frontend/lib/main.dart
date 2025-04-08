import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'splash_screen.dart';
import 'list_sets_screen.dart';
import 'create_set_screen.dart';
import 'new_card_screen.dart';
import 'edit_set_screen.dart';
import 'edit_card_screen.dart';
import 'models.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudyBro',
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/sets': (context) => const ListOfSetsScreen(),
        '/create': (context) => const CreateSetScreen(),
        '/newcard': (context) => NewCardScreen(),
        '/editset': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as FlashcardSet;
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
