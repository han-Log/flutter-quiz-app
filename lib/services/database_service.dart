import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

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
        'attendanceStreak': 0,
        'answerStreak': 0,
        'maxAnswerStreak': 0,
        'lastAttendanceDate': null,
        'attendance': {},
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ 유저 초기화 에러: $e");
    }
  }

  // [2] 출석 스트릭 관리
  Future<void> handleAttendance() async {
    if (uid == null) return;
    DocumentReference userRef = _db.collection('users').doc(uid!);
    try {
      final snap = await userRef.get();
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      Timestamp? lastAttendanceTimestamp = data['lastAttendanceDate'];

      if (lastAttendanceTimestamp == null) {
        await userRef.update({
          'attendanceStreak': 1,
          'lastAttendanceDate': Timestamp.fromDate(today),
        });
      } else {
        DateTime lastDate = lastAttendanceTimestamp.toDate();
        int dayDifference = today.difference(lastDate).inDays;
        if (dayDifference == 1) {
          await userRef.update({
            'attendanceStreak': FieldValue.increment(1),
            'lastAttendanceDate': Timestamp.fromDate(today),
          });
        } else if (dayDifference > 1) {
          await userRef.update({
            'attendanceStreak': 1,
            'lastAttendanceDate': Timestamp.fromDate(today),
          });
        }
      }
    } catch (e) {
      debugPrint("❌ 출석 체크 에러: $e");
    }
  }

  // [3] 퀴즈 결과 누적
  Future<void> updateQuizResults({
    required Map<String, Map<String, int>> sessionStats,
    required int newExp,
    required int totalSolved,
    required int totalCorrect,
    required bool isLastCorrect,
  }) async {
    if (uid == null) return;
    WriteBatch batch = _db.batch();
    DocumentReference userRef = _db.collection('users').doc(uid!);

    batch.update(userRef, {'score': FieldValue.increment(newExp)});
    sessionStats.forEach((category, stats) {
      batch.update(userRef, {
        'categories.$category.total': FieldValue.increment(stats['total']!),
        'categories.$category.correct': FieldValue.increment(stats['correct']!),
      });
    });

    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    batch.update(userRef, {
      'attendance.$todayStr': FieldValue.increment(totalSolved),
    });

    if (isLastCorrect) {
      batch.update(userRef, {'answerStreak': FieldValue.increment(1)});
    } else {
      batch.update(userRef, {'answerStreak': 0});
    }

    await batch.commit();
    _syncMaxAnswerStreak();
  }

  Future<void> _syncMaxAnswerStreak() async {
    if (uid == null) return;
    final userRef = _db.collection('users').doc(uid!);
    final snap = await userRef.get();
    final data = snap.data() as Map<String, dynamic>;
    int current = data['answerStreak'] ?? 0;
    int max = data['maxAnswerStreak'] ?? 0;
    if (current > max) await userRef.update({'maxAnswerStreak': current});
  }

  // [4] 전체 랭킹
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
      return [];
    }
  }

  // [5] 유저 검색
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

  // 💡 [6] 팔로우/언팔로우 (원자적 업데이트 최적화)
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
    final myRef = _db.collection('users').doc(myUid);
    final targetRef = _db.collection('users').doc(targetUid);

    if (currentlyFollowing) {
      // 언팔로우: 문서 삭제 및 카운트 감소
      batch.delete(myFollowingDoc);
      batch.delete(targetFollowerDoc);
      batch.update(myRef, {'followingCount': FieldValue.increment(-1)});
      batch.update(targetRef, {'followerCount': FieldValue.increment(-1)});
    } else {
      // 팔로우: 문서 생성 및 카운트 증가
      batch.set(myFollowingDoc, {
        'followedAt': FieldValue.serverTimestamp(),
        'uid': targetUid,
      });
      batch.set(targetFollowerDoc, {
        'followedAt': FieldValue.serverTimestamp(),
        'uid': myUid,
      });
      batch.update(myRef, {'followingCount': FieldValue.increment(1)});
      batch.update(targetRef, {'followerCount': FieldValue.increment(1)});
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint("❌ 팔로우 배치 처리 에러: $e");
      rethrow;
    }
  }

  // [7] 팔로우 여부 확인
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

  // [8] 친구 랭킹
  Future<List<Map<String, dynamic>>> get friendRankingStream async {
    if (uid == null) return [];
    try {
      final followingSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('following')
          .get();
      List<String> ids = followingSnap.docs.map((doc) => doc.id).toList();
      ids.add(uid!);
      List<Map<String, dynamic>> rankers = [];
      final docs = await Future.wait(
        ids.map((id) => _db.collection('users').doc(id).get()),
      );
      for (var doc in docs) {
        if (doc.exists && doc.data() != null)
          rankers.add(doc.data() as Map<String, dynamic>);
      }
      rankers.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
      return rankers;
    } catch (e) {
      return [];
    }
  }

  // [9] 실시간 유저 데이터 스트림
  Stream<DocumentSnapshot> get userDataStream {
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid!).snapshots();
  }

  // [10] 내 순위 계산
  Future<int> getMyRank() async {
    if (uid == null) return 0;
    try {
      final myDoc = await _db.collection('users').doc(uid).get();
      if (!myDoc.exists) return 0;
      final int myScore = myDoc.data()!['score'] ?? 0;
      final Timestamp myCreatedAt =
          myDoc.data()!['createdAt'] as Timestamp? ?? Timestamp.now();
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
      return 0;
    }
  }

  // 💡 [11] 팔로우/팔로잉 카운트 동기화 (설정 및 복구용)
  // 💡 count() 쿼리를 사용하여 문서를 읽지 않고 개수만 파악하므로 매우 경제적입니다.
  Future<void> syncFollowCounts() async {
    if (uid == null) return;
    try {
      final followingQuery = await _db
          .collection('users')
          .doc(uid)
          .collection('following')
          .count()
          .get();
      final followerQuery = await _db
          .collection('users')
          .doc(uid)
          .collection('followers')
          .count()
          .get();

      await _db.collection('users').doc(uid).update({
        'followingCount': followingQuery.count ?? 0,
        'followerCount': followerQuery.count ?? 0,
      });
      debugPrint("✅ 카운트 동기화 완료");
    } catch (e) {
      debugPrint("❌ 동기화 에러: $e");
    }
  }

  Future<DocumentSnapshot> getUserData(String targetUid) async {
    return await _db.collection('users').doc(targetUid).get();
  }

  // [12] 프로필 수정
  Future<void> updateUserProfile({
    required String uid,
    String? nickname,
    String? profileUrl,
  }) async {
    final Map<String, dynamic> updates = {};
    if (nickname != null) updates['nickname'] = nickname;
    if (profileUrl != null) updates['profileUrl'] = profileUrl;
    if (updates.isNotEmpty)
      await _db.collection('users').doc(uid).update(updates);
  }
}
