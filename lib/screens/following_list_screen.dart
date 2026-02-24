import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../widgets/profile_detail_sheet.dart';

// 팔로우, 팔로잉 관련된 스크린
class FollowingListScreen extends StatefulWidget {
  final String myUid;
  final String title;
  final bool isFollowingMode;

  const FollowingListScreen({
    super.key,
    required this.myUid,
    required this.title,
    required this.isFollowingMode,
  });

  @override
  State<FollowingListScreen> createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  final DatabaseService _dbService = DatabaseService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // 리스트 관련 상태
  final List<DocumentSnapshot> _userDocs = [];
  List<Map<String, dynamic>> _searchResults = [];

  bool _isLoading = false;
  bool _isSearching = false; // 💡 현재 검색 모드인지 여부
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoading &&
        _hasMore &&
        !_isSearching) {
      _fetchUsers();
    }
  }

  // 데이터 가져오기 (팔로우/팔로워)
  Future<void> _fetchUsers() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.myUid)
          .collection(widget.isFollowingMode ? 'following' : 'followers')
          .orderBy('followedAt', descending: true)
          .limit(_limit);

      if (_lastDocument != null)
        query = query.startAfterDocument(_lastDocument!);
      final querySnapshot = await query.get();

      if (querySnapshot.docs.length < _limit) _hasMore = false;
      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        setState(() => _userDocs.addAll(querySnapshot.docs));
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 검색 실행
  void _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    final results = await _dbService.searchUsers(query);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _isSearching = false);
                },
              )
            : null,
      ),
      body: Column(
        children: [
          // 🔍 통합 검색창
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isSearching
                      ? const Color(0xFF7B61FF)
                      : Colors.transparent,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch, // 💡 타이핑할 때마다 검색
                decoration: InputDecoration(
                  hintText: "새로운 친구 찾기...",
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF7B61FF),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          Expanded(
            child: _isSearching
                ? _buildSearchResultList() // 💡 검색 결과 화면
                : _buildFollowList(), // 💡 기존 팔로우 리스트 화면
          ),
        ],
      ),
    );
  }

  // 1. 기존 팔로우/팔로워 리스트 빌더
  Widget _buildFollowList() {
    if (_userDocs.isEmpty && !_isLoading) return _buildEmptyState();
    return ListView.builder(
      controller: _scrollController,
      itemCount: _userDocs.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _userDocs.length)
          return const Center(child: CircularProgressIndicator());
        String targetUid = _userDocs[index].id;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(targetUid)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            var userData = snapshot.data!.data() as Map<String, dynamic>?;
            if (userData == null) return const SizedBox.shrink();
            return _buildUserTile(userData, targetUid);
          },
        );
      },
    );
  }

  // 2. 검색 결과 리스트 빌더
  Widget _buildSearchResultList() {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
      );
    if (_searchResults.isEmpty)
      return const Center(child: Text("검색 결과가 없습니다."));

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final userData = _searchResults[index];
        return _buildUserTile(userData, userData['uid']);
      },
    );
  }

  // 공통 유저 타일 위젯
  Widget _buildUserTile(Map<String, dynamic> userData, String targetUid) {
    return ListTile(
      onTap: () => _openProfile(userData),
      leading: CircleAvatar(
        radius: 25,
        backgroundImage:
            userData['profileUrl'] != null && userData['profileUrl'] != ""
            ? NetworkImage(userData['profileUrl'])
            : const AssetImage('assets/images/default_profile.png')
                  as ImageProvider,
      ),
      title: Text(
        userData['nickname'] ?? "익명",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text("EXP ${userData['score'] ?? 0}"),
      trailing: StreamBuilder<bool>(
        stream: _dbService.isFollowingStream(targetUid),
        builder: (context, snapshot) {
          bool isFollowing = snapshot.data ?? false;
          return _buildFollowButton(targetUid, isFollowing);
        },
      ),
    );
  }

  Widget _buildFollowButton(String targetUid, bool isFollowing) {
    return SizedBox(
      width: 90,
      height: 32,
      child: ElevatedButton(
        onPressed: () =>
            _dbService.toggleFollow(widget.myUid, targetUid, isFollowing),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing
              ? const Color(0xFFF2F4F7)
              : const Color(0xFF7B61FF),
          foregroundColor: isFollowing ? Colors.black87 : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          isFollowing ? "언팔로우" : "팔로우",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _openProfile(Map<String, dynamic> userData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ProfileDetailSheet(userData: userData, myUid: widget.myUid),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add_outlined, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            "아직 ${widget.title}가 없어요.\n친구를 검색해 보세요!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
