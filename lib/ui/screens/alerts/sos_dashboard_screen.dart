import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisecare_staff/provider/sos_alert_provider.dart';
import 'package:wisecare_staff/ui/screens/alerts/alert_details_screen.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class SOSDashboardScreen extends StatefulWidget {
  const SOSDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SOSDashboardScreen> createState() => _SOSDashboardScreenState();
}

class _SOSDashboardScreenState extends State<SOSDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _updateTimer;
  DateTime _lastRefreshTime = DateTime.now();
  List<String> _seenAlertIds = [];
  bool _hasNewAlerts = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Start real-time updates when the screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SOSAlertProvider>();
      
      // This will start the real-time listener if it's not already started
      provider.startListeningToAlerts();
      
      // Set up a timer to update the UI every 10 seconds for "last updated" display
      _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        setState(() {
          // Just trigger a rebuild to update the timestamp
        });
      });
    });
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _checkForNewAlerts(List<SOSAlertModel> alerts) {
    // Filter to only check assigned (unresolved) alerts
    final assignedAlerts = alerts.where((alert) => alert.status == 'assigned').toList();
    
    // Check if there are any alerts we haven't seen before
    bool hasNew = false;
    for (final alert in assignedAlerts) {
      if (!_seenAlertIds.contains(alert.id)) {
        hasNew = true;
        break;
      }
    }
    
    if (hasNew && _seenAlertIds.isNotEmpty) {
      // Only show notification if this isn't the first load
      setState(() {
        _hasNewAlerts = true;
      });
      
      // Show a notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You have new emergency alerts!'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              // Clear the new alerts flag and switch to assigned tab
              setState(() {
                _hasNewAlerts = false;
                _tabController.animateTo(0); // Assigned tab is now index 0
              });
            },
          ),
        ),
      );
    }
    
    // Update seen alerts to include only assigned alerts
    _seenAlertIds = assignedAlerts.map((alert) => alert.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('SOS Responder Dashboard'),
            if (_hasNewAlerts)
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Assigned'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: Consumer<SOSAlertProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          // Check for new alerts
          _checkForNewAlerts(provider.alerts);
          
          // Format last updated timestamp
          final lastUpdatedText = DateFormat('h:mm:ss a').format(_lastRefreshTime);
          
          return Column(
            children: [
              // Real-time status banner
              Container(
                color: Colors.blue.shade100,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Real-time updates active · Last update: $lastUpdatedText',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      'Responder ID: ${provider.responderId ?? "Unknown"}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              
              // Alerts tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAlertsList(provider, 'assigned'),
                    _buildAlertsList(provider, 'resolved'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Update refresh time and reset alerts flag
          setState(() {
            _lastRefreshTime = DateTime.now();
            _hasNewAlerts = false;
          });
          
          // Manual refresh (still useful for force refresh)
          context.read<SOSAlertProvider>().fetchAssignedAlerts();
          
          // Show feedback to the user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Manually refreshing alerts...'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }

  Widget _buildAlertsList(SOSAlertProvider provider, String status) {
    final filteredAlerts = provider.alerts.where((alert) => alert.status == status).toList();
    
    if (filteredAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'assigned' ? Icons.notifications_none : Icons.history,
              size: 60,
              color: status == 'assigned' ? Colors.orange : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text('No ${status} alerts', 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Responder ID: ${provider.responderId ?? "Unknown"}', 
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredAlerts.length,
      itemBuilder: (context, index) {
        final alert = filteredAlerts[index];
        return status == 'assigned' 
            ? _buildAlertCard(context, alert)
            : _buildResolvedAlertCard(context, alert);
      },
    );
  }

  Widget _buildAlertCard(BuildContext context, SOSAlertModel alert) {
    final theme = Theme.of(context);
    final priorityColor = alert.priority == 'high'
        ? Colors.red
        : alert.priority == 'medium'
            ? Colors.orange
            : Colors.yellow;
            
    // Format created time
    final createdAt = alert.createdAt != null
        ? DateFormat('MMM d, y h:mm a').format(alert.createdAt!)
        : 'Unknown';
    
    // Check if this is a new alert (for animation)
    final isNew = !_seenAlertIds.contains(alert.id) || _seenAlertIds.isEmpty;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      transform: Matrix4.translationValues(isNew ? 20 : 0, 0, 0),
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: isNew ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: priorityColor,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlertDetailsScreen(alertId: alert.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient info row
                Row(
                  children: [
                    if (alert.userPhoto.isNotEmpty)
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(alert.userPhoto),
                      )
                    else
                      const CircleAvatar(
                        radius: 18,
                        child: Icon(Icons.person, size: 20),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.userName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (alert.userPhone.isNotEmpty)
                            Text(
                              alert.userPhone,
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.priority_high,
                            size: 14,
                            color: priorityColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${alert.priority.toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: priorityColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 24),
                
                // Alert details
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoItem(Icons.alarm, createdAt),
                          const SizedBox(height: 8),
                          _buildInfoItem(Icons.medical_services, alert.alertType),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (alert.location != null)
                            _buildInfoItem(Icons.location_on, 'View location'),
                          const SizedBox(height: 8),
                          _buildInfoItem(Icons.phone, 'Call patient'),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons based on status
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (alert.status == 'assigned')
                      ElevatedButton.icon(
                        onPressed: () {
                          Provider.of<SOSAlertProvider>(context, listen: false)
                              .resolveAlert(alert.id);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Mark Resolved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlertDetailsScreen(alertId: alert.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResolvedAlertCard(BuildContext context, SOSAlertModel alert) {
    final theme = Theme.of(context);
    final priorityColor = alert.priority == 'high'
        ? Colors.red.withOpacity(0.5)
        : alert.priority == 'medium'
            ? Colors.orange.withOpacity(0.5)
            : Colors.yellow.withOpacity(0.5);
            
    // Format created time
    final createdAt = alert.createdAt != null
        ? DateFormat('MMM d, y h:mm a').format(alert.createdAt!)
        : 'Unknown';
    
    // Format resolved time (assuming it's stored in a field in the alert model)
    final resolvedAt = alert.resolvedAt != null
        ? DateFormat('MMM d, y h:mm a').format(alert.resolvedAt!)
        : 'Unknown';
    
    // Calculate duration if both times are available
    String duration = '';
    if (alert.createdAt != null && alert.resolvedAt != null) {
      final difference = alert.resolvedAt!.difference(alert.createdAt!);
      if (difference.inMinutes < 60) {
        duration = '${difference.inMinutes} minutes';
      } else {
        duration = '${(difference.inMinutes / 60).toStringAsFixed(1)} hours';
      }
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlertDetailsScreen(alertId: alert.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resolved badge
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'RESOLVED',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Patient info row
              Row(
                children: [
                  if (alert.userPhoto.isNotEmpty)
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(alert.userPhoto),
                    )
                  else
                    const CircleAvatar(
                      radius: 18,
                      child: Icon(Icons.person, size: 20),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.userName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (alert.userPhone.isNotEmpty)
                          Text(
                            alert.userPhone,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${alert.priority.toUpperCase()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: priorityColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 24),
              
              // Alert timing details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoItem(Icons.alarm, 'Created: $createdAt'),
                  const SizedBox(height: 8),
                  _buildInfoItem(Icons.check_circle_outline, 'Resolved: $resolvedAt'),
                  if (duration.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildInfoItem(
                        Icons.timer, 
                        'Response time: $duration'
                      ),
                    ),
                  const SizedBox(height: 8),
                  _buildInfoItem(Icons.medical_services, alert.alertType),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // View details button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlertDetailsScreen(alertId: alert.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('View History'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
} 