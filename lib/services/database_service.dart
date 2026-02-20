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
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'nickname': nickname,
        'profileUrl': profileUrl,
        'score': FieldValue.increment(0),
        'categories': initialStats,
        'followerCount': 0, // 💡 초기 카운트 추가
        'followingCount': 0, // 💡 초기 카운트 추가
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("✅ Firestore 유저 데이터 생성/업데이트 성공: $uid");
    } catch (e) {
      debugPrint("❌ Firestore 데이터 저장 에러: $e");
      rethrow;
    }
  }

  // 2. 전체 랭킹 스트림 (기존 유지)
  Stream<List<Map<String, dynamic>>> get rankingStream {
    return _db
        .collection('users')
        .orderBy('score', descending: true)
        .orderBy('createdAt', descending: false)
        .limit(25)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  // 3. 유저 검색 (닉네임 기준 - 기존 유지)
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
      debugPrint("❌ 유저 검색 에러: $e");
      return [];
    }
  }

  // 4. 팔로우/언팔로우 (서브 컬렉션 & 카운트 동시 업데이트)
  // 💡 Batch를 사용하여 내 정보와 상대방 정보를 동시에 안전하게 바꿉니다.
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

      // 💡 팔로우/언팔로우 작업이 끝난 직후 동기화 호출!
      await syncFollowCounts();
    } catch (e) {
      debugPrint("❌ 토글 에러: $e");
    }
  }

  // 5. 실시간 팔로우 여부 확인 (기존 유지)
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

  // 6. 친구 전용 랭킹 스트림 (기존 유지)
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

          // whereIn은 최대 10개까지 지원하므로 주의 (친구가 10명 넘어가면 다른 방식 필요)
          final rankingSnap = await _db
              .collection('users')
              .where('uid', whereIn: followingIds)
              .orderBy('score', descending: true)
              .get();

          return rankingSnap.docs.map((doc) => doc.data()).toList();
        });
  }

  // 7. 퀴즈 결과 누적 업데이트 (기존 유지)
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

  // 8. 실시간 유저 데이터 스트림
  Stream<DocumentSnapshot> get userDataStream {
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid!).snapshots();
  }

  // 동기화 함수 보완
  Future<void> syncFollowCounts() async {
    if (uid == null) return;

    try {
      // 1. 내 팔로잉 서브 컬렉션 문서 개수 확인
      QuerySnapshot followingSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('following')
          .get();

      // 2. 내 팔로워 서브 컬렉션 문서 개수 확인
      QuerySnapshot followerSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('followers')
          .get();

      // 3. 음수 방지 및 정확한 개수 계산
      int actualFollowing = followingSnap.docs.length;
      int actualFollowers = followerSnap.docs.length;

      // 4. 내 문서 업데이트
      await _db.collection('users').doc(uid).update({
        'followingCount': actualFollowing < 0 ? 0 : actualFollowing,
        'followerCount': actualFollowers < 0 ? 0 : actualFollowers,
      });

      debugPrint("🔄 동기화 완료: 팔로잉 $actualFollowing, 팔로워 $actualFollowers");
    } catch (e) {
      debugPrint("❌ 동기화 실패: $e");
    }
  }
}
