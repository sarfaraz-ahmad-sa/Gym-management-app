import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  AuthService() {
    _checkLoginStatus();
  }

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    // Hardcoded admin credentials
    if (username == 'admin' && password == 'admin123') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    _isLoggedIn = false;
    notifyListeners();
  }
}