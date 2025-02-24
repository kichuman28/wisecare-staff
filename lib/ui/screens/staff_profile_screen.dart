import 'package:flutter/material.dart';
import 'package:wisecare_staff/core/theme/app_theme.dart';

class StaffProfileScreen extends StatelessWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.primary,
            onPressed: () {
              // Handle edit profile
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      'JD',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'John Doe',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Medical Assistant',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        context,
                        'Tasks\nCompleted',
                        '156',
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: AppColors.tertiary,
                      ),
                      _buildStatItem(
                        context,
                        'Patient\nRatings',
                        '4.8',
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: AppColors.tertiary,
                      ),
                      _buildStatItem(
                        context,
                        'Years of\nExperience',
                        '5+',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileSection(
                    context,
                    'Working Hours',
                    Icons.access_time_outlined,
                    '9:00 AM - 5:00 PM',
                  ),
                  _buildProfileSection(
                    context,
                    'Contact Info',
                    Icons.phone_outlined,
                    '+1 234 567 8900',
                  ),
                  _buildProfileSection(
                    context,
                    'Email',
                    Icons.email_outlined,
                    'john.doe@wisecare.com',
                  ),
                  _buildProfileSection(
                    context,
                    'Settings',
                    Icons.settings_outlined,
                    'App preferences, notifications',
                    showDivider: false,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () {
                      // Handle logout
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle, {
    bool showDivider = true,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodyMedium,
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
          onTap: () {
            // Handle section tap
          },
        ),
        if (showDivider) const Divider(),
      ],
    );
  }
} 