import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final data = await ApiService().getStatistics();
      setState(() {
        _stats = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(fontSize: 18);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text('Error: $_error')));
    }

    // pre jednoduchosť predpokladáme, že BE vrátil:
    // {
    //   "avg_accuracy": 0.82,
    //   "total_time_secs": 4520,
    //   "best_streak": 5,
    //   "current_streak": 2
    // }

    final avgAccuracy =
        double.tryParse(_stats?['avg_accuracy']?.toString() ?? '') ?? 0.0;
    final totalSeconds =
        double.tryParse(_stats?['total_time_secs']?.toString() ?? '') ?? 0.0;
    final bestStreak =
        int.tryParse(_stats?['best_streak']?.toString() ?? '') ?? 0;
    final currentStreak =
        int.tryParse(_stats?['current_streak']?.toString() ?? '') ?? 0;

    final totalHours = totalSeconds / 3600;
    final avgPct = avgAccuracy * 100;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Statistics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
                '🎯 Avg Accuracy',
                '${avgPct.toStringAsFixed(1)} %',
                textStyle,
              ),
              _buildStatRow(
                '⏱️ Total Time',
                '${totalHours.toStringAsFixed(1)} h',
                textStyle,
              ),
              _buildStatRow('🏆 Best Streak', '$bestStreak days', textStyle),
              _buildStatRow(
                '🔥 Current Streak',
                '$currentStreak days',
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
