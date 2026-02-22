import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ranking_controller.dart';
import '../widgets/profile_detail_sheet.dart';

class RankingScreen extends StatefulWidget {
  final String? myUid;
  const RankingScreen({super.key, required this.myUid});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final RankingController controller = Get.put(RankingController());
  final ScrollController _allScrollController = ScrollController();
  final ScrollController _friendScrollController = ScrollController();
  bool _hasAutoScrolled = false;

  @override
  void initState() {
    super.initState();
    debugPrint("🚩 [1. initState] 시작");
    controller.fetchRankData();

    // 데이터가 채워지면 스크롤 준비
    once(controller.allRankers, (List<Map<String, dynamic>> data) {
      if (data.isNotEmpty && mounted) {
        debugPrint("🚩 [2. Worker] 데이터 수신 (${data.length}명)");
        _prepareScroll();
      }
    });
  }

  @override
  void dispose() {
    _allScrollController.dispose();
    _friendScrollController.dispose();
    super.dispose();
  }

  void _prepareScroll() async {
    await Future.delayed(const Duration(milliseconds: 600)); // 리스트 빌드 대기
    if (mounted) _executeScroll();
  }

  void _executeScroll() {
    if (!mounted || _hasAutoScrolled || !_allScrollController.hasClients)
      return;

    final allRankers = controller.allRankers;
    int myIndex = allRankers.indexWhere((u) => u['uid'] == widget.myUid);

    debugPrint("🚩 [3. 실행] 내 인덱스: $myIndex");

    double targetOffset = 0;

    if (myIndex != -1) {
      // 💡 케이스 1: 상위 랭킹(리스트 내부)에 내가 있을 때
      if (myIndex < 3) {
        _hasAutoScrolled = true; // 포디움은 스크롤 안함
        return;
      }
      targetOffset =
          ((myIndex - 3) * 74.0) - (MediaQuery.of(context).size.height * 0.2);
    } else {
      // 💡 케이스 2: [핵심 수정] 내가 상위 랭킹에 없을 때 -> 리스트 맨 아래로!
      debugPrint("🚩 [4. 이동] 상위권에 없음. 리스트 맨 아래로 이동합니다.");
      targetOffset = _allScrollController.position.maxScrollExtent;
    }

    try {
      _allScrollController.animateTo(
        targetOffset < 0 ? 0 : targetOffset,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
      );
      _hasAutoScrolled = true;
      debugPrint("✅ [완료] 스크롤 성공 (Offset: $targetOffset)");
    } catch (e) {
      debugPrint("❌ [에러] 스크롤 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "LEADER BOARD",
          style: TextStyle(
            color: Color(0xFF2D1B69),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() {
        if (!controller.isInitialLoaded.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                indicatorColor: Color(0xFF7B61FF),
                labelColor: Color(0xFF7B61FF),
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: "전체 랭킹"),
                  Tab(text: "친구 랭킹"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildRankingList(
                      controller.allRankers,
                      _allScrollController,
                      isGlobal: true,
                    ),
                    _buildRankingList(
                      controller.friendRankers,
                      _friendScrollController,
                      isGlobal: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRankingList(
    List<Map<String, dynamic>> rankers,
    ScrollController scrollController, {
    required bool isGlobal,
  }) {
    if (rankers.isEmpty) return const Center(child: Text("데이터가 없습니다."));

    final podiumRankers = rankers.take(3).toList();
    final listRankers = rankers.skip(3).toList();
    int myTotalIndex = rankers.indexWhere((u) => u['uid'] == widget.myUid);

    // 내가 리스트에 없을 때만 하단 "내 순위" 카드 표시
    bool showSpecialBottomCard = isGlobal && (myTotalIndex == -1);

    return Column(
      children: [
        _buildPodium(podiumRankers),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            key: PageStorageKey(isGlobal ? 'all' : 'friend'),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
            itemCount: listRankers.length + (showSpecialBottomCard ? 2 : 0),
            itemBuilder: (context, index) {
              if (index < listRankers.length) {
                final user = listRankers[index];
                return _buildListItem(
                  user,
                  index + 4,
                  isMe: user['uid'] == widget.myUid,
                );
              }
              if (index == listRankers.length && showSpecialBottomCard) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "...",
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.grey,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }
              if (index == listRankers.length + 1 && showSpecialBottomCard) {
                return Obx(() {
                  final myData = controller.myData.value;
                  if (myData == null) return const SizedBox.shrink();
                  return _buildListItem(
                    myData,
                    controller.myRank.value,
                    isMe: true,
                    isSpecial: true,
                  );
                });
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> top3) {
    final displayOrder = [
      if (top3.length > 1) top3[1] else null,
      if (top3.isNotEmpty) top3[0] else null,
      if (top3.length > 2) top3[2] else null,
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: displayOrder.asMap().entries.map((entry) {
          final user = entry.value;
          if (user == null) return const Expanded(child: SizedBox());
          int rank = entry.key == 0 ? 2 : (entry.key == 1 ? 1 : 3);
          bool isMe = user['uid'] == widget.myUid;
          return Expanded(
            child: GestureDetector(
              onTap: () => _showProfile(user),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: rank == 1 ? 40 : 32,
                    backgroundColor: isMe
                        ? const Color(0xFF7B61FF)
                        : Colors.grey[200],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user['nickname'] ?? "익명",
                    style: TextStyle(
                      fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                      color: isMe ? const Color(0xFF7B61FF) : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? const Color(0xFF7B61FF)
                          : const Color(0xFFF2F4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$rank위",
                      style: TextStyle(
                        color: rank == 1
                            ? Colors.white
                            : const Color(0xFF7B61FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListItem(
    Map<String, dynamic> user,
    int rank, {
    required bool isMe,
    bool isSpecial = false,
  }) {
    return GestureDetector(
      onTap: () => _showProfile(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFF2F4FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isMe
              ? Border.all(color: const Color(0xFF7B61FF), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                "$rank",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMe ? const Color(0xFF7B61FF) : Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            const CircleAvatar(
              radius: 22,
              child: Icon(Icons.person, color: Colors.grey, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['nickname'] ?? "익명",
                    style: TextStyle(
                      fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  if (isSpecial)
                    const Text(
                      "나의 현재 순위",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
            Text(
              "${user['score'] ?? 0} EXP",
              style: const TextStyle(
                color: Color(0xFF7B61FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfile(Map<String, dynamic> user) {
    Get.bottomSheet(
      ProfileDetailSheet(userData: user, myUid: widget.myUid ?? ""),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
