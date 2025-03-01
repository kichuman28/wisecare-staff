import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisecare_staff/core/theme/app_theme.dart';
import 'package:wisecare_staff/ui/widgets/custom_card.dart';
import 'package:wisecare_staff/provider/sos_alert_provider.dart';
import 'package:wisecare_staff/ui/screens/alerts/sos_dashboard_screen.dart';
import 'package:wisecare_staff/ui/screens/alerts/alert_details_screen.dart';
import 'package:intl/intl.dart';

class ResponderDashboardScreen extends StatefulWidget {
  const ResponderDashboardScreen({super.key});

  @override
  State<ResponderDashboardScreen> createState() => _ResponderDashboardScreenState();
}

class _ResponderDashboardScreenState extends State<ResponderDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Call getAssignedAlerts with debug flag
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getAssignedAlerts(debug: true);
    });
  }

  // Method to fetch assigned alerts with debug option
  Future<void> _getAssignedAlerts({bool debug = false}) async {
    final sosProvider = Provider.of<SOSAlertProvider>(context, listen: false);
    
    if (debug) {
      print('Debugging responder dashboard alerts...');
      // Add a slight delay to ensure provider is fully initialized
      await Future.delayed(Duration(milliseconds: 500));
    }
    
    await sosProvider.fetchAssignedAlerts();
    
    if (debug && mounted) {
      // Filter to get only assigned (not resolved) alerts
      final assignedAlerts = sosProvider.alerts.where((alert) => alert.status == 'assigned').toList();
      
      if (assignedAlerts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No assigned emergencies found that need your attention.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${assignedAlerts.length} active emergencies requiring your attention'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SOSAlertProvider>().fetchAssignedAlerts();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current status section
            _buildStatusSection(context),
            
            const SizedBox(height: 24),
            
            // Active SOS Alerts Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assigned Emergencies',
                  style: theme.textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SOSDashboardScreen()),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSOSAlertSection(),
            
            const SizedBox(height: 24),
            
            // Mock static content from original design
            Text(
              'Recent Activity',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            CustomCard(
              color: Colors.white,
              child: Column(
                children: [
                  _buildEmergencyItem(
                    context,
                    title: 'Cardiac Emergency',
                    location: '123 Main St, Floor 2',
                    time: '2 mins ago',
                    severity: 'High',
                    icon: Icons.favorite_border,
                    isResolved: true,
                  ),
                  const Divider(),
                  _buildEmergencyItem(
                    context,
                    title: 'Fall Incident',
                    location: '456 Park Ave, Room 302',
                    time: '15 mins ago',
                    severity: 'Medium',
                    icon: Icons.personal_injury,
                    isResolved: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Training section
            Text(
              'Training & Resources',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            CustomCard(
              color: Colors.white,
              child: Column(
                children: [
                  _buildResourceItem(
                    context,
                    title: 'CPR Refresher Course',
                    description: 'Update your CPR skills with our latest techniques',
                    icon: Icons.health_and_safety,
                  ),
                  const Divider(),
                  _buildResourceItem(
                    context,
                    title: 'Emergency Protocols',
                    description: 'Review the latest emergency response protocols',
                    icon: Icons.menu_book,
                  ),
                  const Divider(),
                  _buildResourceItem(
                    context,
                    title: 'First Aid Training',
                    description: 'Basic first aid training resources',
                    icon: Icons.medical_services,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    return Consumer<SOSAlertProvider>(
      builder: (context, provider, child) {
        // Only get assigned alerts - exclude resolved ones
        final activeAlerts = provider.alerts.where(
          (alert) => alert.status == 'assigned'
        ).toList();
        
        final Color statusColor = activeAlerts.isNotEmpty 
            ? Colors.orange
            : Colors.green;
        
        final String statusText = activeAlerts.isNotEmpty 
            ? 'You have ${activeAlerts.length} active ${activeAlerts.length == 1 ? 'emergency' : 'emergencies'}'
            : 'No active emergencies';
            
        final IconData statusIcon = activeAlerts.isNotEmpty 
            ? Icons.warning_amber
            : Icons.check_circle;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    if (activeAlerts.isNotEmpty)
                      Text(
                        'Tap to view details',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (activeAlerts.isNotEmpty)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SOSDashboardScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('View'),
                ),
            ],
          ),
        );
      },
    );
  }

  // Build SOS Alerts section to display assigned alerts
  Widget _buildSOSAlertSection() {
    return Consumer<SOSAlertProvider>(
      builder: (context, provider, _) {
        // Get only assigned alerts (not resolved)
        final alerts = provider.alerts.where((alert) => alert.status == 'assigned').toList();
        
        // If no alerts found
        if (alerts.isEmpty) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
            color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Emergencies',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                        size: 60,
                        color: Colors.green,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No assigned emergencies',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _getAssignedAlerts(debug: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Refresh Alerts'),
                    ),
                  ],
                ),
              ),
              ],
            ),
          );
        }
        
        // Display available alerts
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
          color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assigned Emergencies',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _getAssignedAlerts(),
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text('Refresh'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...alerts.map((alert) => _buildAlertItem(alert)).toList(),
            ],
          ),
        );
      },
    );
  }
  
  // Build individual alert item
  Widget _buildAlertItem(SOSAlertModel alert) {
    // Calculate time ago
    String timeAgo = '';
    if (alert.createdAt != null) {
      final now = DateTime.now();
      final difference = now.difference(alert.createdAt!);
      
      if (difference.inMinutes < 60) {
        timeAgo = '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        timeAgo = '${difference.inHours} hours ago';
      } else {
        timeAgo = '${difference.inDays} days ago';
      }
    }
    
    // Format emergency type for display
    String emergencyType = alert.alertType.toUpperCase();
    IconData typeIcon = Icons.warning_amber;
    Color typeColor = Colors.orange;
    
    if (emergencyType.contains('FALL')) {
      typeIcon = Icons.personal_injury;
      typeColor = Colors.red;
    } else if (emergencyType.contains('HEART') || emergencyType.contains('CARDIAC')) {
      typeIcon = Icons.favorite;
      typeColor = Colors.red;
    } else if (emergencyType.contains('MEDICAL')) {
      typeIcon = Icons.medical_services;
      typeColor = Colors.red;
    }
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlertDetailsScreen(alertId: alert.id),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                  padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
              ),
                  child: Icon(typeIcon, color: typeColor, size: 30),
              ),
                SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      Text(
                        emergencyType,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        alert.userName,
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        alert.address.isNotEmpty ? alert.address : 'Location not available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                      ),
                      ),
                    ],
                  ),
            SizedBox(height: 12),
                    Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                      Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                    'URGENT',
                          style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Original static mock data methods
  Widget _buildEmergencyItem(
    BuildContext context, {
    required String title,
    required String location,
    required String time,
    required String severity,
    required IconData icon,
    bool isResolved = false,
  }) {
    final theme = Theme.of(context);
    final Color severityColor = severity == 'High'
        ? Colors.red
        : severity == 'Medium'
            ? Colors.orange
            : Colors.yellow;

    return InkWell(
      onTap: () {
        // View emergency details
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: severityColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        time,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          severity.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: severityColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isResolved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'RESOLVED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        )
                      else
                        TextButton(
                          onPressed: () {
                            // Navigate to emergency details
                          },
                          child: const Text('Respond'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceItem(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        // View resource details
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
} 