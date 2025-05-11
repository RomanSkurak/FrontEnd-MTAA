import 'package:flutter/material.dart';
import '../Screens/Mobile/list_sets_screen_mobile.dart';
import '../Screens/Tablet/list_sets_screen_tablet.dart';

class ListOfSetsScreen extends StatelessWidget {
  const ListOfSetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 600) {
      // Tablet layout
      return const ListOfSetsScreenTablet();
    } else {
      // Mobile layout
      return const ListOfSetsScreenMobile();
    }
  }
}
