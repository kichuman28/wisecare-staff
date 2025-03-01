import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService() {
    // Set persistence to LOCAL for longer sessions
    _setPersistence();
  }

  // Set Firebase Auth persistence to LOCAL
  Future<void> _setPersistence() async {
    try {
      // This sets session persistence to LOCAL
      // The user will remain logged in until they explicitly sign out
      await _auth.setPersistence(Persistence.LOCAL);
    } catch (e) {
      // Ignore errors since this is just an enhancement
      // The app will still work without this setting
    }
  }

  // Get current authenticated user
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

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

  // Update user profile in Firestore
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updatedData,
  }) async {
    try {
      // Add updatedAt timestamp
      final dataToUpdate = {
        ...updatedData,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Get current user data to determine role
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final role = userData?['role'] as String?;

      // Update in users collection
      await _firestore.collection('users').doc(userId).update(dataToUpdate);

      // Also update in role-specific collection if role exists
      if (role != null) {
        final collectionName = role == 'responder' ? 'responders' : role;
        await _firestore.collection(collectionName).doc(userId).update(dataToUpdate);
      }
    } catch (e) {
      throw Exception('Failed to update user profile: ${e.toString()}');
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

  // Get complete user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
