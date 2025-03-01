import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wisecare_staff/provider/sos_alert_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:intl/intl.dart';
import 'package:wisecare_staff/services/location_service.dart';

class AlertDetailsScreen extends StatefulWidget {
  final String alertId;

  const AlertDetailsScreen({Key? key, required this.alertId}) : super(key: key);

  @override
  State<AlertDetailsScreen> createState() => _AlertDetailsScreenState();
}

class _AlertDetailsScreenState extends State<AlertDetailsScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoadingLocation = false;
  String? _errorMessage;
  LatLng? _alertLocation;

  @override
  void initState() {
    super.initState();
    _fetchAlertDetails();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchAlertDetails() async {
    try {
      await Provider.of<SOSAlertProvider>(context, listen: false)
          .fetchAlertDetails(widget.alertId);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading alert details: $e';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
      
      // Update the map with the alert and responder locations
      _updateMapMarkers();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: $e';
        _isLoadingLocation = false;
      });
    }
  }

  void _updateMapMarkers() {
    final alert = Provider.of<SOSAlertProvider>(context, listen: false).currentAlert;
    if (alert == null || alert.location == null) {
      print("Alert is null or has no location data");
      return;
    }
    
    final double alertLat = alert.location!['latitude']?.toDouble() ?? 0.0;
    final double alertLng = alert.location!['longitude']?.toDouble() ?? 0.0;
    
    if (alertLat == 0 || alertLng == 0) {
      print("Alert location coordinates are invalid");
      return;
    }
    
    setState(() {
      _alertLocation = LatLng(alertLat, alertLng);
      _markers = {};
      
      // Add alert marker
      _markers.add(
        Marker(
          markerId: const MarkerId('alert_location'),
          position: _alertLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Emergency Location',
            snippet: alert.userName,
          ),
        ),
      );
      
      // Add responder marker if location is available
      if (_currentPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('responder_location'),
            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(
              title: 'Your Location',
              snippet: 'Responder',
            ),
          ),
        );
      }
    });
    
    // Move camera to show both markers
    _moveCamera();
  }

  void _moveCamera() {
    if (_mapController == null || _alertLocation == null) return;
    
    if (_currentPosition != null) {
      // Calculate bounds to include both markers
      final LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          _alertLocation!.latitude < _currentPosition!.latitude
              ? _alertLocation!.latitude
              : _currentPosition!.latitude,
          _alertLocation!.longitude < _currentPosition!.longitude
              ? _alertLocation!.longitude
              : _currentPosition!.longitude,
        ),
        northeast: LatLng(
          _alertLocation!.latitude > _currentPosition!.latitude
              ? _alertLocation!.latitude
              : _currentPosition!.latitude,
          _alertLocation!.longitude > _currentPosition!.longitude
              ? _alertLocation!.longitude
              : _currentPosition!.longitude,
        ),
      );
      
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    } else {
      // Just zoom to alert location
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_alertLocation!, 15));
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMapMarkers();
  }

  Future<void> _launchNavigation() async {
    if (_alertLocation == null) return;
    
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${_alertLocation!.latitude},${_alertLocation!.longitude}&travelmode=driving';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch navigation'),
        ),
      );
    }
  }

  Future<void> _callUser() async {
    final alert = Provider.of<SOSAlertProvider>(context, listen: false).currentAlert;
    if (alert == null) return;
    
    final phoneNumber = alert.userPhone;
    
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available'),
        ),
      );
      return;
    }
    
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch phone dialer'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alert Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAlertDetails,
            tooltip: 'Refresh alert details',
          ),
        ],
      ),
      body: Consumer<SOSAlertProvider>(
        builder: (context, provider, child) {
          final alert = provider.currentAlert;
          
          if (alert == null) {
            return Center(
              child: _errorMessage != null
                  ? Text(_errorMessage!)
                  : const CircularProgressIndicator(),
            );
          }
          
          // Calculate distance if both locations are available
          String distanceText = 'Calculating...';
          String estimatedTimeText = 'Calculating...';
          
          if (_currentPosition != null && alert.location != null) {
            final currentLocation = LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            );
            
            final alertLocation = LatLng(
              alert.location!['latitude']?.toDouble() ?? 0.0,
              alert.location!['longitude']?.toDouble() ?? 0.0,
            );
            
            // Use LocationService instead of provider for distance calculation
            final distanceInMeters = LocationService.calculateDistance(
              currentLocation,
              alertLocation,
            );
            
            distanceText = LocationService.formatDistance(distanceInMeters);
            estimatedTimeText = LocationService.estimateTravelTime(distanceInMeters);
          }
          
          // Get timestamp for real-time UI update display
          final lastUpdated = DateTime.now();
          final lastUpdatedText = DateFormat('h:mm:ss a').format(lastUpdated);
          
          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient banner for quick identification
                    _buildPatientBanner(alert),
                    
                    // Map section
                    SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: _isLoadingLocation
                          ? const Center(child: CircularProgressIndicator())
                          : _alertLocation == null
                              ? const Center(child: Text('No location data available'))
                              : GoogleMap(
                                  onMapCreated: _onMapCreated,
                                  initialCameraPosition: CameraPosition(
                                    target: _alertLocation!,
                                    zoom: 15,
                                  ),
                                  markers: _markers,
                                  myLocationEnabled: true,
                                  myLocationButtonEnabled: true,
                                  mapToolbarEnabled: true,
                                  compassEnabled: true,
                                ),
                    ),
                    
                    // Quick actions bar
                    Container(
                      color: Colors.blueGrey.shade50,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickActionButton(
                            icon: Icons.navigation,
                            label: 'Navigate',
                            onTap: _launchNavigation,
                          ),
                          _buildQuickActionButton(
                            icon: Icons.phone,
                            label: 'Call User',
                            onTap: _callUser,
                          ),
                          _buildQuickActionButton(
                            icon: Icons.check_circle,
                            label: 'Resolve',
                            onTap: () {
                              provider.resolveAlert(alert.id);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User info card - moved to top with more prominence
                          _buildUserInfoCard(context, alert),
                          
                          // Emergency info card
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergency Information',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const Divider(),
                                  _buildInfoRow('Status', _getStatusChip(alert.status)),
                                  _buildInfoRow('Priority', _getPriorityChip(alert.priority)),
                                  _buildInfoRow('Alert Type', alert.alertType),
                                  _buildInfoRow('Reported', provider.formatTimestamp(alert.createdAt)),
                                  if (alert.assignedAt != null)
                                    _buildInfoRow('Assigned', provider.formatTimestamp(alert.assignedAt)),
                                  if (alert.resolvedAt != null)
                                    _buildInfoRow('Resolved', provider.formatTimestamp(alert.resolvedAt)),
                                  _buildInfoRow('Detection', alert.detectionMethod ?? 'Manual'),
                                ],
                              ),
                            ),
                          ),
                          
                          // Distance and time estimation
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Location Details',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const Divider(),
                                  _buildInfoRow('Distance', distanceText),
                                  _buildInfoRow('Est. Travel Time', estimatedTimeText),
                                  _buildInfoRow('Address', alert.address),
                                  if (alert.location != null) ...[
                                    _buildInfoRow('Latitude', '${alert.location!['latitude'] ?? 0.0}'),
                                    _buildInfoRow('Longitude', '${alert.location!['longitude'] ?? 0.0}'),
                                    if (alert.location!['accuracy'] != null)
                                      _buildInfoRow('Accuracy', '${alert.location!['accuracy']} meters'),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          
                          // Device info card
                          if (alert.deviceInfo != null)
                            Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Device Information',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const Divider(),
                                    _buildInfoRow('Model', alert.deviceInfo!['model'] ?? 'Unknown'),
                                    _buildInfoRow('Platform', alert.deviceInfo!['platform'] ?? 'Unknown'),
                                    _buildInfoRow('OS Version', alert.deviceInfo!['osVersion'] ?? 'Unknown'),
                                    _buildInfoRow('Battery', '${alert.deviceInfo!['batteryLevel'] ?? 'Unknown'}%'),
                                    _buildInfoRow('Network', alert.deviceInfo!['networkType'] ?? 'Unknown'),
                                  ],
                                ),
                              ),
                            ),
                          
                          // Notes if any
                          if (alert.notes != null && alert.notes!.isNotEmpty)
                            Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notes',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const Divider(),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: alert.notes!.length,
                                      itemBuilder: (context, index) {
                                        final note = alert.notes![index];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                note['text'] ?? '',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                              if (note['timestamp'] != null && note['timestamp'] is Timestamp)
                                                Text(
                                                  DateFormat('MMM d, y h:mm a').format(note['timestamp'].toDate()),
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                          // Last updated timestamp
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Text(
                                'Last updated: $lastUpdatedText',
                                style: const TextStyle(
                                  fontSize: 12, 
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Real-time status indicator
              if (alert.status == 'assigned')
                Positioned(
                  right: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildPatientBanner(SOSAlertModel alert) {
    return Container(
      width: double.infinity,
      color: Colors.blue.shade800,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          if (alert.userPhoto.isNotEmpty)
            CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(alert.userPhoto),
              backgroundColor: Colors.white,
            )
          else
            const CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 30, color: Colors.blue),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('h:mm a').format(alert.createdAt ?? DateTime.now()),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _getStatusChip(alert.status),
        ],
      ),
    );
  }
  
  Widget _buildUserInfoCard(BuildContext context, SOSAlertModel alert) {
    // Get user details from patient details or user field
    final Map<String, dynamic> patientInfo = alert.patientDetails ?? {};
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Patient Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (alert.userId.isNotEmpty)
                  Tooltip(
                    message: 'Patient ID: ${alert.userId}',
                    child: const Icon(Icons.info_outline, size: 16),
                  ),
              ],
            ),
            const Divider(),
            if (alert.userPhoto.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(alert.userPhoto),
                  ),
                ),
              ),
            _buildInfoRow('Name', patientInfo['displayName'] ?? alert.userName),
            _buildInfoRow('Email', patientInfo['email'] ?? 'Not available'),
            _buildInfoRow('Phone', patientInfo['phone'] ?? alert.userPhone),
            if (patientInfo['createdAt'] != null && patientInfo['createdAt'] is Timestamp)
              _buildInfoRow('Account Created', 
                DateFormat('MMM d, y').format(patientInfo['createdAt'].toDate())),
            if (patientInfo['lastLoginAt'] != null && patientInfo['lastLoginAt'] is Timestamp)
              _buildInfoRow('Last Login', 
                DateFormat('MMM d, y h:mm a').format(patientInfo['lastLoginAt'].toDate())),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: value is Widget
                ? value
                : Text(
                    value?.toString() ?? 'Not available',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusChip(String status) {
    final Color color = status == 'pending'
        ? Colors.red
        : status == 'assigned'
            ? Colors.orange
            : status == 'resolved'
                ? Colors.green
                : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _getPriorityChip(String priority) {
    final Color color = priority == 'high'
        ? Colors.red
        : priority == 'medium'
            ? Colors.orange
            : Colors.yellow;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 