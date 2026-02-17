import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 인증 상태 변화를 실시간으로 구독하는 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 현재 로그인된 사용자 (로그아웃 상태면 null)
  User? get currentUser => _auth.currentUser;

  // 이메일/비밀번호로 회원가입
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 이메일/비밀번호로 로그인
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google OAuth 로그인
  // GoogleSignIn 패키지로 구글 계정 선택 → Firebase credential 생성 → Firebase 로그인
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 사용자가 계정 선택 창을 닫은 경우
        throw Exception('Google sign in aborted');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // Apple ID 로그인 (iOS/macOS 전용)
  // AppleID 인증 → OAuthCredential 생성 → Firebase 로그인
  Future<UserCredential> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw Exception('Apple Sign In is only available on iOS and macOS');
    }

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Apple이 반환한 identityToken/authorizationCode로 OAuthCredential 생성
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await _auth.signInWithCredential(oauthCredential);
    } catch (e) {
      throw Exception('Apple sign in failed: $e');
    }
  }

  // 비밀번호 재설정 이메일 발송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 로그아웃 (Firebase + Google 동시 로그아웃)
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // 계정 삭제 (Firebase 보안 정책상 최근 로그인이 필요할 수 있음)
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  // 현재 비밀번호로 재인증 (비밀번호 변경 전 필수 단계)
  // Firebase는 민감한 작업(비밀번호 변경, 계정 삭제) 전에 재인증을 요구함
  Future<void> reauthenticateWithPassword(String currentPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('사용자가 로그인하지 않았습니다');

      final email = user.email;
      if (email == null) throw Exception('이메일 정보를 찾을 수 없습니다');

      // 현재 이메일 + 입력받은 비밀번호로 EmailAuthCredential 생성
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      // Firebase에 재인증 요청 → 비밀번호 틀리면 wrong-password 예외 발생
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 새 비밀번호로 업데이트 (반드시 reauthenticateWithPassword 호출 후 사용)
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('사용자가 로그인하지 않았습니다');

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // FirebaseAuthException 에러 코드를 한국어 메시지로 변환
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return '비밀번호가 너무 약합니다. 최소 6자 이상 입력해주세요.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다. 로그인하거나 다른 이메일을 사용해주세요.';
      case 'user-not-found':
        return '계정을 찾을 수 없습니다. 회원가입을 먼저 진행해주세요.';
      case 'wrong-password':
        return '현재 비밀번호가 올바르지 않습니다';
      case 'invalid-email':
        return '유효하지 않은 이메일 주소입니다.';
      case 'invalid-credential':
        // Firebase SDK v9+ 에서 wrong-password 대신 반환되는 코드
        return '이메일 또는 비밀번호가 올바르지 않습니다. 확인 후 다시 시도해주세요.';
      case 'user-disabled':
        return '비활성화된 계정입니다. 관리자에게 문의하세요.';
      case 'too-many-requests':
        return '너무 많은 로그인 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
      case 'operation-not-allowed':
        return '이 로그인 방법은 현재 사용할 수 없습니다. Firebase Console에서 활성화해주세요.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      case 'requires-recent-login':
        // 재인증 없이 비밀번호 변경/계정 삭제 시도할 때 발생
        return '보안을 위해 다시 로그인이 필요합니다';
      default:
        return '로그인 오류: ${e.code}\n${e.message ?? "알 수 없는 오류"}';
    }
  }
}
