import 'package:flutter/material.dart';
import 'package:wisecare_staff/core/theme/app_theme.dart';

class TaskSummaryCard extends StatelessWidget {
  const TaskSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context,
                  'Pending',
                  '5',
                  AppColors.secondary,
                ),
                _buildSummaryItem(
                  context,
                  'In Progress',
                  '2',
                  AppColors.primary,
                ),
                _buildSummaryItem(
                  context,
                  'Completed',
                  '8',
                  AppColors.tertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
} 