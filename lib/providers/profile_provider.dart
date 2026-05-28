import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class ProfileProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> updateProfile(UserModel updatedUser, File? newAvatar) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      UserModel finalUser = updatedUser;

      // Nếu có ảnh mới thì upload
      if (newAvatar != null) {
        String avatarUrl = await _uploadAvatar(updatedUser.id, newAvatar);
        finalUser = updatedUser.copyWith(avatarUrl: avatarUrl);
      }

      await _userService.updateUser(finalUser);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String> _uploadAvatar(String uid, File image) async {
    try {
      Reference ref = _storage.ref().child('avatars').child('$uid.jpg');
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception("Lỗi khi upload ảnh đại diện: $e");
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.reauthenticate(currentPassword);
      await _authService.updatePassword(newPassword);
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
}
