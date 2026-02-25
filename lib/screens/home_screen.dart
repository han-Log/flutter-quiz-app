import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

import '../services/database_service.dart';
import '../widgets/user_info_view.dart';
import 'following_list_screen.dart';
import 'package:login/theme/app_theme.dart';

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

    // 💡 홈 화면 진입 시 출석 체크 및 스트릭 갱신 실행
    _dbService.handleAttendance();

    // 캐릭터 둥둥 떠다니는 애니메이션
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // 1. 헤더 (통합된 팔로우/팔로잉 섹션 포함)
                _buildHeader(context, userData),

                // 2. 수족관 뷰 및 스탯 영역 (UserInfoView)
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: UserInfoView(
                    userData: userData,
                    floatController: _floatController,
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- 💡 UI 구성 위젯들 ---

  // 상단 헤더: 타이틀과 통합된 팔로우 섹션
  Widget _buildHeader(BuildContext context, Map<String, dynamic> data) {
    String myUid = data['uid'] ?? "";
    // 데이터 오염 방지를 위해 최소값 0 보장
    int followers = math.max(0, data['followerCount'] ?? 0);
    int following = math.max(0, data['followingCount'] ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽: 웰컴 문구
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "현재 나의 상식 상태",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.deepPurple,
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "꾸준한 퀴즈 풀이로 레벨업!",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.explainTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 오른쪽: 통합 팔로우 정보 카드
          _buildFollowSection(context, myUid, followers, following),
        ],
      ),
    );
  }

  // 팔로워와 팔로잉을 하나로 묶은 통합 컨테이너
  Widget _buildFollowSection(
    BuildContext context,
    String uid,
    int followers,
    int following,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // 둥글둥글한 디자인
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 팔로워 섹션
          _buildFollowTab(context, "팔로워", followers, uid, false),

          // 💡 세로 구분선 (Vertical Divider)
          Container(width: 1, height: 22, color: Colors.grey.withOpacity(0.2)),

          // 팔로잉 섹션
          _buildFollowTab(context, "팔로잉", following, uid, true),
        ],
      ),
    );
  }

  // 개별 팔로우 탭 (클릭 가능 영역)
  Widget _buildFollowTab(
    BuildContext context,
    String label,
    int count,
    String uid,
    bool isFollowing,
  ) {
    return GestureDetector(
      onTap: () => uid.isEmpty
          ? null
          : showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => FractionallySizedBox(
                heightFactor: 0.75,
                child: FollowingListScreen(
                  myUid: uid,
                  title: label,
                  isFollowingMode: isFollowing,
                ),
              ),
            ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.transparent, // 투명 배경을 줘서 터치 영역 확대
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$count",
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
