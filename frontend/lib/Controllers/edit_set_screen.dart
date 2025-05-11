import 'package:flutter/material.dart';
import '../Screens/Mobile/edit_set_screen_mobile.dart';
import '../Screens/Tablet/edit_set_screen_tablet.dart';
import '../../models.dart';

class EditSetScreen extends StatelessWidget {
  const EditSetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // ✅ Získaj argument od Navigatora
    final flashcardSet =
        ModalRoute.of(context)?.settings.arguments as FlashcardSet;

    if (screenWidth >= 600) {
      // ✅ Tablet layout s argumentom
      return EditSetScreenTablet(flashcardSet: flashcardSet);
    } else {
      // ✅ Mobile layout s argumentom
      return EditSetScreenMobile(flashcardSet: flashcardSet);
    }
  }
}
