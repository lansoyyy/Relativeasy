import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  app_user.User? _currentUser;
  final StreamController<app_user.User?> _userController =
      StreamController.broadcast();
  Stream<app_user.User?> get user => _userController.stream;

  app_user.User? get currentUser => _currentUser;

  // Initialize Firebase Auth listener
  Future<void> initialize() async {
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await _handleAuthenticatedUser(firebaseUser);
      } else {
        // User is signed out
        _currentUser = null;
        _userController.add(_currentUser);
      }
    });
  }

  // Handle authenticated user with proper error handling
  Future<void> _handleAuthenticatedUser(User firebaseUser) async {
    try {
      // Get additional user data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          _currentUser = app_user.User(
            id: firebaseUser.uid,
            name: _extractName(data, firebaseUser),
            email: firebaseUser.email ?? '',
          );
        } else {
          // Fallback to basic user info
          _currentUser = _createFallbackUser(firebaseUser);
        }
      } else {
        // Create user document if it doesn't exist
        _currentUser = _createFallbackUser(firebaseUser);

        // Save to Firestore
        await _saveUserToFirestore(_currentUser!);
      }
    } catch (e, stackTrace) {
      // Log the error for debugging
      print('Error handling authenticated user: $e');
      print('Stack trace: $stackTrace');

      // Fallback to basic user info
      _currentUser = _createFallbackUser(firebaseUser);
    }

    _userController.add(_currentUser);
  }

  // Extract name with proper error handling
  String _extractName(Map<String, dynamic> data, User firebaseUser) {
    try {
      // Try to get name from Firestore data
      if (data.containsKey('name') && data['name'] != null) {
        return data['name'].toString();
      }

      // Fallback to Firebase user display name
      if (firebaseUser.displayName != null &&
          firebaseUser.displayName!.isNotEmpty) {
        return firebaseUser.displayName!;
      }

      // Last resort fallback
      return 'User';
    } catch (e) {
      return 'User';
    }
  }

  // Create fallback user object
  app_user.User _createFallbackUser(User firebaseUser) {
    return app_user.User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'User',
      email: firebaseUser.email ?? '',
    );
  }

  // Save user to Firestore with error handling
  Future<void> _saveUserToFirestore(app_user.User user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).set({
        'name': user.name,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't throw - we can still function without saving to Firestore
      print('Error saving user to Firestore: $e');
    }
  }

  // Sign in with email and password
  Future<app_user.User?> login(String email, String password) async {
    try {
      // Clear any previous error state
      _errorMessage = null;

      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        await _handleAuthenticatedUser(firebaseUser);
        return _currentUser;
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthException(e);
    } on TypeError catch (e) {
      // Handle the specific PigeonUserDetails error
      print('TypeError during login (likely PigeonUserDetails issue): $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception(
          'Authentication service error. Please try again or restart the app.');
    } catch (e, stackTrace) {
      print('Unexpected error during login: $e');
      print('Stack trace: $stackTrace');
      throw Exception(
          'An unexpected error occurred during login. Please try again.');
    }

    return null;
  }

  // Handle Firebase Auth exceptions
  void _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        throw Exception('No user found for that email.');
      case 'wrong-password':
        throw Exception('Wrong password provided for that user.');
      case 'invalid-email':
        throw Exception('The email address is badly formatted.');
      case 'user-disabled':
        throw Exception('This user account has been disabled.');
      case 'too-many-requests':
        throw Exception(
            'Too many failed login attempts. Please try again later.');
      default:
        throw Exception('Login failed: ${e.message ?? 'Unknown error'}');
    }
  }

  String? _errorMessage;

  // Sign up with email and password
  Future<app_user.User?> signup(
      String name, String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        // Update user display name
        try {
          await firebaseUser.updateDisplayName(name);
        } catch (e) {
          // If we can't update display name, continue anyway
          print('Warning: Could not update display name: $e');
        }

        // Create user document in Firestore
        _currentUser = app_user.User(
          id: firebaseUser.uid,
          name: name,
          email: firebaseUser.email ?? '',
        );

        await _saveUserToFirestore(_currentUser!);

        _userController.add(_currentUser);
        return _currentUser;
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthException(e);
    } catch (e, stackTrace) {
      print('Unexpected error during signup: $e');
      print('Stack trace: $stackTrace');
      throw Exception(
          'An unexpected error occurred during signup. Please try again.');
    }
    return null;
  }

  // Sign out
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      _currentUser = null;
      _userController.add(_currentUser);
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw Exception('The email address is badly formatted.');
        case 'user-not-found':
          throw Exception('No user found for that email.');
        default:
          throw Exception(
              'Failed to send password reset email: ${e.message ?? 'Unknown error'}');
      }
    }
  }

  void dispose() {
    _userController.close();
  }
}
