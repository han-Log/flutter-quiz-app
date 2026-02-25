import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ranking_controller.dart';
import '../widgets/profile_detail_sheet.dart';
import '../services/level_service.dart';

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
    controller.fetchRankData();
    once(controller.allRankers, (List<Map<String, dynamic>> data) {
      if (data.isNotEmpty && mounted) _prepareScroll();
    });
  }

  @override
  void dispose() {
    _allScrollController.dispose();
    _friendScrollController.dispose();
    super.dispose();
  }

  void _prepareScroll() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) _executeScroll();
  }

  void _executeScroll() {
    if (!mounted || _hasAutoScrolled || !_allScrollController.hasClients)
      return;
    final allRankers = controller.allRankers;
    int myIndex = allRankers.indexWhere((u) => u['uid'] == widget.myUid);
    double targetOffset = 0;
    if (myIndex != -1) {
      if (myIndex < 3) {
        _hasAutoScrolled = true;
        return;
      }
      targetOffset =
          ((myIndex - 3) * 74.0) - (MediaQuery.of(context).size.height * 0.2);
    } else {
      targetOffset = _allScrollController.position.maxScrollExtent;
    }
    _allScrollController.animateTo(
      targetOffset < 0 ? 0 : targetOffset,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutCubic,
    );
    _hasAutoScrolled = true;
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
    bool showSpecialBottomCard =
        isGlobal && (myTotalIndex == -1 || myTotalIndex >= 10);

    String topRankerBg = "sea.jpeg";
    if (podiumRankers.isNotEmpty) {
      int topScore = (podiumRankers[0]['score'] is num)
          ? (podiumRankers[0]['score'] as num).toInt()
          : 0;
      int topLevel = LevelService.getLevel(topScore);
      topRankerBg = LevelService.getLevelBackground(topLevel);
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/$topRankerBg"),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white,
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              _buildPodium(podiumRankers),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            key: PageStorageKey(isGlobal ? 'all' : 'friend'),
            padding: const EdgeInsets.fromLTRB(40, 20, 40, 80),
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

  // 🏆 수정된 시상대 위젯 (Transform.translate 적용)
  Widget _buildPodium(List<Map<String, dynamic>> top3) {
    final displayOrder = [
      if (top3.length > 1) top3[1] else null,
      if (top3.isNotEmpty) top3[0] else null,
      if (top3.length > 2) top3[2] else null,
    ];

    return Container(
      height: 230,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: displayOrder.asMap().entries.map((entry) {
          final user = entry.value;
          if (user == null) return const Expanded(child: SizedBox());

          int rank = entry.key == 0 ? 2 : (entry.key == 1 ? 1 : 3);
          bool isMe = user['uid'] == widget.myUid;

          double barHeight = rank == 1 ? 100 : (rank == 2 ? 70 : 50);
          double avatarRadius = rank == 1 ? 12 : 10;

          // 💡 1위는 캐릭터가 크니까 조금 더 많이(12) 내리고, 나머지는 살짝(8) 내립니다.
          double pushDownOffset = rank == 1 ? 12.0 : 8.0;

          return Expanded(
            child: GestureDetector(
              onTap: () => _showProfile(user),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 💡 1. Transform.translate를 써서 프로필과 닉네임을 아래로(Y축) 강제로 끌어내립니다!
                  Transform.translate(
                    offset: Offset(0, pushDownOffset),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Colors.transparent,
                          backgroundImage:
                              (user['profileUrl'] != null &&
                                  user['profileUrl'] != "")
                              ? NetworkImage(user['profileUrl'])
                                    as ImageProvider
                              : const AssetImage(
                                  'assets/images/default_profile.png',
                                ),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            user['nickname'] ?? "익명",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isMe
                                  ? FontWeight.bold
                                  : FontWeight.w800,
                              color: isMe
                                  ? const Color(0xFF7B61FF)
                                  : Colors.black87,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 0),
                                  blurRadius: 3.0,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 💡 2. 캐릭터 이미지 (위에서 끌어내린 닉네임과 거리가 확 좁혀짐)
                  Image.asset(
                    "assets/images/level_${LevelService.getLevel(user['score'] ?? 0)}.png",
                    width: rank == 1 ? 90 : 75,
                  ),

                  // 💡 3. 시상대 막대
                  Container(
                    width: 60,
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: rank == 1
                            ? [const Color(0xFF7B61FF), const Color(0xFF5A45D1)]
                            : [
                                const Color(0xFFF2F4FF),
                                const Color(0xFFE0E5FF),
                              ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "$rank위",
                        style: TextStyle(
                          color: rank == 1
                              ? Colors.white
                              : const Color(0xFF7B61FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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

  // 리스트 아이템
  Widget _buildListItem(
    Map<String, dynamic> user,
    int rank, {
    required bool isMe,
    bool isSpecial = false,
  }) {
    int userLevel = LevelService.getLevel(user['score'] ?? 0);
    const double listAvatarRadius = 12;

    return GestureDetector(
      onTap: () => _showProfile(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFF2F4FF) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: isMe
              ? Border.all(color: const Color(0xFF7B61FF), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                "$rank",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMe ? const Color(0xFF7B61FF) : Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Image.asset(
              "assets/images/level_$userLevel.png",
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: listAvatarRadius,
                        backgroundColor: Colors.transparent,
                        backgroundImage:
                            (user['profileUrl'] != null &&
                                user['profileUrl'] != "")
                            ? NetworkImage(user['profileUrl']) as ImageProvider
                            : const AssetImage(
                                'assets/images/default_profile.png',
                              ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          user['nickname'] ?? "익명",
                          style: TextStyle(
                            fontWeight: isMe
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  if (isSpecial)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        "나의 현재 순위",
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7B61FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
