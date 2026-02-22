import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';

class RankingController extends GetxController {
  final DatabaseService _dbService = DatabaseService();

  // Observable 변수들
  var allRankers = <Map<String, dynamic>>[].obs;
  var friendRankers = <Map<String, dynamic>>[].obs;
  var isInitialLoaded = false.obs;
  var myRank = 0.obs;

  // 💡 Rxn<Map<String, dynamic>>은 null을 허용하는 반응형 객체입니다.
  var myData = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    fetchRankData();
  }

  Future<void> fetchRankData() async {
    try {
      isInitialLoaded.value = false;

      // 1. 랭킹 데이터 및 내 순위 가져오기
      final all = await _dbService.rankingStream;
      final friends = await _dbService.friendRankingStream;
      final rank = await _dbService.getMyRank();

      allRankers.assignAll(all);
      friendRankers.assignAll(friends);
      myRank.value = rank;

      // 2. 💡 내 데이터 확보 로직 (타입 안전성 강화)
      if (_dbService.uid != null) {
        final myIndex = allRankers.indexWhere(
          (u) => u['uid'] == _dbService.uid,
        );

        if (myIndex != -1) {
          // 💡 리스트에서 가져올 때도 명시적으로 Map 타입임을 확인
          myData.value = Map<String, dynamic>.from(allRankers[myIndex]);
          debugPrint("✅ 내 데이터가 상위 랭킹에 포함되어 있습니다.");
        } else {
          debugPrint("⚠️ 내가 상위 랭킹 밖입니다. 개별 데이터를 호출합니다.");
          final myDoc = await _dbService.getUserData(_dbService.uid!);

          if (myDoc.exists && myDoc.data() != null) {
            // 💡 [해결 포인트] Object? 타입을 Map<String, dynamic>으로 강제 형변환
            // 이 처리가 없으면 Rxn<Map> 타입에 Object가 들어오려 한다며 에러가 날 수 있습니다.
            myData.value = myDoc.data() as Map<String, dynamic>;
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint("❌ 데이터 로드 중 오류: $e");
      debugPrint("❌ 스택 트레이스: $stackTrace");
    } finally {
      isInitialLoaded.value = true;
    }
  }
}
