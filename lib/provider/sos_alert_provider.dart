import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as maps_toolkit;
import '../services/location_service.dart';
import '../services/sos_alert_service.dart';
import '../services/auth_service.dart';
import 'dart:async';

class SOSAlertModel {
  final String id;
  final String userId;
  final String deviceId;
  final String alertType;
  final String status;
  final String assignedTo;
  final DateTime? assignedAt;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final double? latitude;
  final double? longitude;
  final String userName;
  final String userPhone;
  final String address;
  final String userPhoto;

  // Added missing properties that UI is trying to access
  final String priority;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? user;
  final String? detectionMethod;
  final Map<String, dynamic>? deviceInfo;
  final List<Map<String, dynamic>>? notes;

  // Detailed user information from users collection
  final Map<String, dynamic>? patientDetails;

  SOSAlertModel({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.alertType,
    required this.status,
    required this.assignedTo,
    this.assignedAt,
    this.resolvedAt,
    this.createdAt,
    this.latitude,
    this.longitude,
    required this.userName,
    required this.userPhone,
    required this.address,
    required this.userPhoto,
    this.priority = 'medium',
    this.location,
    this.user,
    this.detectionMethod,
    this.deviceInfo,
    this.notes,
    this.patientDetails,
  });

  factory SOSAlertModel.fromFirestore(DocumentSnapshot doc,
      {Map<String, dynamic>? patientData}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle possible field structure variations
    String assignedTo = 'unassigned';
    if (data['assignedTo'] != null) {
      assignedTo = data['assignedTo'];
    } else if (data.containsKey('responder')) {
      assignedTo = data['responder'] ?? 'unassigned';
    } else if (data.containsKey('assignedResponder')) {
      assignedTo = data['assignedResponder'] ?? 'unassigned';
    }

    // Extract location data
    double? latitude;
    double? longitude;
    Map<String, dynamic>? locationData;

    if (data.containsKey('location') && data['location'] is Map) {
      locationData = Map<String, dynamic>.from(data['location'] as Map);
      latitude = locationData['latitude']?.toDouble();
      longitude = locationData['longitude']?.toDouble();
    } else if (data.containsKey('latitude') && data.containsKey('longitude')) {
      latitude = data['latitude']?.toDouble();
      longitude = data['longitude']?.toDouble();
      locationData = {
        'latitude': latitude,
        'longitude': longitude,
      };
    }

    // Extract user ID for fetching patient details
    final String userId = data['userId'] ?? data['user_id'] ?? '';

    // Handle user data
    Map<String, dynamic>? userData;
    if (data.containsKey('user') && data['user'] is Map) {
      userData = Map<String, dynamic>.from(data['user'] as Map);
    } else {
      // Create user data from flat fields or patient details
      userData = {
        'id': userId,
        'deviceId': data['deviceId'] ?? 'unknown',
        'name':
            patientData?['displayName'] ?? data['userName'] ?? 'Unknown User',
        'phone': patientData?['phone'] ?? data['userPhone'] ?? 'No Phone',
        'email': patientData?['email'] ?? data['userEmail'] ?? 'No Email',
        'photoURL': patientData?['photoURL'] ?? data['userPhoto'] ?? '',
        'displayName':
            patientData?['displayName'] ?? data['userName'] ?? 'Unknown User',
      };
    }

    // Merge patient data if available
    if (patientData != null) {
      userData['displayName'] =
          patientData['displayName'] ?? userData['displayName'];
      userData['email'] = patientData['email'] ?? userData['email'];
      userData['phone'] = patientData['phone'] ?? userData['phone'];
      userData['photoURL'] = patientData['photoURL'] ?? userData['photoURL'];
    }

    // Handle status field variations
    String status = data['status'] ?? 'pending';

    // Extract priority
    String priority = data['priority'] ?? 'medium';

    // Extract device info
    Map<String, dynamic>? deviceInfo;
    if (data.containsKey('deviceInfo') && data['deviceInfo'] is Map) {
      deviceInfo = Map<String, dynamic>.from(data['deviceInfo'] as Map);
    }

    // Extract notes
    List<Map<String, dynamic>>? notes;
    if (data.containsKey('notes') && data['notes'] is List) {
      notes = List<Map<String, dynamic>>.from((data['notes'] as List).map(
          (note) => note is Map<String, dynamic>
              ? note
              : <String, dynamic>{'text': note.toString()}));
    }

    return SOSAlertModel(
      id: doc.id,
      userId: userId,
      deviceId: data['deviceId'] ?? userData['deviceId'] ?? 'unknown',
      alertType: data['alertType'] ?? data['type'] ?? 'emergency',
      status: status,
      assignedTo: assignedTo,
      assignedAt: data['assignedAt'] != null
          ? (data['assignedAt'] as Timestamp).toDate()
          : null,
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      userName: userData['displayName'] ?? 'Unknown User',
      userPhone: userData['phone'] ?? 'No Phone',
      address: data['address'] ?? 'No Address',
      userPhoto: userData['photoURL'] ?? '',
      // Added new properties
      priority: priority,
      location: locationData,
      user: userData,
      detectionMethod: data['detectionMethod'] ?? data['method'] ?? 'manual',
      deviceInfo: deviceInfo,
      notes: notes,
      patientDetails: patientData,
    );
  }
}

class SOSAlertProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final SOSAlertService _sosAlertService = SOSAlertService();

  List<SOSAlertModel> _assignedAlerts = [];
  SOSAlertModel? _currentAlert;
  bool _isLoading = false;

  // Listeners
  StreamSubscription<QuerySnapshot>? _alertsSubscription;
  StreamSubscription<DocumentSnapshot>? _currentAlertSubscription;

  // Location variables
  LatLng? _currentUserLocation;
  LatLng? get currentUserLocation => _currentUserLocation;

  List<SOSAlertModel> get alerts => _assignedAlerts;
  SOSAlertModel? get currentAlert => _currentAlert;
  bool get isLoading => _isLoading;

  // Get responder ID from current user
  String? get responderId => _auth.currentUser?.uid;

  SOSAlertProvider() {
    // Start listening to assigned alerts when provider is created
    startListeningToAlerts();
  }

  @override
  void dispose() {
    // Clean up listeners
    _alertsSubscription?.cancel();
    _currentAlertSubscription?.cancel();
    super.dispose();
  }

  // Start listening to alerts assigned to current responder
  void startListeningToAlerts() {
    if (_auth.currentUser == null) {
      // If user is not logged in, wait for auth state changes
      _auth.authStateChanges().listen((User? user) {
        if (user != null) {
          // User logged in, start listening
          _setupAlertsListener();
        } else {
          // User logged out, clear data
          _assignedAlerts = [];
          notifyListeners();
        }
      });
    } else {
      // User is already logged in, start listening
      _setupAlertsListener();
    }
  }

  // Set up the real-time listener for SOS alerts
  void _setupAlertsListener() {
    // Cancel any existing subscription
    _alertsSubscription?.cancel();

    final user = _auth.currentUser;
    if (user == null) return;

    // Set loading state
    _isLoading = true;
    notifyListeners();

    // Listen to assigned alerts
    _alertsSubscription = _firestore
        .collection('sos_alerts')
        .where('assignedTo', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) async {
      try {
        // Process each alert and fetch user details
        List<SOSAlertModel> newAlerts = [];

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final userId = data['userId'] ?? data['user_id'] ?? '';

          // Only fetch user details if userId is available
          Map<String, dynamic>? patientData;
          if (userId.isNotEmpty) {
            try {
              final userDoc =
                  await _firestore.collection('users').doc(userId).get();
              if (userDoc.exists) {
                patientData = userDoc.data();
              }
            } catch (e) {
              debugPrint('Error fetching user details: $e');
            }
          }

          newAlerts
              .add(SOSAlertModel.fromFirestore(doc, patientData: patientData));
        }

        _assignedAlerts = newAlerts;
        _isLoading = false;
        notifyListeners();

        // Update location if needed
        updateCurrentLocation();
      } catch (e) {
        debugPrint('Error processing alerts update: $e');
        _isLoading = false;
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint('Error in alerts listener: $error');
      _isLoading = false;
      notifyListeners();
    });
  }

  // Update the user's current location
  Future<void> updateCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        _currentUserLocation = LatLng(position.latitude, position.longitude);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  // Manual refresh method (still useful for force refresh)
  Future<void> fetchAssignedAlerts() async {
    // Reset any errors and show loading
    _isLoading = true;
    notifyListeners();

    // Just wait for the listener to update with fresh data
    // and force a location update
    await updateCurrentLocation();

    // Debug: Check responder identity
    await _sosAlertService.debugResponderIdentity();

    // Check total alerts with assigned status
    try {
      final assignedAlertsSnapshot = await _firestore
          .collection('sos_alerts')
          .where('status', isEqualTo: 'assigned')
          .get();

      // Check alerts assigned to current responder
      final user = _auth.currentUser;
      if (user != null) {
        final allAssignedAlertsSnapshot = await _firestore
            .collection('sos_alerts')
            .where('assignedTo', isEqualTo: user.uid)
            .get();
      }

      // End loading state if it wasn't already ended by the listener
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error in manual refresh: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark alert as resolved
  Future<void> resolveAlert(String alertId) async {
    try {
      await _firestore.collection('sos_alerts').doc(alertId).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      // No need to manually refresh as the listener will update
    } catch (e) {
      debugPrint('Error resolving alert: $e');
    }
  }

  // Get more details about a specific alert
  Future<void> fetchAlertDetails(String alertId) async {
    try {
      // Set loading state to true
      _isLoading = true;
      notifyListeners();

      // Cancel any existing subscription
      _currentAlertSubscription?.cancel();

      // Get a one-time snapshot first for immediate data
      final docSnapshot =
          await _firestore.collection('sos_alerts').doc(alertId).get();

      if (!docSnapshot.exists) {
        debugPrint('Alert document not found in Firestore');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      final userId = data['userId'] ?? data['user_id'] ?? '';

      // Fetch user details immediately
      Map<String, dynamic>? patientData;
      if (userId.isNotEmpty) {
        try {
          final userDoc =
              await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            patientData = userDoc.data();
          }
        } catch (e) {
          debugPrint('Error fetching user details: $e');
        }
      }

      // Create the alert model with patient data
      _currentAlert =
          SOSAlertModel.fromFirestore(docSnapshot, patientData: patientData);
      _isLoading = false;
      notifyListeners();

      // Setup real-time listener for future updates to this alert
      _currentAlertSubscription = _firestore
          .collection('sos_alerts')
          .doc(alertId)
          .snapshots()
          .listen((updatedSnapshot) async {
        if (updatedSnapshot.exists) {
          final updatedData = updatedSnapshot.data() as Map<String, dynamic>;
          final updatedUserId =
              updatedData['userId'] ?? updatedData['user_id'] ?? '';

          // Fetch user details again for real-time updates
          Map<String, dynamic>? updatedPatientData;
          if (updatedUserId.isNotEmpty) {
            try {
              final userDoc =
                  await _firestore.collection('users').doc(updatedUserId).get();
              if (userDoc.exists) {
                updatedPatientData = userDoc.data();
              }
            } catch (e) {
              debugPrint('Error fetching user details in real-time update: $e');
            }
          }

          _currentAlert = SOSAlertModel.fromFirestore(updatedSnapshot,
              patientData: updatedPatientData);
          notifyListeners();
        } else {
          debugPrint('Alert document no longer exists');
          _currentAlert = null;
          notifyListeners();
        }
      }, onError: (error) {
        debugPrint('Error in alert real-time listener: $error');
      });
    } catch (e) {
      debugPrint('Error fetching alert details: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate distance between responder and alert location
  double calculateDistance(
      LatLng responderLocation, Map<String, dynamic>? alertLocation) {
    if (alertLocation == null) return 0.0;

    double alertLat = alertLocation['latitude'] ?? 0.0;
    double alertLng = alertLocation['longitude'] ?? 0.0;

    if (alertLat == 0 || alertLng == 0) return 0.0;

    final distance = maps_toolkit.SphericalUtil.computeDistanceBetween(
        maps_toolkit.LatLng(
            responderLocation.latitude, responderLocation.longitude),
        maps_toolkit.LatLng(alertLat, alertLng));

    return distance.toDouble(); // Convert num to double
  }

  // Format timestamp to readable format
  String formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown';
    return DateFormat('MMM d, y h:mm a').format(timestamp);
  }

  // Format distance to readable format
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  // Estimate travel time based on distance (very rough estimate)
  String estimateTravelTime(double distanceInMeters) {
    // Assuming average speed of 30 km/h in urban areas
    // 30 km/h = 8.33 m/s
    final speedInMetersPerSecond = 8.33;

    final seconds = distanceInMeters / speedInMetersPerSecond;
    final minutes = seconds / 60;

    if (minutes < 1) {
      return 'Less than 1 min';
    } else if (minutes < 60) {
      return '${minutes.round()} min';
    } else {
      final hours = minutes / 60;
      return '${hours.toStringAsFixed(1)} hours';
    }
  }

  // Set the current alert directly
  void setCurrentAlert(SOSAlertModel alert) {
    _currentAlert = alert;
    notifyListeners();
  }
}
