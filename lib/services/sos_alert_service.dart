import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SOSAlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current responder ID
  String? get currentResponderId => _auth.currentUser?.uid;

  // Debug method to verify responder identity
  Future<void> debugResponderIdentity() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }

    // Check if this UID exists in responders collection
    try {
      final responderDoc =
          await _firestore.collection('responders').doc(uid).get();
      if (responderDoc.exists) {
        final data = responderDoc.data();
        debugPrint(
            'Found responder in responders collection: ${data?['name']} with role ${data?['role']}');
      } else {
        // Check all responders to find the current user by email
        final user = _auth.currentUser;
        if (user?.email != null) {
          final querySnapshot = await _firestore
              .collection('responders')
              .where('email', isEqualTo: user!.email)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final matchingResponder = querySnapshot.docs.first;
            debugPrint(
                'Found responder by email: ${matchingResponder.data()['name']} with ID: ${matchingResponder.id}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error debugging responder identity: $e');
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
      debugPrint('Error fetching user details: $e');
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
  Future<void> updateResponderLocation(
      double latitude, double longitude) async {
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
