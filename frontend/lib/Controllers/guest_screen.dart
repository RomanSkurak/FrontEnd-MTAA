import 'package:flutter/material.dart';
import '../Screens/Mobile/guest_screen_mobile.dart';
import '../Screens/Tablet/guest_screen_tablet.dart';

class GuestScreen extends StatelessWidget {
  const GuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 600) {
      return GuestScreenTablet();
    } else {
      return GuestScreenMobile();
    }
  }
}
