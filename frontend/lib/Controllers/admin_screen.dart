import 'package:flutter/material.dart';
import '../Screens/Mobile/admin_screen_mobile.dart';
import '../Screens/Tablet/admin_screen_tablet.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 600) {
      // Tablet layout
      return const AdminScreenTablet();
    } else {
      // Mobile layout
      return const AdminScreenMobile();
    }
  }
}
