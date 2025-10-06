import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _userData;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserData();
      } else {
        _userData = null;
      }
      notifyListeners();
    });
  }

  User? get currentUser => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _user != null;

  Future<void> _loadUserData() async {
    if (_user != null) {
      try {
        final doc = await _firestore.collection('users').doc(_user!.uid).get();
        if (doc.exists) {
          _userData = doc.data();
          notifyListeners();
          print('User data loaded: \\${_userData}');
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> signOut() async {
    try {
      if (_user != null) {
        String userName =
          (_userData?['name'] as String?)?.isNotEmpty == true
            ? _userData!['name']
            : (_user?.email?.isNotEmpty == true
                ? _user!.email!.split('@')[0]
                : (_user!.uid.isNotEmpty ? _user!.uid : 'User'));
        await _firestore.collection('activities').add({
          'type': 'logout',
          'userId': _user!.uid,
          'userName': userName,
          'timestamp': FieldValue.serverTimestamp(),
          'title': 'Logout',
          'description': 'User logout dari sistem',
        });
      }
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
} 
 