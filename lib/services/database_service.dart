import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;
  final int _rankLimit = 9;

  // 💡 [1] 유저 데이터 초기화 (신규 유저일 때만 생성 - 롤백 방지 핵심)
  Future<void> initializeUserData(
    String email,
    String nickname, {
    String? profileUrl,
  }) async {
    if (uid == null) return;

    try {
      final userDoc = _db.collection('users').doc(uid!);
      final snap = await userDoc.get();

      // 기존 데이터가 있다면 덮어쓰지 않고 종료 (점수 보존)
      if (snap.exists) {
        debugPrint("✅ 기존 유저 확인: 데이터를 보존합니다.");
        return;
      }

      final categories = ['사회', '인문', '예술', '역사', '경제', '과학', '일상'];
      Map<String, dynamic> initialStats = {
        for (var cat in categories) cat: {'total': 0, 'correct': 0},
      };

      await userDoc.set({
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
      });
      debugPrint("🆕 신규 유저 초기 세팅 완료");
    } catch (e) {
      debugPrint("❌ 유저 초기화 에러: $e");
    }
  }

  // [2] 출석 스트릭 관리 (매일 첫 접속 시 호출)
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

  // 💡 [3] 퀴즈 결과 누적 (진정한 연속 정답 로직 적용)
  Future<void> updateQuizResults({
    required Map<String, Map<String, int>> sessionStats,
    required int newExp,
    required int totalSolved,
    required int totalCorrect,
    required int sessionStreak, // 세션 마지막의 연속 정답 수
    required bool failedThisSession, // 세션 중 한 번이라도 틀렸는지 여부
  }) async {
    if (uid == null) return;
    WriteBatch batch = _db.batch();
    DocumentReference userRef = _db.collection('users').doc(uid!);

    // 경험치 및 카테고리 통계 업데이트
    batch.update(userRef, {'score': FieldValue.increment(newExp)});
    sessionStats.forEach((category, stats) {
      batch.update(userRef, {
        'categories.$category.total': FieldValue.increment(stats['total']!),
        'categories.$category.correct': FieldValue.increment(stats['correct']!),
      });
    });

    // 오늘 푼 문제 수 업데이트 (잔디용)
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    batch.update(userRef, {
      'attendance.$todayStr': FieldValue.increment(totalSolved),
    });

    // 연속 정답(스트릭) 처리
    if (failedThisSession) {
      batch.update(userRef, {'answerStreak': sessionStreak});
    } else {
      batch.update(userRef, {
        'answerStreak': FieldValue.increment(sessionStreak),
      });
    }

    await batch.commit();
    _syncMaxAnswerStreak();
  }

  // [4] 최고 연속 정답 기록 동기화
  Future<void> _syncMaxAnswerStreak() async {
    if (uid == null) return;
    final userRef = _db.collection('users').doc(uid!);
    final snap = await userRef.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    int current = data['answerStreak'] ?? 0;
    int max = data['maxAnswerStreak'] ?? 0;

    if (current > max) {
      await userRef.update({'maxAnswerStreak': current});
    }
  }

  // [5] 전체 랭킹 데이터 (Future 버전 - 랭킹 화면용)
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
      debugPrint("❌ 랭킹 로딩 에러: $e");
      return [];
    }
  }

  // [6] 유저 검색 기능
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

  // [7] 팔로우/언팔로우 (원자적 업데이트)
  Future<void> toggleFollow(
    String myUid,
    String targetUid,
    bool currentlyFollowing,
  ) async {
    final batch = _db.batch();
    final myRef = _db.collection('users').doc(myUid);
    final targetRef = _db.collection('users').doc(targetUid);
    final myFollowing = myRef.collection('following').doc(targetUid);
    final targetFollower = targetRef.collection('followers').doc(myUid);

    if (currentlyFollowing) {
      batch.delete(myFollowing);
      batch.delete(targetFollower);
      batch.update(myRef, {'followingCount': FieldValue.increment(-1)});
      batch.update(targetRef, {'followerCount': FieldValue.increment(-1)});
    } else {
      batch.set(myFollowing, {
        'followedAt': FieldValue.serverTimestamp(),
        'uid': targetUid,
      });
      batch.set(targetFollower, {
        'followedAt': FieldValue.serverTimestamp(),
        'uid': myUid,
      });
      batch.update(myRef, {'followingCount': FieldValue.increment(1)});
      batch.update(targetRef, {'followerCount': FieldValue.increment(1)});
    }
    await batch.commit();
  }

  // [8] 팔로우 여부 실시간 확인
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

  // [9] 친구 랭킹 (내가 팔로우한 사람들 + 나)
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
        if (doc.exists && doc.data() != null) {
          rankers.add(doc.data() as Map<String, dynamic>);
        }
      }
      rankers.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
      return rankers;
    } catch (e) {
      return [];
    }
  }

  // [10] 내 정보 실시간 스트림 (홈 화면/프로필용)
  Stream<DocumentSnapshot> get userDataStream {
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid!).snapshots();
  }

  // [11] 특정 유저 데이터 가져오기 (비동기)
  Future<DocumentSnapshot> getUserData(String targetUid) async {
    return await _db.collection('users').doc(targetUid).get();
  }

  // [12] 내 순위 계산 (전체 유저 대상)
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

  // [13] 팔로우 카운트 강제 동기화 (복구용)
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

  // [14] 프로필 수정 (닉네임, 사진)
  Future<void> updateUserProfile({
    required String uid,
    String? nickname,
    String? profileUrl,
  }) async {
    final Map<String, dynamic> updates = {};
    if (nickname != null) updates['nickname'] = nickname;
    if (profileUrl != null) updates['profileUrl'] = profileUrl;

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
  }
}
