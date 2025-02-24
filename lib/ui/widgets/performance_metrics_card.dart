import 'package:flutter/material.dart';
import 'package:wisecare_staff/core/theme/app_theme.dart';

class PerformanceMetricsCard extends StatelessWidget {
  const PerformanceMetricsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildMetricItem(
              context,
              'Average Response Time',
              '15 mins',
              Icons.timer_outlined,
            ),
            const Divider(height: 32),
            _buildMetricItem(
              context,
              'Task Completion Rate',
              '95%',
              Icons.check_circle_outline,
            ),
            const Divider(height: 32),
            _buildMetricItem(
              context,
              'Patient Satisfaction',
              '4.8/5',
              Icons.star_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
} 