import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 💡 기존 필드 및 Getter 유지
  String? get uid => FirebaseAuth.instance.currentUser?.uid;
  final int _rankLimit = 9; // 랭킹 표시 제한

  // [기존 1] 유저 데이터 초기화
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
        'profileUrl': profileUrl,
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

  // [기존 2] 전체 랭킹 스트림 (정렬 기준 유지)
  Stream<List<Map<String, dynamic>>> get rankingStream {
    return _db
        .collection('users')
        .orderBy('score', descending: true)
        .orderBy('createdAt', descending: false)
        .limit(_rankLimit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // [기존 3] 유저 검색 (다른 화면에서 사용)
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

  // [기존 4] 팔로우/언팔로우 (다른 화면에서 사용)
  Future<void> toggleFollow(String targetUid, bool isFollowing) async {
    if (uid == null) return;
    WriteBatch batch = _db.batch();
    DocumentReference myFollowingRef = _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .doc(targetUid);
    DocumentReference targetFollowerRef = _db
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(uid);
    try {
      if (isFollowing) {
        batch.delete(myFollowingRef);
        batch.delete(targetFollowerRef);
      } else {
        batch.set(myFollowingRef, {
          'uid': targetUid,
          'followedAt': FieldValue.serverTimestamp(),
        });
        batch.set(targetFollowerRef, {
          'uid': uid,
          'followedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      await syncFollowCounts();
    } catch (e) {
      debugPrint("❌ 토글 에러: $e");
    }
  }

  // [기존 5] 팔로우 여부 확인
  Stream<bool> isFollowingStream(String targetUid) {
    if (uid == null) return Stream.value(false);
    return _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // [기존 6] 친구 전용 랭킹 스트림
  Stream<List<Map<String, dynamic>>> get friendRankingStream {
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .asyncMap((followingSnap) async {
          List<String> followingIds = followingSnap.docs
              .map((doc) => doc.id)
              .toList();
          followingIds.add(uid!);
          if (followingIds.isEmpty) return [];
          final rankingSnap = await _db
              .collection('users')
              .where('uid', whereIn: followingIds.take(30).toList())
              .orderBy('score', descending: true)
              .get();
          return rankingSnap.docs.map((doc) => doc.data()).toList();
        });
  }

  // [기존 7] 퀴즈 결과 누적
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

  // [기존 8] 실시간 유저 데이터 스트림
  Stream<DocumentSnapshot> get userDataStream {
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid!).snapshots();
  }

  // [기존 9] 팔로워 숫자 동기화
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

  // [기능 보강 10] 내 순위 계산 (동점자 처리 추가하여 3위 버그 해결)
  Future<int> getMyRank() async {
    if (uid == null) return 0;
    try {
      final myDoc = await _db.collection('users').doc(uid).get();
      if (!myDoc.exists) return 0;
      final data = myDoc.data()!;
      final int myScore = data['score'] ?? 0;
      final Timestamp? myCreatedAt = data['createdAt'] as Timestamp?;

      // 나보다 점수 높은 사람
      final higherScoreQuery = await _db
          .collection('users')
          .where('score', isGreaterThan: myScore)
          .count()
          .get();
      int rankCount = higherScoreQuery.count ?? 0;

      // 점수 같으면 먼저 가입한 사람
      if (myCreatedAt != null) {
        final sameScoreQuery = await _db
            .collection('users')
            .where('score', isEqualTo: myScore)
            .where('createdAt', isLessThan: myCreatedAt)
            .count()
            .get();
        rankCount += (sameScoreQuery.count ?? 0);
      }
      return rankCount + 1;
    } catch (e) {
      return 0;
    }
  }
}
