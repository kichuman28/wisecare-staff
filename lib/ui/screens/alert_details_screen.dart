import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../provider/sos_alert_provider.dart';
import '../../services/location_service.dart';

class AlertDetailsScreen extends StatefulWidget {
  final String alertId;

  const AlertDetailsScreen({required this.alertId, Key? key}) : super(key: key);

  @override
  _AlertDetailsScreenState createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends State<AlertDetailsScreen> {
  SOSAlertModel? _alert;
  bool _isLoading = true;
  bool _isResolvingAlert = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAlertDetails();
  }

  Future<void> _loadAlertDetails() async {
    try {
      setState(() => _isLoading = true);
      
      // Debug information
      print('Loading alert details for ID: ${widget.alertId}');
      
      // Get the alert details from Firestore directly for debugging
      final doc = await FirebaseFirestore.instance
          .collection('sos_alerts')
          .doc(widget.alertId)
          .get();
          
      if (!doc.exists) {
        print('Alert document not found in Firestore');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Alert not found';
        });
        return;
      }
      
      print('Alert document data: ${doc.data()}');
      
      // Create the alert model
      final alert = SOSAlertModel.fromFirestore(doc);
      setState(() {
        _alert = alert;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading alert details: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load alert details: $e';
      });
    }
  }

  Future<void> _resolveAlert() async {
    final sosProvider = Provider.of<SOSAlertProvider>(context, listen: false);
    
    try {
      setState(() => _isResolvingAlert = true);
      
      // Debug information
      print('Resolving alert ID: ${widget.alertId}');
      
      await sosProvider.resolveAlert(widget.alertId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alert resolved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back after resolving
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error resolving alert: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resolve alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isResolvingAlert = false);
      }
    }
  }

  Future<void> _refreshAlertDetails() async {
    await _loadAlertDetails();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert details refreshed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _launchNavigation() async {
    if (_alert == null || _alert!.latitude == null || _alert!.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location coordinates not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final url = LocationService.getNavigationUrl(
      _alert!.latitude!,
      _alert!.longitude!,
    );
    
    print('Navigation URL: $url');
    
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch navigation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error launching navigation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching navigation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _callUser() async {
    if (_alert == null || _alert!.userPhone.isEmpty || _alert!.userPhone == 'No Phone') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final phoneNumber = _alert!.userPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = 'tel:$phoneNumber';
    
    print('Phone URL: $url');
    
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error launching phone call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching phone call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alert Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshAlertDetails,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _alert != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAlertDetails,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_alert == null) {
      return Center(
        child: Text('Alert not found'),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _refreshAlertDetails,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlertHeader(),
            SizedBox(height: 24),
            _buildUserDetailsCard(),
            SizedBox(height: 16),
            _buildLocationCard(),
            SizedBox(height: 16),
            _buildAlertInfoCard(),
            SizedBox(height: 16),
            _buildActionsCard(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertHeader() {
    String alertType = _alert!.alertType.toUpperCase();
    IconData typeIcon = Icons.warning_amber;
    Color typeColor = Colors.orange;
    
    if (alertType.contains('FALL')) {
      typeIcon = Icons.personal_injury;
      typeColor = Colors.red;
    } else if (alertType.contains('HEART') || alertType.contains('CARDIAC')) {
      typeIcon = Icons.favorite;
      typeColor = Colors.red;
    } else if (alertType.contains('MEDICAL')) {
      typeIcon = Icons.medical_services;
      typeColor = Colors.red;
    }
    
    String timeAgo = '';
    if (_alert!.createdAt != null) {
      final now = DateTime.now();
      final difference = now.difference(_alert!.createdAt!);
      
      if (difference.inMinutes < 60) {
        timeAgo = '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        timeAgo = '${difference.inHours} hours ago';
      } else {
        timeAgo = '${difference.inDays} days ago';
      }
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: typeColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 32),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alertType,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Reported $timeAgo',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

  Widget _buildUserDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildUserDetailRow(
              Icons.person,
              'Name',
              _alert!.userName,
            ),
            Divider(),
            _buildUserDetailRow(
              Icons.phone,
              'Phone',
              _alert!.userPhone,
              onTap: _callUser,
            ),
            Divider(),
            _buildUserDetailRow(
              Icons.smartphone,
              'Device ID',
              _alert!.deviceId,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final locationAvailable = _alert!.latitude != null && _alert!.longitude != null;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (locationAvailable)
                  TextButton.icon(
                    onPressed: _launchNavigation,
                    icon: Icon(Icons.directions, size: 16),
                    label: Text('Navigate'),
                  ),
              ],
            ),
            SizedBox(height: 8),
            if (_alert!.address.isNotEmpty)
              _buildUserDetailRow(
                Icons.location_on,
                'Address',
                _alert!.address,
              ),
            if (locationAvailable) Divider(),
            if (locationAvailable)
              _buildUserDetailRow(
                Icons.map,
                'Coordinates',
                'Lat: ${_alert!.latitude!.toStringAsFixed(6)}, Lng: ${_alert!.longitude!.toStringAsFixed(6)}',
              ),
            if (!locationAvailable)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Location information not available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertInfoCard() {
    final createdDate = _alert!.createdAt != null
        ? DateFormat('MMM dd, yyyy hh:mm a').format(_alert!.createdAt!)
        : 'Unknown';
    
    final assignedDate = _alert!.assignedAt != null
        ? DateFormat('MMM dd, yyyy hh:mm a').format(_alert!.assignedAt!)
        : 'Not assigned';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alert Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildUserDetailRow(
              Icons.event,
              'Created At',
              createdDate,
            ),
            Divider(),
            _buildUserDetailRow(
              Icons.assignment_turned_in,
              'Assigned At',
              assignedDate,
            ),
            Divider(),
            _buildUserDetailRow(
              Icons.analytics,
              'Status',
              _alert!.status.toUpperCase(),
            ),
            Divider(),
            _buildUserDetailRow(
              Icons.confirmation_number,
              'Alert ID',
              _alert!.id,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  Icons.call,
                  'Call User',
                  Colors.green,
                  _callUser,
                ),
                _buildActionButton(
                  Icons.directions,
                  'Navigate',
                  Colors.blue,
                  _launchNavigation,
                ),
                _buildActionButton(
                  Icons.check_circle,
                  'Resolve',
                  Colors.orange,
                  _resolveAlert,
                  isLoading: _isResolvingAlert,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDetailRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed, {
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, -1),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _callUser,
                icon: Icon(Icons.call),
                label: Text('Call User'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isResolvingAlert ? null : _resolveAlert,
                icon: _isResolvingAlert
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.check_circle),
                label: Text(_isResolvingAlert ? 'Resolving...' : 'Resolve Alert'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 