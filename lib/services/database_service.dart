import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;
  final int _rankLimit = 9;

  // [1] 유저 데이터 초기화
  Future<void> initializeUserData(
    String email,
    String nickname, {
    String? profileUrl,
  }) async {
    if (uid == null) return;
    final categories = ['사회', '인문', '예술', '역사', '경제', '과학', '일상'];
    Map<String, dynamic> initialStats = {
      for (var cat in categories) cat: {'total': 0, 'correct': 0},
    };
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'nickname': nickname,
        'profileUrl': profileUrl ?? "",
        'score': 0,
        'categories': initialStats,
        'followerCount': 0,
        'followingCount': 0,
        'attendance': {},
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ 유저 초기화 에러: $e");
    }
  }

  // [2] rankingStream (비용 절감을 위해 Future로 내부 구현)
  // 💡 팁: 이 부분이 Future이기 때문에 프로필 수정 후 이 함수를 다시 호출해야 화면이 갱신됩니다.
  Future<List<Map<String, dynamic>>> get rankingStream async {
    try {
      final snapshot = await _db
          .collection('users')
          .orderBy('score', descending: true)
          .orderBy('createdAt', descending: false)
          .limit(_rankLimit)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("❌ 전체 랭킹 로딩 에러: $e");
      return [];
    }
  }

  // [3] 유저 검색
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      final snap = await _db
          .collection('users')
          .where('nickname', isGreaterThanOrEqualTo: query)
          .where('nickname', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      return snap.docs
          .map((doc) => doc.data())
          .where((data) => data['uid'] != uid)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // [4] 팔로우/언팔로우
  Future<void> toggleFollow(
    String myUid,
    String targetUid,
    bool currentlyFollowing,
  ) async {
    final batch = _db.batch();

    final myFollowingDoc = _db
        .collection('users')
        .doc(myUid)
        .collection('following')
        .doc(targetUid);

    final targetFollowerDoc = _db
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(myUid);

    if (currentlyFollowing) {
      batch.delete(myFollowingDoc);
      batch.delete(targetFollowerDoc);
      batch.update(_db.collection('users').doc(myUid), {
        'followingCount': FieldValue.increment(-1),
      });
      batch.update(_db.collection('users').doc(targetUid), {
        'followerCount': FieldValue.increment(-1),
      });
    } else {
      batch.set(myFollowingDoc, {
        'followedAt': FieldValue.serverTimestamp(),
        'uid': targetUid,
      });
      batch.set(targetFollowerDoc, {
        'followedAt': FieldValue.serverTimestamp(),
        'uid': myUid,
      });
      batch.update(_db.collection('users').doc(myUid), {
        'followingCount': FieldValue.increment(1),
      });
      batch.update(_db.collection('users').doc(targetUid), {
        'followerCount': FieldValue.increment(1),
      });
    }
    await batch.commit();
  }

  // [5] 팔로우 여부 확인
  Stream<bool> isFollowingStream(String targetUid) {
    if (uid == null) return Stream.value(false);
    return _db
        .collection('users')
        .doc(uid!)
        .collection('following')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // [6] friendRankingStream
  Future<List<Map<String, dynamic>>> get friendRankingStream async {
    if (uid == null) return [];
    try {
      final followingSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('following')
          .get();
      List<String> followingIds = followingSnap.docs
          .map((doc) => doc.id)
          .toList();
      followingIds.add(uid!);

      final rankingSnap = await _db
          .collection('users')
          .where('uid', whereIn: followingIds.take(10).toList())
          .orderBy('score', descending: true)
          .get();
      return rankingSnap.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("❌ 친구 랭킹 로딩 에러: $e");
      return [];
    }
  }

  // [7] 퀴즈 결과 누적
  Future<void> updateQuizResults(
    Map<String, Map<String, int>> sessionStats,
    int newExp,
    int totalCorrect,
  ) async {
    if (uid == null) return;
    WriteBatch batch = _db.batch();
    DocumentReference userRef = _db.collection('users').doc(uid);
    batch.update(userRef, {'score': FieldValue.increment(newExp)});
    sessionStats.forEach((category, stats) {
      batch.update(userRef, {
        'categories.$category.total': FieldValue.increment(stats['total']!),
        'categories.$category.correct': FieldValue.increment(stats['correct']!),
      });
    });
    String today = DateTime.now().toString().split(' ')[0];
    batch.update(userRef, {
      'attendance.$today': FieldValue.increment(totalCorrect),
    });
    await batch.commit();
  }

  // [8] 실시간 유저 데이터 스트림
  Stream<DocumentSnapshot> get userDataStream {
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid!).snapshots();
  }

  // [9] 팔로워 숫자 동기화
  Future<void> syncFollowCounts() async {
    if (uid == null) return;
    try {
      final followingSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('following')
          .get();
      final followerSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('followers')
          .get();
      await _db.collection('users').doc(uid).update({
        'followingCount': followingSnap.docs.length,
        'followerCount': followerSnap.docs.length,
      });
    } catch (e) {}
  }

  // [10] 내 순위 계산
  Future<int> getMyRank() async {
    if (uid == null) return 0;
    try {
      final myDoc = await _db.collection('users').doc(uid).get();
      if (!myDoc.exists) return 0;
      final data = myDoc.data()!;
      final int myScore = data['score'] ?? 0;
      final Timestamp myCreatedAt =
          data['createdAt'] as Timestamp? ?? Timestamp.now();

      final higherScoreQuery = await _db
          .collection('users')
          .where('score', isGreaterThan: myScore)
          .count()
          .get();
      int rankCount = higherScoreQuery.count ?? 0;

      final sameScoreQuery = await _db
          .collection('users')
          .where('score', isEqualTo: myScore)
          .where('createdAt', isLessThan: myCreatedAt)
          .count()
          .get();
      rankCount += (sameScoreQuery.count ?? 0);
      return rankCount + 1;
    } catch (e) {
      debugPrint("❌ 순위 계산 에러: $e");
      return 0;
    }
  }

  Future<DocumentSnapshot> getUserData(String targetUid) async {
    return await _db.collection('users').doc(targetUid).get();
  }

  // 💡 수정된 부분: 유저 프로필 업데이트
  Future<void> updateUserProfile({
    required String uid,
    String? nickname,
    String? profileUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (nickname != null) updates['nickname'] = nickname;
      if (profileUrl != null) updates['profileUrl'] = profileUrl;

      if (updates.isNotEmpty) {
        // 1. users 컬렉션 업데이트 (랭킹 데이터의 원천)
        await _db.collection('users').doc(uid).update(updates);
        debugPrint("✅ Users 컬렉션 업데이트 완료: $updates");

        // 💡 만약 다른 컬렉션(예: 랭킹 전용)을 따로 쓰지 않는다면
        // 화면에서 이 Future가 끝난 후 setState()나 GetX 컨트롤러를 새로고침해야 합니다.
      }
    } catch (e) {
      debugPrint("❌ 프로필 업데이트 실패: $e");
      rethrow;
    }
  }
}
