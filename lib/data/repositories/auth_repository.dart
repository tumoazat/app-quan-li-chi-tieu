import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      developer.log('✅ Login success: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      developer.log('❌ Login FirebaseAuthException: code=${e.code}, message=${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      developer.log('❌ Login unknown error: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();

      developer.log('✅ Register success: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      developer.log('❌ Register FirebaseAuthException: code=${e.code}, message=${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      developer.log('❌ Register unknown error: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in aborted');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      developer.log('❌ Google sign-in FirebaseAuthException: code=${e.code}, message=${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      developer.log('❌ Google sign-in error: $e');
      throw Exception('Đăng nhập Google thất bại: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      await _firebaseAuth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'Không tìm thấy tài khoản với email này';
        break;
      case 'wrong-password':
        message = 'Mật khẩu không chính xác';
        break;
      case 'invalid-credential':
        message = 'Email hoặc mật khẩu không đúng';
        break;
      case 'email-already-in-use':
        message = 'Email này đã được sử dụng';
        break;
      case 'invalid-email':
        message = 'Email không hợp lệ';
        break;
      case 'weak-password':
        message = 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn';
        break;
      case 'user-disabled':
        message = 'Tài khoản này đã bị vô hiệu hóa';
        break;
      case 'too-many-requests':
        message = 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
        break;
      case 'operation-not-allowed':
        message = 'Phương thức đăng nhập Email/Password chưa được bật trong Firebase Console. Vào Firebase Console → Authentication → Sign-in method → Bật Email/Password';
        break;
      case 'requires-recent-login':
        message = 'Vui lòng đăng nhập lại để thực hiện thao tác này';
        break;
      case 'network-request-failed':
        message = 'Lỗi kết nối mạng. Vui lòng kiểm tra internet';
        break;
      case 'channel-error':
        message = 'Lỗi kênh liên lạc. Vui lòng thử lại';
        break;
      default:
        message = 'Lỗi xác thực [${e.code}]: ${e.message ?? 'Không xác định'}';
        break;
    }
    return Exception(message);
  }
}
