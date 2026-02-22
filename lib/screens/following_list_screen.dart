import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import 'search_screen.dart';

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

  // 💡 리스트 초기화 및 다시 불러오기 함수
  Future<void> _refreshList() async {
    setState(() {
      _userDocs.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    await _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.myUid)
          .collection(widget.isFollowingMode ? 'following' : 'followers')
          // 💡 DatabaseService에서 이 이름과 똑같은 필드('followedAt')를 저장해야 합니다.
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
    } catch (e) {
      debugPrint("Error fetching users: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () async {
                // 💡 검색 화면으로 갔다가 돌아올 때(pop)를 기다립니다.
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
                // 💡 돌아오면 리스트를 새로고침합니다.
                _refreshList();
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
                            trailing: StreamBuilder<bool>(
                              stream: _dbService.isFollowingStream(targetUid),
                              builder: (context, followSnapshot) {
                                bool isFollowing = followSnapshot.data ?? false;

                                return SizedBox(
                                  width: 90,
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await _dbService.toggleFollow(
                                        widget.myUid,
                                        targetUid,
                                        isFollowing,
                                      );
                                      // 팔로우 상태가 변하면 리스트에서 제거하거나 갱신해야 할 수 있음
                                      if (widget.isFollowingMode &&
                                          isFollowing) {
                                        // 언팔로우 한 경우 리스트에서 즉시 제거 (선택 사항)
                                        setState(() {
                                          _userDocs.removeAt(index);
                                        });
                                      }
                                    },
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
