import 'package:flutter/material.dart';
import '../../Screens/Mobile/statistics_screen_mobile.dart';
import '../../Screens/Tablet/statistics_screen_tablet.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 600) {
      // Tablet layout
      return const StatisticsScreenTablet();
    } else {
      // Mobile layout
      return const StatisticsScreenMobile();
    }
  }
}
