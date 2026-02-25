import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _dbService = DatabaseService(); // 💡 인스턴스 생성

  // 1. 에러 메시지 한글 변환기 (기존 유지)
  String getKoreanErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return "비밀번호가 너무 취약합니다. (최소 6자리 이상)";
      case 'email-already-in-use':
        return "이미 가입된 이메일입니다.";
      case 'invalid-email':
        return "이메일 형식이 올바르지 않습니다.";
      case 'user-not-found':
        return "등록되지 않은 사용자입니다.";
      case 'wrong-password':
        return "비밀번호가 일치하지 않습니다.";
      case 'network-request-failed':
        return "네트워크 연결이 원활하지 않습니다.";
      case 'invalid-credential':
        return "이메일 또는 비밀번호가 올바르지 않습니다.";
      default:
        return "오류가 발생했습니다. ($errorCode)";
    }
  }

  // 2. 이메일 회원가입
  Future<String?> signUpEmail(
    String email,
    String password,
    String nickname,
  ) async {
    if (password.length < 6) return "비밀번호는 최소 6자리 이상이어야 합니다.";

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // 💡 [핵심] 가입 즉시 Firestore 초기 데이터 생성
        await _dbService.initializeUserData(email, nickname);
        debugPrint("✅ 이메일 가입 및 데이터 초기화 완료");
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return getKoreanErrorMessage(e.code);
    } catch (e) {
      return "회원가입 중 오류가 발생했습니다.";
    }
  }

  // 3. 이메일 로그인 (기존 유지)
  Future<String?> loginWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return getKoreanErrorMessage(e.code);
    } catch (e) {
      return "로그인 중 오류가 발생했습니다.";
    }
  }

  // 4. 구글 로그인
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return "로그인이 취소되었습니다.";

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      if (result.user != null) {
        // 💡 [핵심] 구글 로그인 시에도 초기화 함수 호출
        // DatabaseService 내부에서 '이미 있는 유저'인지 확인하므로 안심하고 호출하세요.
        await _dbService.initializeUserData(
          result.user!.email ?? "",
          result.user!.displayName ?? "사용자",
          profileUrl: result.user!.photoURL,
        );
        debugPrint("✅ 구글 로그인 및 데이터 체크 완료");
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return getKoreanErrorMessage(e.code);
    } catch (e) {
      debugPrint("구글 로그인 에러: $e");
      return "구글 로그인 중 오류가 발생했습니다.";
    }
  }

  // 비밀번호 재설정 (기존 유지)
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return getKoreanErrorMessage(e.code);
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("로그아웃 에러: $e");
    }
  }

  User? get currentUser => _auth.currentUser;
}
