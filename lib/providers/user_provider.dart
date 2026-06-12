import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _currentUser;
  Map<String, dynamic>? _userData;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  UserProvider() {
    _init();
  }

  void _init() {
    _isLoading = true;
    _authSubscription = _auth.userChanges().listen((user) {
      _currentUser = user;
      _isLoading = false;
      
      _cancelUserDocSubscription();
      if (user != null) {
        // Mendengarkan perubahan data profil pengguna di Firestore secara real-time
        _userDocSubscription = _db
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((docSnapshot) {
          if (docSnapshot.exists) {
            _userData = docSnapshot.data();
          } else {
            _userData = null;
          }
          notifyListeners();
        }, onError: (error) {
          debugPrint("Error listening to user document: $error");
        });
      } else {
        _userData = null;
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint("Error listening to auth changes: $error");
      _isLoading = false;
      notifyListeners();
    });
  }

  void _cancelUserDocSubscription() {
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelUserDocSubscription();
    super.dispose();
  }
}
