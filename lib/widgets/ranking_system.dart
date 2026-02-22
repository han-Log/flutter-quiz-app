import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import 'profile_detail_sheet.dart';

class RankingSystem extends StatefulWidget {
  final String? myUid;
  const RankingSystem({super.key, required this.myUid});

  @override
  State<RankingSystem> createState() => _RankingSystemState();
}

class _RankingSystemState extends State<RankingSystem> {
  final DatabaseService _dbService = DatabaseService();
  final ScrollController _allScrollController = ScrollController();
  final ScrollController _friendScrollController = ScrollController();

  int _myRank = 0;
  Map<String, dynamic>? _myData;
  bool _isInitialLoaded = false;
  bool _hasAutoScrolled = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _allScrollController.dispose();
    _friendScrollController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    if (widget.myUid == null) return;
    try {
      final results = await Future.wait([
        _dbService.getMyRank(),
        _dbService.userDataStream.first,
      ]);
      if (mounted) {
        setState(() {
          _myRank = results[0] as int;
          final doc = results[1] as DocumentSnapshot;
          _myData = doc.data() as Map<String, dynamic>?;
          if (_myData != null) _myData!['uid'] = widget.myUid;
          _isInitialLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("❌ 데이터 로드 실패: $e");
    }
  }

  // 자동 스크롤 로직 (전체 랭킹용)
  void _autoScrollToMe(bool isMeInList, int? myIndex) {
    if (_hasAutoScrolled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_allScrollController.hasClients) {
        double targetOffset;
        if (isMeInList && myIndex != null) {
          targetOffset =
              ((myIndex - 3) * 74.0) -
              (MediaQuery.of(context).size.height / 3.5);
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
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialLoaded)
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
      );

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // 탭바 디자인
          TabBar(
            indicatorColor: const Color(0xFF7B61FF),
            labelColor: const Color(0xFF7B61FF),
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "전체 랭킹"),
              Tab(text: "친구 랭킹"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildRankingList(
                  _dbService.rankingStream,
                  _allScrollController,
                  isGlobal: true,
                ),
                _buildRankingList(
                  _dbService.friendRankingStream,
                  _friendScrollController,
                  isGlobal: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 랭킹 리스트 빌더 (전체/친구 공용)
  Widget _buildRankingList(
    Stream<List<Map<String, dynamic>>> stream,
    ScrollController controller, {
    required bool isGlobal,
  }) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
          );
        }
        final allRankers = snapshot.data ?? [];
        if (allRankers.isEmpty) return const Center(child: Text("데이터가 없습니다."));

        final podiumRankers = allRankers.take(3).toList();
        final listRankers = allRankers.skip(3).toList();

        int myTotalIndex = allRankers.indexWhere(
          (u) => u['uid'] == widget.myUid,
        );
        bool isMeInTop3 = myTotalIndex >= 0 && myTotalIndex < 3;
        bool isMeInList = myTotalIndex >= 3;
        bool showSpecialBottomCard = isGlobal && (myTotalIndex == -1);

        if (isGlobal && !isMeInTop3) _autoScrollToMe(isMeInList, myTotalIndex);

        return Column(
          children: [
            _buildPodium(podiumRankers),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                itemCount: listRankers.length + (showSpecialBottomCard ? 2 : 0),
                itemBuilder: (context, index) {
                  if (index < listRankers.length) {
                    final user = listRankers[index];
                    bool isActuallyMe = user['uid'] == widget.myUid;
                    // 친구 랭킹에서는 전체 순위가 아닌 리스트 순서대로 표시
                    int displayRank = isGlobal ? (index + 4) : (index + 4);
                    return _buildListItem(
                      user,
                      displayRank,
                      isMe: isActuallyMe,
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

                  if (index == listRankers.length + 1 &&
                      showSpecialBottomCard &&
                      _myData != null) {
                    int displayRank = _myRank;
                    if (displayRank <= allRankers.length)
                      displayRank = allRankers.length + 1;
                    return _buildListItem(
                      _myData!,
                      displayRank,
                      isMe: true,
                      isSpecial: true,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- UI 컴포넌트 (디자인 유지) ---
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
              onTap: () => _showProfileSheet(user),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: rank == 1 ? 40 : 32,
                    backgroundColor: isMe
                        ? const Color(0xFF7B61FF)
                        : Colors.grey[200],
                    child: CircleAvatar(
                      radius: rank == 1 ? 37 : 29,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          (user['profileUrl'] != null &&
                              user['profileUrl'] != "")
                          ? NetworkImage(user['profileUrl'])
                          : null,
                      child:
                          (user['profileUrl'] == null ||
                              user['profileUrl'] == "")
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
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
      onTap: () => _showProfileSheet(user),
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
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
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
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey[100],
              backgroundImage:
                  (user['profileUrl'] != null && user['profileUrl'] != "")
                  ? NetworkImage(user['profileUrl'])
                  : null,
              child: (user['profileUrl'] == null || user['profileUrl'] == "")
                  ? const Icon(Icons.person, color: Colors.grey, size: 20)
                  : null,
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

  void _showProfileSheet(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileDetailSheet(userData: user),
    );
  }
}
