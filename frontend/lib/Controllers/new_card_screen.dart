import 'package:flutter/material.dart';
import '../../Screens/Mobile/new_card_screen_mobile.dart';
import '../../Screens/Tablet/new_card_screen_tablet.dart';

class NewCardScreen extends StatelessWidget {
  const NewCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 600) {
      // Tablet layout
      return const NewCardScreenTablet();
    } else {
      // Mobile layout
      return const NewCardScreenMobile();
    }
  }
}
