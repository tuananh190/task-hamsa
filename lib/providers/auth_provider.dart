import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  User? _firebaseUser;
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _error;

  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _currentUser?.role.toLowerCase() == 'admin';
  bool get isAuthenticated => _firebaseUser != null && _currentUser != null && _currentUser!.isActive;

  StreamSubscription? _authSubscription;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        await _fetchUserDetails(user.uid);
      } else {
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserDetails(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _userService.getUser(uid);
      if (_currentUser != null && !_currentUser!.isActive) {
        // Tài khoản bị khóa, bắt đăng xuất
        _error = "Tài khoản của bạn đã bị khóa.";
        await logout();
      } else {
        _error = null;
      }
    } catch (e) {
      _error = e.toString();
      _currentUser = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signIn(email, password);
      // Listener sẽ tự động load user details
      return true;
    } catch (e) {
      // AUTO-SETUP ADMIN ĐẦU TIÊN
      if (email == 'admin@otakustore.com' && e.toString().contains('Không tìm thấy tài khoản')) {
        try {
          // Tạo account thông qua createSecondaryAccount để không rối loạn
          final uc = await _authService.createSecondaryAccount(email, password);
          
          // Ghi dữ liệu admin vào Firestore
          await FirebaseFirestore.instance.collection('users').doc(uc.user!.uid).set({
            'name': 'Super Admin',
            'email': email,
            'role': 'admin',
            'isActive': true,
            'avatarUrl': '',
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          // Sau khi tạo thành công, tiến hành login lại
          await _authService.signIn(email, password);
          return true;
        } catch (setupError) {
          _error = 'Lỗi khởi tạo admin: ${setupError.toString()}';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      _error = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
  }

  // Reload data cho profile (khi cập nhật xong)
  Future<void> reloadUser() async {
    if (_firebaseUser != null) {
      await _fetchUserDetails(_firebaseUser!.uid);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
