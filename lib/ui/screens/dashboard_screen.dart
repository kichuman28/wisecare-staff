import 'package:flutter/material.dart';
import 'package:wisecare_staff/core/theme/app_theme.dart';
import 'package:wisecare_staff/ui/widgets/task_summary_card.dart';
import 'package:wisecare_staff/ui/widgets/performance_metrics_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.primary,
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, John!',
              style: theme.textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Here\'s your daily overview',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Today\'s Summary',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const TaskSummaryCard(),
            const SizedBox(height: 24),
            Text(
              'Performance Metrics',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const PerformanceMetricsCard(),
          ],
        ),
      ),
    );
  }
} 