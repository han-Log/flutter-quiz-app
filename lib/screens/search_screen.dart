import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/profile_detail_sheet.dart'; // 💡 상세 프로필 위젯 임포트

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // 💡 프로필 상세 바텀 시트를 여는 함수
  void _openProfileDetail(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileDetailSheet(userData: user),
    );
  }

  // 검색 로직
  void _onSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    final results = await _dbService.searchUsers(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "친구 찾기",
          style: TextStyle(
            color: Color(0xFF101828),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF101828),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 🔍 검색창 영역
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _onSearch(),
                decoration: InputDecoration(
                  hintText: "찾고 싶은 친구의 닉네임 입력",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF7B61FF),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF7B61FF),
                    ),
                    onPressed: _onSearch,
                  ),
                ),
              ),
            ),
          ),

          // 📜 결과 리스트 영역
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
                  )
                : _searchResults.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Color(0xFFF2F4F7)),
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return _buildUserTile(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 80,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? "닉네임으로 친구를 찾아보세요!"
                : "검색 결과가 없습니다.",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    return StreamBuilder<bool>(
      stream: _dbService.isFollowingStream(user['uid']),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              // 💡 프로필 이미지 클릭 시 상세 정보 열기
              GestureDetector(
                onTap: () => _openProfileDetail(user),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFF2F4F7),
                  backgroundImage: user['profileUrl'] != null
                      ? NetworkImage(user['profileUrl'])
                      : const AssetImage('assets/images/default_profile.png')
                            as ImageProvider,
                ),
              ),
              const SizedBox(width: 16),
              // 💡 닉네임 영역 클릭 시 상세 정보 열기
              Expanded(
                child: GestureDetector(
                  onTap: () => _openProfileDetail(user),
                  behavior: HitTestBehavior.opaque, // 빈 공간 클릭도 감지
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['nickname'] ?? "익명",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF101828),
                        ),
                      ),
                      Text(
                        "최종 점수: ${user['score']} EXP",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 팔로우 토글 버튼
              SizedBox(
                width: 90,
                child: ElevatedButton(
                  onPressed: () =>
                      _dbService.toggleFollow(user['uid'], isFollowing),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: isFollowing
                        ? Colors.white
                        : const Color(0xFF7B61FF),
                    foregroundColor: isFollowing
                        ? const Color(0xFF344054)
                        : Colors.white,
                    side: isFollowing
                        ? const BorderSide(color: Color(0xFFD0D5DD))
                        : BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    isFollowing ? "언팔로우" : "팔로우",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
