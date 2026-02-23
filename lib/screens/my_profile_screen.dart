import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/level_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'edit_profile_screen.dart'; // 💡 새로 추가될 화면 임포트

class MyProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const MyProfileScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "마이페이지",
          style: TextStyle(
            color: Color(0xFF101828),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async {
              await authService.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: dbService.userDataStream,
        builder: (context, snapshot) {
          // 실시간 데이터가 있으면 업데이트, 없으면 전달받은 기본 데이터 사용
          var liveData = snapshot.hasData && snapshot.data!.data() != null
              ? snapshot.data!.data() as Map<String, dynamic>
              : userData;

          int exp = liveData['score'] ?? 0;
          int level = LevelService.getLevel(exp);

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 💡 프로필 이미지
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      liveData['profileUrl'] != null &&
                          liveData['profileUrl'].toString().isNotEmpty
                      ? NetworkImage(liveData['profileUrl'])
                      : const AssetImage('assets/images/default_profile.png')
                            as ImageProvider,
                  child:
                      liveData['profileUrl'] == null ||
                          liveData['profileUrl'].toString().isEmpty
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 20),

                // 💡 닉네임
                Text(
                  liveData['nickname'] ?? "익명",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 8),

                // 💡 레벨 정보
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Lv.$level ${LevelService.getLevelName(level)}",
                    style: const TextStyle(
                      color: Color(0xFF7B61FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 💡 [새로운 버튼] 내 정보 변경 버튼
                ElevatedButton(
                  onPressed: () {
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF), // 버튼 배경색
                    foregroundColor: Colors.white, // 버튼 글자색
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "내 정보 변경",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
