import 'package:flutter/material.dart';
import '../../../Screens/Mobile/edit_card_screen_mobile.dart';
import '../../../Screens/Tablet/edit_card_screen_tablet.dart';

class EditCardScreen extends StatelessWidget {
  final int flashcardId;

  const EditCardScreen({super.key, required this.flashcardId});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 600) {
      return EditCardScreenTablet(flashcardId: flashcardId);
    } else {
      return EditCardScreenMobile(flashcardId: flashcardId);
    }
  }
}
