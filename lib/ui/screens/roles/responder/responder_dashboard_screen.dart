import 'package:flutter/material.dart';
import 'package:wisecare_staff/core/theme/app_theme.dart';
import 'package:wisecare_staff/ui/widgets/custom_card.dart';

class ResponderDashboardScreen extends StatelessWidget {
  const ResponderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Emergency Response',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Emergency Alerts Section
            Text(
              'Active Emergencies',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            CustomCard(
              color: AppColors.primary.withOpacity(0.1),
              child: Column(
                children: [
                  _buildEmergencyItem(
                    context,
                    title: 'Cardiac Emergency',
                    location: '123 Main St, Floor 2',
                    time: '2 mins ago',
                    severity: 'High',
                    icon: Icons.favorite_border,
                  ),
                  const Divider(),
                  _buildEmergencyItem(
                    context,
                    title: 'Fall Incident',
                    location: '456 Park Ave, Room 302',
                    time: '5 mins ago',
                    severity: 'Medium',
                    icon: Icons.personal_injury_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions Section
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.local_hospital_outlined,
                    label: 'View All Cases',
                    onTap: () {
                      // Navigate to all cases screen
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.history_outlined,
                    label: 'Response History',
                    onTap: () {
                      // Navigate to history screen
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Equipment Status Section
            Text(
              'Equipment Status',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: Column(
                children: [
                  _buildEquipmentStatus(
                    context,
                    name: 'First Aid Kit',
                    status: 'Available',
                    icon: Icons.medical_services_outlined,
                  ),
                  const Divider(),
                  _buildEquipmentStatus(
                    context,
                    name: 'Defibrillator',
                    status: 'In Use',
                    icon: Icons.bolt_outlined,
                    isAvailable: false,
                  ),
                  const Divider(),
                  _buildEquipmentStatus(
                    context,
                    name: 'Oxygen Tank',
                    status: 'Available',
                    icon: Icons.air_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyItem(
    BuildContext context, {
    required String title,
    required String location,
    required String time,
    required String severity,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final color = severity.toLowerCase() == 'high'
        ? Colors.red
        : severity.toLowerCase() == 'medium'
            ? Colors.orange
            : Colors.green;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        severity,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () {
              // Navigate to emergency details
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentStatus(
    BuildContext context, {
    required String name,
    required String status,
    required IconData icon,
    bool isAvailable = true,
  }) {
    final theme = Theme.of(context);
    final color = isAvailable ? Colors.green : Colors.orange;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: () {
              // Show equipment details
            },
          ),
        ],
      ),
    );
  }
} 