import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<UserModel>> get usersStream => _userService.getUsersStream();

  Future<bool> createEmployee(UserModel newUser, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Tạo auth trên Secondary App
      var credential = await _authService.createSecondaryAccount(newUser.email, password);
      
      // 2. Lưu vào Firestore với ID mới
      if (credential.user != null) {
        UserModel userToSave = newUser.copyWith(id: credential.user!.uid);
        await _userService.createUser(userToSave);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmployee(UserModel user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userService.updateUser(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleUserStatus(String uid, bool currentStatus) async {
    try {
      await _userService.toggleUserStatus(uid, !currentStatus);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
