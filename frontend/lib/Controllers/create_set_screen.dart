import 'package:flutter/material.dart';
import '../Screens/Mobile/create_set_screen_mobile.dart';
import '../Screens/Tablet/create_set_screen_tablet.dart';

class CreateSetScreen extends StatelessWidget {
  const CreateSetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 600) {
      return CreateSetScreenTablet();
    } else {
      return CreateSetScreenMobile();
    }
  }
}
