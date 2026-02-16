import 'package:flutter/material.dart';
import '../services/database_service.dart';

class RankingSystem extends StatefulWidget {
  final String? myUid;
  const RankingSystem({super.key, required this.myUid});

  @override
  State<RankingSystem> createState() => _RankingSystemState();
}

class _RankingSystemState extends State<RankingSystem> {
  final DatabaseService _dbService = DatabaseService();
  int _selectedRankingTab = 0; // 0: 전체, 1: 친구

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRankingHeader(),
        // 1. 기존 SizedBox(height: 12)를 4 정도로 줄이거나 제거하세요.
        const SizedBox(height: 4),
        _buildRankingList(),
      ],
    );
  }

  Widget _buildRankingHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "실시간 랭킹",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D1B69),
          ),
        ),
        Container(
          height: 32,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _buildRankingTabItem(0, "전체"),
              _buildRankingTabItem(1, "친구"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankingTabItem(int index, String label) {
    bool isSelected = _selectedRankingTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedRankingTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF7B61FF) : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildRankingList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _selectedRankingTab == 0
          ? _dbService.rankingStream
          : _dbService.friendRankingStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final rankers = snapshot.data ?? [];

        if (rankers.isEmpty) {
          return Container(
            height: 100,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _selectedRankingTab == 0 ? "랭킹 데이터가 없습니다." : "팔로우하는 친구가 없습니다.",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // 2. 중요: ListView의 기본 상하단 패딩을 0으로 설정합니다.
            padding: EdgeInsets.zero,
            itemCount: rankers.length > 10 ? 10 : rankers.length,
            itemBuilder: (context, index) {
              final user = rankers[index];
              final int rank = index + 1;
              bool isMe = user['uid'] == widget.myUid;

              return Container(
                // 3. ListTile의 여백을 줄이기 위해 Padding을 직접 조절합니다.
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xFF7B61FF).withOpacity(0.05)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  // 4. ListTile 대신 Row를 사용하여 여백을 완전히 통제합니다.
                  children: [
                    _getRankIcon(rank),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: user['profileUrl'] != null
                          ? NetworkImage(user['profileUrl'])
                          : const AssetImage(
                                  'assets/images/default_profile.png',
                                )
                                as ImageProvider,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user['nickname'] ?? "익명",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isMe
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      "${user['score']} EXP",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475467),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _getRankIcon(int rank) {
    if (rank == 1)
      return const Icon(Icons.emoji_events, color: Colors.amber, size: 20);
    if (rank == 2)
      return const Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 20);
    if (rank == 3)
      return const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 20);
    return SizedBox(
      width: 20,
      child: Center(
        child: Text(
          "$rank",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
