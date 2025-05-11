import 'package:flutter/material.dart';
import '../Screens/Mobile/login_screen_mobile.dart';
import '../Screens/Tablet/login_screen_tablet.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 600) {
      return const LoginTablet();
    } else {
      return const LoginMobile();
    }
  }
}
