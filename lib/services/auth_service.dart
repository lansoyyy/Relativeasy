import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  User? _currentUser;
  final StreamController<User?> _userController = StreamController.broadcast();
  Stream<User?> get user => _userController.stream;

  User? get currentUser => _currentUser;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final userName = prefs.getString('userName');
    final userEmail = prefs.getString('userEmail');

    if (userId != null && userName != null && userEmail != null) {
      _currentUser = User(id: userId, name: userName, email: userEmail);
    }
    _userController.add(_currentUser);
  }

  Future<User?> login(String email, String password) async {
    // In a real app, this would make an API call
    // For now, we'll simulate a successful login
    await Future.delayed(const Duration(milliseconds: 500));

    // Simple validation
    if (email.isEmpty || password.isEmpty) {
      return null;
    }

    // For demo purposes, accept any non-empty email/password
    _currentUser = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: email.split('@')[0],
      email: email,
    );

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _currentUser!.id);
    await prefs.setString('userName', _currentUser!.name);
    await prefs.setString('userEmail', _currentUser!.email);

    _userController.add(_currentUser);
    return _currentUser;
  }

  Future<User?> signup(String name, String email, String password) async {
    // In a real app, this would make an API call
    // For now, we'll simulate a successful signup
    await Future.delayed(const Duration(milliseconds: 500));

    // Simple validation
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return null;
    }

    // For demo purposes, accept any non-empty values
    _currentUser = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
    );

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _currentUser!.id);
    await prefs.setString('userName', _currentUser!.name);
    await prefs.setString('userEmail', _currentUser!.email);

    _userController.add(_currentUser);
    return _currentUser;
  }

  Future<void> logout() async {
    _currentUser = null;

    // Clear shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');

    _userController.add(_currentUser);
  }

  void dispose() {
    _userController.close();
  }
}
