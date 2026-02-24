import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../widgets/user_info_view.dart'; // 💡 새로 만든 위젯 임포트
import 'following_list_screen.dart';
import 'package:login/theme/app_theme.dart';

// 처음 화면에 나타나는 스크린
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _dbService.userDataStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // 💡 홈 화면 전용 헤더
                _buildHeader(context, userData),
                const SizedBox(height: 20),
                // 💡 공통 수족관 위젯 사용
                UserInfoView(
                  userData: userData,
                  floatController: _floatController,
                ),
                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> data) {
    String myUid = data['uid'] ?? "";
    int followers = data['followerCount'] ?? 0;
    int following = data['followingCount'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "현재 나의 상식 상태",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.titleTextColor,
                ),
              ),
              Text(
                "꾸준한 퀴즈 풀이로 레벨을 올려보세요",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.explainTextColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildFollowItem(context, "팔로워", followers, myUid, false),
              const SizedBox(width: 15),
              _buildFollowItem(context, "팔로잉", following, myUid, true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowItem(
    BuildContext context,
    String label,
    int count,
    String uid,
    bool isFollowing,
  ) => GestureDetector(
    onTap: () => uid.isEmpty
        ? null
        : Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => FollowingListScreen(
                myUid: uid,
                title: label,
                isFollowingMode: isFollowing,
              ),
            ),
          ),
    child: Column(
      children: [
        Text(
          "$count",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryPurple,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
      ],
    ),
  );
}
