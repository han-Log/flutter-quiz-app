// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'database_service.dart';

// login과 관련된 서비스
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. 에러 메시지 한글 변환기
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
      case 'operation-not-allowed':
        return "해당 로그인 방식이 활성화되지 않았습니다.";
      default:
        return "오류가 발생했습니다. ($errorCode)";
    }
  }

  // 2. 이메일 회원가입 (데이터 저장 보완)
  Future<String?> signUpEmail(
    String email,
    String password,
    String nickname,
  ) async {
    // 💡 [추가] Firebase 정책상 6자 미만은 무조건 에러가 나므로 미리 체크
    if (password.length < 6) {
      return "비밀번호는 최소 6자리 이상이어야 합니다.";
    }

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // 계정 생성 후 즉시 Firestore 데이터 생성
        // 💡 주의: DatabaseService 내의 initializeUserData가 에러 없이 작동해야 함
        await DatabaseService().initializeUserData(email, nickname);
        debugPrint("✅ Firestore 유저 데이터 생성 완료");
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ 가입 에러 코드: ${e.code}");
      return getKoreanErrorMessage(e.code);
    } catch (e) {
      debugPrint("❌ 알 수 없는 에러: $e");
      return "회원가입 중 알 수 없는 오류가 발생했습니다.";
    }
  }

  // 3. 이메일 로그인
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
        await DatabaseService().initializeUserData(
          result.user!.email ?? "",
          result.user!.displayName ?? "사용자",
          profileUrl: googleUser.photoUrl,
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return getKoreanErrorMessage(e.code);
    } catch (e) {
      return "구글 로그인 중 오류가 발생했습니다.";
    }
  }

  // 5. 비밀번호 재설정 및 6. 로그아웃 유지...
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
