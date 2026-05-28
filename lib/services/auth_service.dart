import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lắng nghe trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng nhập
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Quên mật khẩu
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // Xác thực lại (trước khi đổi mật khẩu)
  Future<void> reauthenticate(String password) async {
    User? user = _auth.currentUser;
    if (user != null && user.email != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      try {
        await user.reauthenticateWithCredential(credential);
      } catch (e) {
        throw Exception("Mật khẩu hiện tại không đúng.");
      }
    }
  }

  // Đổi mật khẩu
  Future<void> updatePassword(String newPassword) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await user.updatePassword(newPassword);
      } catch (e) {
        throw Exception(_handleAuthError(e));
      }
    }
  }

  // [Dành cho Admin] Tạo tài khoản mà không đăng xuất tài khoản hiện tại
  Future<UserCredential> createSecondaryAccount(String email, String password) async {
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      final FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      UserCredential userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      throw Exception(_handleAuthError(e));
    } finally {
      await tempApp.delete();
    }
  }

  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này.';
        case 'wrong-password':
          return 'Sai mật khẩu.';
        case 'email-already-in-use':
          return 'Email này đã được sử dụng.';
        case 'invalid-email':
          return 'Email không hợp lệ.';
        case 'weak-password':
          return 'Mật khẩu quá yếu.';
        default:
          return e.message ?? 'Đã xảy ra lỗi xác thực.';
      }
    }
    return e.toString();
  }
}
