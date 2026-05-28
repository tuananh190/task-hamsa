import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy thông tin user hiện tại
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception("Lỗi khi lấy thông tin người dùng: $e");
    }
  }

  // Tạo user mới trong Firestore
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      throw Exception("Lỗi khi tạo dữ liệu người dùng: $e");
    }
  }

  // Cập nhật thông tin user
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      throw Exception("Lỗi khi cập nhật thông tin người dùng: $e");
    }
  }

  // [Admin] Stream danh sách user
  Stream<List<UserModel>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  // [Admin] Khóa hoặc mở khóa tài khoản
  Future<void> toggleUserStatus(String uid, bool isActive) async {
    try {
      await _firestore.collection('users').doc(uid).update({'isActive': isActive});
    } catch (e) {
      throw Exception("Lỗi khi thay đổi trạng thái người dùng: $e");
    }
  }
}
