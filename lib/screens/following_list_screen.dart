import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import 'search_screen.dart'; // 검색 화면으로 이동이 필요한 경우

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

  final List<DocumentSnapshot> _userDocs = [];
  bool _isLoading = false;
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
        _hasMore) {
      _fetchUsers();
    }
  }

  Future<void> _fetchUsers() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.myUid)
        .collection(widget.isFollowingMode ? 'following' : 'followers')
        .orderBy('followedAt', descending: true)
        .limit(_limit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final querySnapshot = await query.get();

    if (querySnapshot.docs.length < _limit) {
      _hasMore = false;
    }

    if (querySnapshot.docs.isNotEmpty) {
      _lastDocument = querySnapshot.docs.last;
      setState(() {
        _userDocs.addAll(querySnapshot.docs);
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      ),
      body: Column(
        children: [
          // 🔍 1. 상단 친구 찾기 바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () {
                // 클릭 시 기존에 만들어둔 검색 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey.shade600),
                    const SizedBox(width: 10),
                    Text(
                      "새로운 친구 찾기...",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 👥 2. 리스트 영역
          Expanded(
            child: _userDocs.isEmpty && !_isLoading
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _userDocs.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _userDocs.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      String targetUid = _userDocs[index].id;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(targetUid)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData)
                            return const SizedBox.shrink();
                          var userData =
                              userSnapshot.data!.data()
                                  as Map<String, dynamic>?;
                          if (userData == null) return const SizedBox.shrink();

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: userData['profileUrl'] != null
                                  ? NetworkImage(userData['profileUrl'])
                                  : const AssetImage(
                                          'assets/images/default_profile.png',
                                        )
                                        as ImageProvider,
                            ),
                            title: Text(
                              userData['nickname'] ?? "익명",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "Lv.${(userData['score'] ?? 0) ~/ 100 + 1}",
                            ),
                            // 🔘 팔로우/언팔로우 버튼
                            trailing: StreamBuilder<bool>(
                              stream: _dbService.isFollowingStream(targetUid),
                              builder: (context, followSnapshot) {
                                bool isFollowing = followSnapshot.data ?? false;

                                return SizedBox(
                                  width: 90,
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: () => _dbService.toggleFollow(
                                      targetUid,
                                      isFollowing,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isFollowing
                                          ? Colors.grey.shade200
                                          : const Color(0xFF7B61FF),
                                      foregroundColor: isFollowing
                                          ? Colors.black87
                                          : Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      isFollowing ? "언팔로우" : "팔로우",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
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
          Icon(Icons.group_add_outlined, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            "아직 ${widget.title}가 없어요.\n새로운 친구를 찾아보세요!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
