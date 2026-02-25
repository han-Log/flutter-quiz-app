import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/level_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'edit_profile_screen.dart';
import 'package:login/theme/app_theme.dart';

class MyProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const MyProfileScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "마이페이지",
          style: TextStyle(
            color: Color(0xFF101828),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: dbService.userDataStream,
        builder: (context, snapshot) {
          var liveData = snapshot.hasData && snapshot.data!.data() != null
              ? snapshot.data!.data() as Map<String, dynamic>
              : userData;

          int exp = liveData['score'] ?? 0;
          int level = LevelService.getLevel(exp);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "내 정보",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),

                _buildMenuCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          currentNickname: liveData['nickname'] ?? "익명",
                          currentProfileUrl: liveData['profileUrl'] ?? "",
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.background,
                        backgroundImage:
                            liveData['profileUrl'] != null &&
                                liveData['profileUrl'].toString().isNotEmpty
                            ? NetworkImage(liveData['profileUrl'])
                            : const AssetImage(
                                    'assets/images/default_profile.png',
                                  )
                                  as ImageProvider,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              liveData['nickname'] ?? "익명",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Lv.$level ${LevelService.getLevelName(level)}",
                              style: const TextStyle(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const Text(
                  "계정 설정",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),

                // 💡 로그아웃 버튼 로직 수정
                _buildMenuCard(
                  onTap: () async {
                    // 1. Firebase 로그아웃 수행
                    await authService.signOut();

                    if (!context.mounted) return;

                    // 2. 웰컴 스크린으로 이동하며 모든 스택 비우기
                    // 💡 pushNamedAndRemoveUntil을 쓰면 이전 화면으로 돌아갈 수 없습니다.
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/welcome', // main.dart에 등록한 welcome 경로
                      (route) => false, // 모든 이전 경로 제거
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "로그아웃",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    "Version 1.3.0",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCard({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
