import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SOSAlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current responder ID
  String? get currentResponderId => _auth.currentUser?.uid;

  // Debug method to verify responder identity
  Future<void> debugResponderIdentity() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      print('No user is currently logged in');
      return;
    }
    
    print('Current Auth UID: $uid');
    
    // Check if this UID exists in responders collection
    try {
      final responderDoc = await _firestore.collection('responders').doc(uid).get();
      if (responderDoc.exists) {
        final data = responderDoc.data();
        print('Found responder in responders collection: ${data?['name']} with role ${data?['role']}');
      } else {
        print('No responder found with this UID. Checking all responders...');
        
        // Check all responders to find the current user by email
        final user = _auth.currentUser;
        if (user?.email != null) {
          final querySnapshot = await _firestore
              .collection('responders')
              .where('email', isEqualTo: user!.email)
              .get();
              
          if (querySnapshot.docs.isNotEmpty) {
            final matchingResponder = querySnapshot.docs.first;
            print('Found responder by email: ${matchingResponder.data()['name']} with ID: ${matchingResponder.id}');
            print('This differs from Auth UID. Should use Responder ID: ${matchingResponder.id} instead');
          } else {
            print('No responder found with email: ${user.email}');
          }
        }
      }
    } catch (e) {
      print('Error debugging responder identity: $e');
    }
    
    // Check for assigned alerts to this UID
    try {
      final alertsSnapshot = await _firestore
          .collection('sos_alerts')
          .where('assignedTo', isEqualTo: uid)
          .get();
          
      print('Found ${alertsSnapshot.docs.length} alerts assigned to Auth UID');
      
      // Check for all assigned alerts
      final allAssignedSnapshot = await _firestore
          .collection('sos_alerts')
          .where('status', isEqualTo: 'assigned')
          .get();
          
      print('Total assigned alerts in the system: ${allAssignedSnapshot.docs.length}');
      
      for (var doc in allAssignedSnapshot.docs) {
        final data = doc.data();
        print('Alert ID: ${doc.id}, assignedTo: ${data['assignedTo']}, status: ${data['status']}');
      }
    } catch (e) {
      print('Error checking alerts: $e');
    }
  }

  // Fetch all alerts assigned to the current responder
  Future<QuerySnapshot> getAssignedAlerts() async {
    return await _firestore
        .collection('sos_alerts')
        .where('assignedTo', isEqualTo: currentResponderId)
        .orderBy('responseTimeline.created', descending: true)
        .get();
  }

  // Get a stream of alerts assigned to the current responder
  Stream<QuerySnapshot> getAssignedAlertsStream() {
    return _firestore
        .collection('sos_alerts')
        .where('assignedTo', isEqualTo: currentResponderId)
        .orderBy('responseTimeline.created', descending: true)
        .snapshots();
  }

  // Mark an alert as resolved
  Future<void> resolveAlert(String alertId) async {
    await _firestore.collection('sos_alerts').doc(alertId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get a single alert by ID
  Future<DocumentSnapshot> getAlertById(String alertId) async {
    return await _firestore.collection('sos_alerts').doc(alertId).get();
  }

  // Get user details for an alert
  Future<DocumentSnapshot?> getUserDetails(String userId) async {
    try {
      return await _firestore.collection('users').doc(userId).get();
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  // Add a note to an alert
  Future<void> addNoteToAlert(String alertId, String note) async {
    await _firestore.collection('sos_alerts').doc(alertId).update({
      'notes': FieldValue.arrayUnion([
        {
          'text': note,
          'timestamp': FieldValue.serverTimestamp(),
          'authorId': currentResponderId,
        }
      ])
    });
  }

  // Update responder location (could be used for tracking)
  Future<void> updateResponderLocation(double latitude, double longitude) async {
    if (currentResponderId == null) return;
    
    await _firestore.collection('responders').doc(currentResponderId).update({
      'lastLocation': {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }
    });
  }
} 