import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? _userId;
  String? _userRole;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userRole => _userRole;

  void setAuthState(bool isAuthenticated, {String? userId, String? userRole}) {
    _isAuthenticated = isAuthenticated;
    _userId = userId;
    _userRole = userRole;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _userId = null;
    _userRole = null;
    notifyListeners();
  }
} 