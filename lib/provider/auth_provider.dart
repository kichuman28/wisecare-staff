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

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  String? get userRole => _userRole;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  void setAuthState(bool isAuthenticated, {
    String? userId, 
    String? userRole,
    String? userName,
    String? userEmail,
  }) {
    _isAuthenticated = isAuthenticated;
    _userId = userId;
    _userRole = userRole;
    _userName = userName;
    _userEmail = userEmail;
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
        
        setAuthState(
          true,
          userId: userId,
          userRole: role,
          userName: userCredential.user?.displayName,
          userEmail: email,
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
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.createUserInFirestore(
        userId: userId,
        name: name,
        email: email,
        role: role,
      );

      setAuthState(
        true,
        userId: userId,
        userRole: role,
        userName: name,
        userEmail: email,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
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