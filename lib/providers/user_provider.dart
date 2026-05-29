import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProvider() {
    // Listen real-time
    _firestore.collection('users').orderBy('createdAt', descending: true).snapshots().listen(
      (snapshot) {
        _users = snapshot.docs.map((doc) => UserModel.fromJson(doc.data(), doc.id)).toList();
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      }
    );
  }

  Future<bool> addUser(UserModel user) async {
    _setLoading(true);
    try {
      // Dùng set() với id để đồng nhất id nếu cần, hoặc add()
      if (user.id.isNotEmpty) {
        await _firestore.collection('users').doc(user.id).set(user.toJson());
      } else {
        await _firestore.collection('users').add(user.toJson());
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleUserStatus(String id, bool currentStatus) async {
    try {
      await _firestore.collection('users').doc(id).update({
        'isActive': !currentStatus,
      });
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
