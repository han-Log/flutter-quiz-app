import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../widgets/user_info_view.dart'; // 💡 새로 만든 위젯 임포트
import 'package:login/theme/app_theme.dart';

// 유저를 클릭했을 때 나오는 프로필 정보
class ProfileDetailSheet extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String myUid;

  const ProfileDetailSheet({
    super.key,
    required this.userData,
    required this.myUid,
  });

  @override
  State<ProfileDetailSheet> createState() => _ProfileDetailSheetState();
}

class _ProfileDetailSheetState extends State<ProfileDetailSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  final DatabaseService _dbService = DatabaseService();
  bool isFollowing = false;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    isFollowing = widget.userData['isFollowing'] ?? false;
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userData;
    final nickname =
        user['nickname']?.toString() ?? user['name']?.toString() ?? "익명";

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildHandle(),
                    const SizedBox(height: 25),
                    // 💡 바텀시트 전용 헤더 (팔로우 버튼 포함)
                    _buildSheetHeader(nickname, user['uid']),
                    const SizedBox(height: 20),
                    // 💡 공통 수족관 위젯 사용
                    UserInfoView(
                      userData: user,
                      floatController: _floatController,
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHeader(String nickname, String? targetUid) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$nickname님의 수족관",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.titleTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  "상대방의 지식 성장도를 확인해보세요",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.explainTextColor,
                  ),
                ),
              ],
            ),
          ),
          if (widget.myUid != targetUid) _buildFollowButton(),
        ],
      ),
    );
  }

  // (이하 _handleFollow, _buildFollowButton, _buildBottomButton 등 기존 로직 유지)
  // ... 생략 ...

  Widget _buildHandle() => Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(2),
    ),
  );
  Widget _buildBottomButton() => Positioned(
    bottom: 20,
    left: 24,
    right: 24,
    child: SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: () => Get.back(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          "수족관 나가기",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );

  Widget _buildFollowButton() => GestureDetector(
    onTap: _handleFollow,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isFollowing ? Colors.white : AppColors.primaryPurple,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryPurple),
      ),
      child: isProcessing
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textGrey,
              ),
            )
          : Text(
              isFollowing ? "팔로잉" : "팔로우",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isFollowing ? AppColors.primaryPurple : Colors.white,
              ),
            ),
    ),
  );

  Future<void> _handleFollow() async {
    if (isProcessing) return;
    setState(() => isProcessing = true);
    try {
      await _dbService.toggleFollow(
        widget.myUid,
        widget.userData['uid'],
        isFollowing,
      );
      setState(() => isFollowing = !isFollowing);
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }
}
