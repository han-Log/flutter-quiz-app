import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 💡 현재 로그인된 유저의 UID를 안전하게 가져오기
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  // 1. 회원가입/로그인 시 유저 데이터 생성 및 보완
  Future<void> initializeUserData(
    String email,
    String nickname, {
    String? profileUrl,
  }) async {
    if (uid == null) {
      debugPrint("❌ initializeUserData 실패: 로그인된 UID가 없음");
      return;
    }

    final categories = ['사회', '인문', '예술', '역사', '경제', '과학', '일상'];
    Map<String, dynamic> initialStats = {
      for (var cat in categories) cat: {'total': 0, 'correct': 0},
    };

    try {
      // 💡 [개선] exists 체크 대신 set(merge: true)를 사용해 데이터 생성을 보장함
      // 기존 유저라면 필드를 유지하고, 없다면 새로 생성합니다.
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'nickname': nickname,
        'profileUrl': profileUrl,
        'score': FieldValue.increment(0), // 숫자 타입 보장
        'categories': initialStats,
        'createdAt':
            FieldValue.serverTimestamp(), // ⚠️ 인덱스 오타(createadAt) 수정 확인 필수!
      }, SetOptions(merge: true));

      debugPrint("✅ Firestore 유저 데이터 생성/업데이트 성공: $uid");
    } catch (e) {
      debugPrint("❌ Firestore 데이터 저장 에러: $e");
      rethrow; // AuthService에서 에러를 잡을 수 있게 던져줌
    }
  }

  // 2. 랭킹 스트림 (디버깅 로그 및 에러 핸들링 추가)
  Stream<List<Map<String, dynamic>>> get rankingStream {
    return _db
        .collection('users')
        .orderBy('score', descending: true)
        .orderBy('createdAt', descending: false)
        .limit(25)
        .snapshots()
        .map((snapshot) {
          debugPrint("📊 랭킹 데이터 수신: ${snapshot.docs.length}명");
          return snapshot.docs.map((doc) => doc.data()).toList();
        })
        .handleError((error) {
          // 💡 여기서 에러가 나면 100% 인덱스 오타 혹은 미설정 문제입니다.
          debugPrint("❌ 랭킹 스트림 에러: $error");
          return <Map<String, dynamic>>[];
        });
  }

  // 3. 퀴즈 결과 누적 업데이트 (Batch 사용)
  Future<void> updateQuizResults(
    Map<String, Map<String, int>> sessionStats,
    int newExp,
  ) async {
    if (uid == null) return;

    WriteBatch batch = _db.batch();
    DocumentReference userRef = _db.collection('users').doc(uid);

    // 경험치 업데이트
    batch.update(userRef, {'score': newExp});

    // 카테고리별 통계 증가
    sessionStats.forEach((category, stats) {
      batch.update(userRef, {
        'categories.$category.total': FieldValue.increment(stats['total']!),
        'categories.$category.correct': FieldValue.increment(stats['correct']!),
      });
    });

    await batch.commit();
    debugPrint("✅ 퀴즈 결과 Batch 업데이트 완료");
  }

  // 4. 실시간 유저 데이터 스트림
  Stream<DocumentSnapshot> get userDataStream {
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid!).snapshots();
  }
}
