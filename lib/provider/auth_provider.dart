import 'package:flutter/material.dart';
import 'package:wisecare_staff/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  String? _userId;
  String? _userRole;
  String? _userName;
  String? _userEmail;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  String? get userRole => _userRole;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  Map<String, dynamic>? get userProfile => _userProfile;

  void setAuthState(
    bool isAuthenticated, {
    String? userId,
    String? userRole,
    String? userName,
    String? userEmail,
    Map<String, dynamic>? userProfile,
  }) {
    _isAuthenticated = isAuthenticated;
    _userId = userId;
    _userRole = userRole;
    _userName = userName;
    _userEmail = userEmail;
    _userProfile = userProfile;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _authService.signInWithEmailAndPassword(email, password);
      final userId = userCredential.user?.uid;

      if (userId != null) {
        final role = await _authService.getUserRole(userId);
        final userProfile = await _authService.getUserProfile(userId);

        setAuthState(
          true,
          userId: userId,
          userRole: role,
          userName: userProfile?['name'] ?? userCredential.user?.displayName,
          userEmail: email,
          userProfile: userProfile,
        );
      }
    } catch (e) {
      setAuthState(false);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUserProfile({
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
      _isLoading = true;
      notifyListeners();

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
      };

      await _authService.createUserInFirestore(
        userId: userId,
        name: name,
        email: email,
        role: role,
        phone: phone,
        address: address,
        emergencyContact: emergencyContact,
        emergencyContactName: emergencyContactName,
        experience: experience,
        preferredShift: preferredShift,
        shiftTiming: shiftTiming,
      );

      setAuthState(
        true,
        userId: userId,
        userRole: role,
        userName: name,
        userEmail: email,
        userProfile: userData,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    if (_userId == null) return null;

    // Don't set loading state or notify listeners here to avoid build-time issues
    try {
      final userProfile = await _authService.getUserProfile(_userId!);

      if (userProfile != null) {
        // Update the local variables without notifying
        _userRole = userProfile['role'] as String?;
        _userName = userProfile['name'] as String?;
        _userEmail = userProfile['email'] as String?;
        _userProfile = userProfile;

        // Only notify after all updates are complete
        notifyListeners();
        return userProfile;
      }
      return null;
    } catch (e) {
      // Handle error but don't change auth state
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      setAuthState(false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
