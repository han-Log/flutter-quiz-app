import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 💡 1. uid를 매번 현재 로그인된 유저 정보에서 가져오도록 Getter로 설정
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  // 1. 회원가입 시 유저 데이터 초기 생성
  Future<void> initializeUserData(String email, String nickname) async {
    if (uid == null) return;

    // 💡 먼저 해당 유저의 문서가 있는지 확인
    final userDoc = await _db.collection('users').doc(uid).get();

    // 문서가 존재하지 않을 때만(신규 가입) 초기 데이터를 생성
    if (!userDoc.exists) {
      final categories = ['사회', '인문', '예술', '역사', '경제', '과학', '일상'];
      Map<String, dynamic> initialStats = {
        for (var cat in categories) cat: {'total': 0, 'correct': 0},
      };

      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'nickname': nickname,
        'score': 0,
        'categories': initialStats,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 2. 퀴즈 결과 누적 업데이트 (Batch 사용)
  Future<void> updateQuizResults(
    Map<String, Map<String, int>> sessionStats,
    int newExp,
  ) async {
    if (uid == null) return;

    WriteBatch batch = _db.batch();
    DocumentReference userRef = _db.collection('users').doc(uid);

    batch.update(userRef, {'score': newExp});

    sessionStats.forEach((category, stats) {
      batch.update(userRef, {
        'categories.$category.total': FieldValue.increment(stats['total']!),
        'categories.$category.correct': FieldValue.increment(stats['correct']!),
      });
    });

    await batch.commit();
  }

  // 3. 실시간 유저 데이터 스트림
  Stream<DocumentSnapshot> get userDataStream {
    // uid가 null일 경우 빈 스트림을 반환하여 에러를 방지합니다.
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid!).snapshots();
  }
}
