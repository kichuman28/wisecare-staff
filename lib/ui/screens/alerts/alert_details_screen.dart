import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wisecare_staff/provider/sos_alert_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:intl/intl.dart';
import 'package:wisecare_staff/services/location_service.dart';
import 'dart:async';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

class AlertDetailsScreen extends StatefulWidget {
  final String alertId;

  const AlertDetailsScreen({Key? key, required this.alertId}) : super(key: key);

  @override
  State<AlertDetailsScreen> createState() => _AlertDetailsScreenState();
}

// Simple class to store coordinates
class LocationCoordinates {
  final double latitude;
  final double longitude;

  LocationCoordinates(this.latitude, this.longitude);
}

class _AlertDetailsScreenState extends State<AlertDetailsScreen> {
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String? _errorMessage;
  LocationCoordinates? _alertLocation;
  SOSAlertModel? _alert;
  bool _isLaunchingNavigation = false;

  @override
  void initState() {
    super.initState();
    _loadAlertDetails();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadAlertDetails() async {
    try {
      setState(() {
        _isLoadingLocation = true;
        _errorMessage = null;
      });

      // Get the provider
      final provider = Provider.of<SOSAlertProvider>(context, listen: false);

      // Fetch the alert details using the provider's method which properly retrieves patient data
      await provider.fetchAlertDetails(widget.alertId);

      // Get the updated alert with patient data
      SOSAlertModel? alert = provider.currentAlert;

      // If alert is still not available after fetching
      if (alert == null) {
        print("Alert still not available after fetching");
        setState(() {
          _isLoadingLocation = false;
          _errorMessage = "Alert not found";
        });
        return;
      }

      print(
          "Loading alert details: ${alert.id}, has location: ${alert.location != null}, has patient details: ${alert.patientDetails != null}");

      setState(() {
        _alert = alert;
        // Initialize alert location from various possible sources
        _extractAlertLocation(alert);
        _isLoadingLocation = false;
      });

      // Once we have the alert data, get the current location
      _getCurrentLocation();
    } catch (e) {
      print("Error loading alert details: $e");
      setState(() {
        _isLoadingLocation = false;
        _errorMessage = "Failed to load alert details: $e";
      });
    }
  }

  void _extractAlertLocation(SOSAlertModel alert) {
    double? alertLat;
    double? alertLng;

    // Try to get location from alert.location map first
    if (alert.location != null) {
      alertLat = alert.location!['latitude']?.toDouble();
      alertLng = alert.location!['longitude']?.toDouble();
      print("Found location in map: $alertLat, $alertLng");
    }

    // If not found in location map, try direct properties
    if (alertLat == null || alertLng == null) {
      // Try direct latitude/longitude properties if they exist
      if (alert.latitude != null && alert.longitude != null) {
        alertLat = alert.latitude!.toDouble();
        alertLng = alert.longitude!.toDouble();
        print("Using direct lat/lng properties: $alertLat, $alertLng");
      }
    }

    // If we still don't have valid coordinates, show error
    if (alertLat == null ||
        alertLng == null ||
        (alertLat == 0 && alertLng == 0)) {
      print("Alert location coordinates are invalid or not found");
      setState(() {
        _errorMessage = "No location data available for this alert";
      });
      return;
    }

    // Valid coordinates found
    setState(() {
      _alertLocation = LocationCoordinates(alertLat!, alertLng!);
      _errorMessage = null;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
              'Location services are disabled. Please enable GPS in settings.';
          _isLoadingLocation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please enable location services to use navigation features'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage =
                'Location permissions are denied. Please allow location access in app settings.';
            _isLoadingLocation = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permission denied. Some features may not work properly.'),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Location permissions are permanently denied. Please allow location access in app settings.';
          _isLoadingLocation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permission permanently denied. Please enable in device settings.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).catchError((e) {
        print('Error getting location: $e');
        setState(() {
          _errorMessage = 'Could not get current location: $e';
          _isLoadingLocation = false;
        });
        return null;
      });

      if (position == null) {
        return; // Early return if position is null from catchError
      }

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _errorMessage = 'Error getting location: $e';
        _isLoadingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _launchNavigation() async {
    if (_alertLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid location data available for navigation'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLaunchingNavigation = true;
      });

      // Format the coordinates for navigation
      final lat = _alertLocation!.latitude;
      final lng = _alertLocation!.longitude;

      // Create navigation URL for Google Maps
      String googleMapsUrl = await LocationService.getNavigationUrl(lat, lng);

      // Launch the URL
      final launched = await launchUrl(
        Uri.parse(googleMapsUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // If direct app launch failed, try fallback URL
        final fallbackUrl =
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
        final fallbackLaunched = await launchUrl(
          Uri.parse(fallbackUrl),
          mode: LaunchMode.externalNonBrowserApplication,
        );

        if (!fallbackLaunched) {
          // Last resort - open in browser
          final browserLaunched = await launchUrl(
            Uri.parse(fallbackUrl),
            mode: LaunchMode.platformDefault,
          );

          if (!browserLaunched) {
            throw Exception('Could not launch navigation in any mode');
          }
        }
      }
    } catch (e) {
      print('Error launching navigation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch navigation: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLaunchingNavigation = false;
        });
      }
    }
  }

