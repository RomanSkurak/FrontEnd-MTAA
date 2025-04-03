import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  final Map<String, dynamic> stats;
  const StatisticsScreen({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Statistics")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Avg Accuracy: ${stats['avg_accuracy']}%",
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              "Total Learning Time: ${stats['total_learning_time']} minutes",
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              "Best Streak: ${stats['best_learning_streak']}",
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              "Current Streak: ${stats['current_learning_streak']}",
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
