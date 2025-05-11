import 'package:flutter/material.dart';
import '../Screens/Mobile/home_screen_mobile.dart';
import '../Screens/Tablet/home_screen_tablet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 600) {
      // Tablet layout
      return const HomeScreenTablet();
    } else {
      // Mobile layout
      return const HomeScreenMobile();
    }
  }
}