  Future<void> _callUser() async {
    final alert =
        Provider.of<SOSAlertProvider>(context, listen: false).currentAlert;
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
            onPressed: _loadAlertDetails,
            tooltip: 'Refresh alert details',
          ),
        ],
      ),
      body: Consumer<SOSAlertProvider>(
        builder: (context, provider, child) {
          // Show loading indicator if either local state is loading or provider is loading
          if (_isLoadingLocation || provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading alert details...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final alert = provider.currentAlert;

          if (alert == null) {
            return Center(
              child: _errorMessage != null
                  ? Column(
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
                    )
                  : const CircularProgressIndicator(),
            );
          }

          // Calculate distance if both locations are available
          String distanceText = 'Calculating...';
          String estimatedTimeText = 'Calculating...';

          // Extract location data from alert in different possible formats
          double? alertLatitude;
          double? alertLongitude;

          // Try location map first
          if (alert.location != null) {
            alertLatitude = alert.location!['latitude']?.toDouble();
            alertLongitude = alert.location!['longitude']?.toDouble();
          }

          // If not available, try direct properties
          if (alertLatitude == null || alertLongitude == null) {
            if (alert.latitude != null && alert.longitude != null) {
              alertLatitude = alert.latitude!.toDouble();
              alertLongitude = alert.longitude!.toDouble();
            }
          }

          // Now calculate distance if we have valid coordinates
          if (_currentPosition != null &&
              alertLatitude != null &&
              alertLongitude != null) {
            final currentLatitude = _currentPosition!.latitude;
            final currentLongitude = _currentPosition!.longitude;

            // Use Geolocator to calculate distance directly
            final distanceInMeters = Geolocator.distanceBetween(currentLatitude,
                currentLongitude, alertLatitude, alertLongitude);

            distanceText = LocationService.formatDistance(distanceInMeters);
            estimatedTimeText =
                LocationService.estimateTravelTime(distanceInMeters);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient banner for quick identification
                _buildPatientBanner(alert),

                // Show location error message if any
                if (_errorMessage != null &&
                    _errorMessage!.contains('location'))
                  _buildLocationMessageWidget(),

                // Location card with map link - replaces the map container
                if (!_isLoadingLocation && _alertLocation != null)
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Theme.of(context).primaryColor,
                                  size: 30,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Alert Location',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Coordinates: ${_alertLocation!.latitude.toStringAsFixed(6)}, ${_alertLocation!.longitude.toStringAsFixed(6)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            if (_alert?.address != null &&
                                _alert!.address.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  'Address: ${_alert!.address}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: !_isLaunchingNavigation
                                    ? _launchNavigation
                                    : null,
                                icon: const Icon(Icons.map),
                                label: Text(_isLaunchingNavigation
                                    ? 'Opening Maps...'
                                    : 'View in Google Maps'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Quick actions bar
                Container(
                  color: Colors.blueGrey.shade50,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.navigation,
                        label: 'Navigate',
                        onTap:
                            _alertLocation != null ? _launchNavigation : null,
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

                // Alert details card with detailed information
                Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User info card - moved to top with more prominence
                        _buildUserInfoCard(context, alert),

                        // Location details card
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
                                _buildInfoRow(
                                    'Est. Travel Time', estimatedTimeText),
                                _buildInfoRow('Address', alert.address),

                                // Display coordinates from any available source
                                if (alertLatitude != null &&
                                    alertLongitude != null) ...[
                                  _buildInfoRow(
                                      'Latitude', alertLatitude.toString()),
                                  _buildInfoRow(
                                      'Longitude', alertLongitude.toString()),
                                ]
                              ],
                            ),
                          ),
                        ),

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
                                _buildInfoRow(
                                    'Status', _getStatusChip(alert.status)),
                                _buildInfoRow('Priority',
                                    _getPriorityChip(alert.priority)),
                                _buildInfoRow('Alert Type', alert.alertType),
                                _buildInfoRow('Reported',
                                    provider.formatTimestamp(alert.createdAt)),
                                if (alert.assignedAt != null)
                                  _buildInfoRow(
                                      'Assigned',
                                      provider
                                          .formatTimestamp(alert.assignedAt)),
                                if (alert.resolvedAt != null)
                                  _buildInfoRow(
                                      'Resolved',
                                      provider
                                          .formatTimestamp(alert.resolvedAt)),
                                _buildInfoRow('Detection',
                                    alert.detectionMethod ?? 'Manual'),
                              ],
                            ),
                          ),
                        ),

                        // Device info card if available
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
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const Divider(),
                                  _buildInfoRow('Model',
                                      alert.deviceInfo!['model'] ?? 'Unknown'),
                                  _buildInfoRow(
                                      'Platform',
                                      alert.deviceInfo!['platform'] ??
                                          'Unknown'),
                                  _buildInfoRow(
                                      'OS Version',
                                      alert.deviceInfo!['osVersion'] ??
                                          'Unknown'),
                                  _buildInfoRow('Battery',
                                      '${alert.deviceInfo!['batteryLevel'] ?? 'Unknown'}%'),
                                  _buildInfoRow(
                                      'Network',
                                      alert.deviceInfo!['networkType'] ??
                                          'Unknown'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatientBanner(SOSAlertModel alert) {
    // Check if we have patient details
    final hasPatientDetails =
        alert.patientDetails != null && alert.patientDetails!.isNotEmpty;

    // Prioritize patient details display name if available
    final displayName = hasPatientDetails
        ? (alert.patientDetails!['displayName'] ?? alert.userName)
        : alert.userName;

    // Get photo URL from patient details if available
    final photoUrl =
        hasPatientDetails && alert.patientDetails!['photoURL'] != null
            ? alert.patientDetails!['photoURL']
            : alert.userPhoto;

    return Container(
      width: double.infinity,
      color: Colors.blue.shade800,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          if (photoUrl.isNotEmpty)
            CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(photoUrl),
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
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('h:mm a')
                          .format(alert.createdAt ?? DateTime.now()),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
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
    final bool hasPatientDetails = patientInfo.isNotEmpty;

    // Determine photo URL, prioritizing patientDetails
    final String photoUrl = patientInfo['photoURL'] ?? alert.userPhoto;

    // Determine display name, prioritizing patientDetails
    final String displayName = patientInfo['displayName'] ?? alert.userName;

    // Determine email
    final String email = patientInfo['email'] ?? 'Not available';

    // Determine phone
    final String phone = patientInfo['phone'] ?? alert.userPhone;

    // Log what data we're displaying for debugging
    print(
        'Displaying user info - Name: $displayName, Email: $email, Phone: $phone, Has Patient Details: $hasPatientDetails');

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
            if (photoUrl.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(photoUrl),
                  ),
                ),
              ),
            _buildInfoRow('Name', displayName),
            _buildInfoRow('Email', email),
            _buildInfoRow('Phone', phone),
            if (patientInfo['createdAt'] != null &&
                patientInfo['createdAt'] is Timestamp)
              _buildInfoRow(
                  'Account Created',
                  DateFormat('MMM d, y')
                      .format(patientInfo['createdAt'].toDate())),
            if (patientInfo['lastLoginAt'] != null &&
                patientInfo['lastLoginAt'] is Timestamp)
              _buildInfoRow(
                  'Last Login',
                  DateFormat('MMM d, y h:mm a')
                      .format(patientInfo['lastLoginAt'].toDate())),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color:
                    isDisabled ? Colors.grey : Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDisabled ? Colors.grey : null,
                  ),
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

  // Display a widget based on error message or loading state
  Widget _buildLocationMessageWidget() {
    if (_isLoadingLocation) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Fetching location data...'),
            ],
          ),
        ),
      );
    } else if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _getCurrentLocation();
                _loadAlertDetails();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink(); // No message to show
    }
  }
}
