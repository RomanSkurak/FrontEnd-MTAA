import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  final Map<String, dynamic> stats;
  const StatisticsScreen({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(fontSize: 18);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Your Statistics",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 1,
        iconTheme: theme.iconTheme,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow(
                "🎯 Avg Accuracy",
                "${stats['avg_accuracy']}%",
                textStyle,
              ),
              _buildStatRow(
                "⏱️ Total Time",
                "${stats['total_learning_time']} hours",
                textStyle,
              ),
              _buildStatRow(
                "🏆 Best Streak",
                "${stats['best_learning_streak']}",
                textStyle,
              ),
              _buildStatRow(
                "🔥 Current Streak",
                "${stats['current_learning_streak']}",
                textStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
