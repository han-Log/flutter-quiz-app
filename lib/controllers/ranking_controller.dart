import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';

class RankingController extends GetxController {
  final DatabaseService _dbService = DatabaseService();

  // Observable 변수들
  var allRankers = <Map<String, dynamic>>[].obs;
  var friendRankers = <Map<String, dynamic>>[].obs;
  var isInitialLoaded = false.obs;
  var myRank = 0.obs;
  var myData = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    fetchRankData();
  }

  Future<void> fetchRankData() async {
    try {
      // 1. 랭킹 데이터 및 내 순위 가져오기
      final all = await _dbService.rankingStream;
      final friends = await _dbService.friendRankingStream;
      final rank = await _dbService.getMyRank();

      allRankers.assignAll(all);
      friendRankers.assignAll(friends);
      myRank.value = rank;

      // 2. 내 상세 데이터 확보
      if (_dbService.uid != null) {
        final myIndex = allRankers.indexWhere(
          (u) => u['uid'] == _dbService.uid,
        );

        if (myIndex != -1) {
          myData.value = allRankers[myIndex];
        } else {
          final myDoc = await _dbService.getUserData(_dbService.uid!);
          if (myDoc.exists) {
            myData.value = myDoc.data() as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      debugPrint("❌ RankingController 데이터 로드 오류: $e");
    } finally {
      isInitialLoaded.value = true;
    }
  }
}
