import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../widgets/profile_detail_sheet.dart';

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

  final List<Map<String, dynamic>> _displayUsers = [];
  List<Map<String, dynamic>> _searchResults = [];

  bool _isLoading = false;
  bool _isSearching = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _limit = 15;

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

  Future<void> _fetchUsers() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      Query subQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.myUid)
          .collection(widget.isFollowingMode ? 'following' : 'followers')
          .orderBy('followedAt', descending: true)
          .limit(_limit);

      if (_lastDocument != null)
        subQuery = subQuery.startAfterDocument(_lastDocument!);
      final subSnapshot = await subQuery.get();

      if (subSnapshot.docs.length < _limit) _hasMore = false;
      if (subSnapshot.docs.isEmpty) {
        _hasMore = false;
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _lastDocument = subSnapshot.docs.last;
      List<String> uids = subSnapshot.docs.map((doc) => doc.id).toList();

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: uids)
          .get();

      Map<String, Map<String, dynamic>> userMap = {
        for (var doc in usersSnapshot.docs)
          doc.id: {...doc.data(), 'uid': doc.id},
      };

      List<Map<String, dynamic>> fetchedUsers = [];
      for (String id in uids) {
        if (userMap.containsKey(id)) fetchedUsers.add(userMap[id]!);
      }

      setState(() {
        _displayUsers.addAll(fetchedUsers);
      });
    } catch (e) {
      debugPrint("데이터 로드 에러: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${widget.title} 목록",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: const InputDecoration(
                  hintText: "닉네임 검색",
                  prefixIcon: Icon(Icons.search, color: Color(0xFF7B61FF)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isSearching
                ? _buildList(_searchResults)
                : _buildList(_displayUsers),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> users) {
    if (users.isEmpty && !_isLoading) return _buildEmptyState();

    return ListView.builder(
      controller: _isSearching ? null : _scrollController,
      physics: const BouncingScrollPhysics(),
      itemCount: users.length + (_hasMore && !_isSearching ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == users.length) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return _buildUserTile(users[index]);
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> userData) {
    String targetUid = userData['uid'] ?? "";
    return ListTile(
      onTap: () => _openProfile(userData),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: CircleAvatar(
        radius: 24,
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
      subtitle: Text("Level. ${((userData['score'] ?? 0) / 100).floor() + 1}"),
      trailing: StreamBuilder<bool>(
        stream: _dbService.isFollowingStream(targetUid),
        // 💡 [핵심 수정] 팔로잉 탭에서 들어왔다면 초기값을 true(언팔로우 버튼)로 설정합니다!
        initialData: widget.isFollowingMode ? true : false,
        builder: (context, snapshot) {
          // 데이터가 로딩 중일 때는 initialData를 사용하므로 번쩍거림이 사라집니다.
          bool isFollowing =
              snapshot.data ?? (widget.isFollowingMode ? true : false);
          return _buildFollowButton(targetUid, isFollowing);
        },
      ),
    );
  }

  Widget _buildFollowButton(String targetUid, bool isFollowing) {
    if (targetUid == widget.myUid) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () =>
          _dbService.toggleFollow(widget.myUid, targetUid, isFollowing),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 85,
        height: 32,
        decoration: BoxDecoration(
          color: isFollowing
              ? const Color(0xFFF2F4F7)
              : const Color(0xFF7B61FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isFollowing ? Colors.black87 : Colors.white,
            ),
            child: Text(isFollowing ? "언팔로우" : "팔로우"),
          ),
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
          Icon(Icons.person_outline, size: 60, color: Colors.grey[200]),
          const SizedBox(height: 10),
          Text("목록이 비어있습니다.", style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }
}
