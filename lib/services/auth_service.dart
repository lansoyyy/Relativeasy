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
        // User is signed in
        // Get additional user data from Firestore
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .get();

          if (doc.exists) {
            final data = doc.data()!;
            _currentUser = app_user.User(
              id: firebaseUser.uid,
              name: data['name'] ?? firebaseUser.displayName ?? 'User',
              email: firebaseUser.email ?? '',
            );
          } else {
            // Create user document if it doesn't exist
            _currentUser = app_user.User(
              id: firebaseUser.uid,
              name: firebaseUser.displayName ?? 'User',
              email: firebaseUser.email ?? '',
            );

            // Save to Firestore
            await FirebaseFirestore.instance
                .collection('users')
                .doc(firebaseUser.uid)
                .set({
              'name': _currentUser!.name,
              'email': _currentUser!.email,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          // Fallback to basic user info
          _currentUser = app_user.User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? '',
          );
        }
      } else {
        // User is signed out
        _currentUser = null;
      }
      _userController.add(_currentUser);
    });
  }

  // Sign in with email and password
  Future<app_user.User?> login(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        // Get user data from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          _currentUser = app_user.User(
            id: firebaseUser.uid,
            name: data['name'] ?? firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? '',
          );
        } else {
          // Create user document if it doesn't exist
          _currentUser = app_user.User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? '',
          );

          // Save to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .set({
            'name': _currentUser!.name,
            'email': _currentUser!.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        _userController.add(_currentUser);
        return _currentUser;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided for that user.');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('An error occurred during login: $e');
    }
    return null;
  }

  // Sign up with email and password
  Future<app_user.User?> signup(
      String name, String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        // Update user display name
        await firebaseUser.updateDisplayName(name);

        // Create user document in Firestore
        _currentUser = app_user.User(
          id: firebaseUser.uid,
          name: name,
          email: firebaseUser.email ?? '',
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          'name': name,
          'email': firebaseUser.email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _userController.add(_currentUser);
        return _currentUser;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('The account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is badly formatted.');
      } else if (e.code == 'operation-not-allowed') {
        throw Exception('Email/password accounts are not enabled.');
      } else if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else {
        throw Exception('Signup failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('An error occurred during signup: $e');
    }
    return null;
  }

  // Sign out
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _currentUser = null;
    _userController.add(_currentUser);
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw Exception('The email address is badly formatted.');
      } else if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else {
        throw Exception('Failed to send password reset email: ${e.message}');
      }
    }
  }

  void dispose() {
    _userController.close();
  }
}
