import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. 에러 메시지 한글 변환기
  String getKoreanErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return "비밀번호가 너무 취약합니다.";
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
      case 'operation-not-allowed':
        return "해당 로그인 방식이 활성화되지 않았습니다.";
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
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        // 새 사용자 초기 데이터 생성
        await DatabaseService().initializeUserData(email, nickname);
      }
      return null; // 성공 시 null 반환
    } on FirebaseAuthException catch (e) {
      return getKoreanErrorMessage(e.code);
    } catch (e) {
      return "회원가입 중 알 수 없는 오류가 발생했습니다.";
    }
  }

  // 3. 이메일 로그인
  Future<String?> loginWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // 성공
    } on FirebaseAuthException catch (e) {
      return getKoreanErrorMessage(e.code);
    } catch (e) {
      return "로그인 중 오류가 발생했습니다.";
    }
  }

  // 4. 구글 로그인
  Future<String?> signInWithGoogle() async {
    try {
      // 구글 로그인 팝업 띄우기
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return "로그인이 취소되었습니다.";

      // 구글 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 구글 자격 증명으로 로그인
      UserCredential result = await _auth.signInWithCredential(credential);

      if (result.user != null) {
        // [중요] 기존 사용자인지 확인 후 처음인 경우에만 초기화
        // DatabaseService에 해당 로직이 포함되어 있다면 그대로 사용합니다.
        await DatabaseService().initializeUserData(
          result.user!.email ?? "",
          result.user!.displayName ?? "사용자",
        );
      }
      return null; // 성공
    } on FirebaseAuthException catch (e) {
      return getKoreanErrorMessage(e.code);
    } catch (e) {
      return "구글 로그인 중 오류가 발생했습니다.";
    }
  }

  // 5. 비밀번호 재설정 메일 발송
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return getKoreanErrorMessage(e.code);
    } catch (e) {
      return "메일 발송 중 오류가 발생했습니다.";
    }
  }

  // 6. 로그아웃
  Future<void> signOut() async {
    try {
      // 구글 로그인 세션과 Firebase 세션 모두 종료
      await GoogleSignIn().signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("로그아웃 에러: $e");
    }
  }

  // 현재 로그인된 유저 확인용 (필요 시)
  User? get currentUser => _auth.currentUser;
}
