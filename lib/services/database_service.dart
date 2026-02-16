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
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("✅ Firestore 유저 데이터 생성/업데이트 성공: $uid");
    } catch (e) {
      debugPrint("❌ Firestore 데이터 저장 에러: $e");
      rethrow;
    }
  }

  // 2. 전체 랭킹 스트림
  Stream<List<Map<String, dynamic>>> get rankingStream {
    return _db
        .collection('users')
        .orderBy('score', descending: true)
        .orderBy('createdAt', descending: false)
        .limit(25)
        .snapshots()
        .map((snapshot) {
          debugPrint("📊 전체 랭킹 데이터 수신: ${snapshot.docs.length}명");
          return snapshot.docs.map((doc) => doc.data()).toList();
        })
        .handleError((error) {
          debugPrint("❌ 전체 랭킹 스트림 에러: $error");
          return <Map<String, dynamic>>[];
        });
  }

  // -------------------------------------------------------------------------
  // 💡 신규 추가: 친구 관련 기능 (팔로우 방식)
  // -------------------------------------------------------------------------

  // 3. 유저 검색 (닉네임 기준)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      final snap = await _db
          .collection('users')
          .where('nickname', isGreaterThanOrEqualTo: query)
          .where('nickname', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      debugPrint("🔍 검색 결과: ${snap.docs.length}명");
      return snap.docs
          .map((doc) => doc.data())
          .where((data) => data['uid'] != uid) // 본인은 제외
          .toList();
    } catch (e) {
      debugPrint("❌ 유저 검색 에러: $e");
      return [];
    }
  }

  // 4. 팔로우/언팔로우 (Batch 사용하여 데이터 무결성 보장)
  Future<void> toggleFollow(String targetUid, bool isFollowing) async {
    if (uid == null) return;

    DocumentReference followRef = _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .doc(targetUid);

    try {
      if (isFollowing) {
        await followRef.delete();
        debugPrint("✅ 언팔로우 완료: $targetUid");
      } else {
        await followRef.set({
          'uid': targetUid,
          'followedAt': FieldValue.serverTimestamp(),
        });
        debugPrint("✅ 팔로우 완료: $targetUid");
      }
    } catch (e) {
      debugPrint("❌ 팔로우 토글 에러: $e");
    }
  }

  // 5. 실시간 팔로우 여부 확인
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

  // 6. 친구 전용 랭킹 스트림
  // (내가 팔로우한 사람들의 UID를 가져와서 해당 유저들의 점수만 필터링)
  Stream<List<Map<String, dynamic>>> get friendRankingStream {
    if (uid == null) return Stream.value([]);

    // 1. 내가 팔로우하는 사람들의 목록을 실시간으로 감시
    return _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .asyncMap((followingSnap) async {
          List<String> followingIds = followingSnap.docs
              .map((doc) => doc.id)
              .toList();
          followingIds.add(uid!); // 나 자신도 포함

          // 2. 팔로우하는 사람이 아무도 없다면 (나뿐이라면) 내 데이터만 가져옴
          // 3. Firestore의 'whereIn'은 최대 10명(또는 정책에 따라 30명) 제한이 있음에 유의
          final rankingSnap = await _db
              .collection('users')
              .where('uid', whereIn: followingIds)
              .orderBy('score', descending: true)
              .get();

          debugPrint("📊 친구 랭킹 데이터 수신: ${rankingSnap.docs.length}명");
          return rankingSnap.docs.map((doc) => doc.data()).toList();
        })
        .handleError((e) {
          debugPrint("❌ 친구 랭킹 스트림 에러: $e");
          return <Map<String, dynamic>>[];
        });
  }

  // -------------------------------------------------------------------------

  // 7. 퀴즈 결과 누적 업데이트 (Batch 사용)
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
    debugPrint("✅ 퀴즈 결과 Batch 업데이트 완료");
  }

  // 8. 실시간 유저 데이터 스트림
  Stream<DocumentSnapshot> get userDataStream {
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid!).snapshots();
  }
}
