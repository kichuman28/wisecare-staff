import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  // Create new user in Firestore
  Future<void> createUserInFirestore({
    required String userId,
    required String name,
    required String email,
    required String role,
    required String phone,
    required String address,
    required String emergencyContact,
    required String emergencyContactName,
    required String experience,
    required String preferredShift,
    required String shiftTiming,
  }) async {
    try {
      final userData = {
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'address': address,
        'emergency_contact': emergencyContact,
        'emergency_contact_name': emergencyContactName,
        'experience': experience,
        'preferred_shift': preferredShift,
        'shift_timing': shiftTiming,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add to users collection
      await _firestore.collection('users').doc(userId).set(userData);

      // Also add to role-specific collection
      final collectionName = role == 'responder' ? 'responders' : role;
      await _firestore.collection(collectionName).doc(userId).set(userData);
    } catch (e) {
      throw Exception('Failed to create user in Firestore: ${e.toString()}');
    }
  }

  // Get user role from Firestore
  Future<String?> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['role'] as String?;
    } catch (e) {
      throw Exception('Failed to get user role: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
} 