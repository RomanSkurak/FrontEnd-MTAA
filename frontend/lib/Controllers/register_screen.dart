import 'package:flutter/material.dart';
import '../Screens/Mobile/register_screen_mobile.dart';
import '../Screens/Tablet/register_screen_tablet.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 600) {
      return const RegisterScreenTablet();
    } else {
      return const RegisterScreenMobile();
    }
  }
}
