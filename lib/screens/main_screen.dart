import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login/screens/home_screen.dart';
import 'quiz_home_screen.dart';
import 'ranking_screen.dart';
import '../services/database_service.dart';
import 'my_profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final DatabaseService _dbService = DatabaseService();

  Widget _getScreen(int index, Map<String, dynamic>? userData) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return RankingScreen(myUid: userData?['uid']);
      case 2:
        return const QuizHomeScreen();
      case 3:
        return userData != null
            ? MyProfileScreen(userData: userData)
            : const Center(child: CircularProgressIndicator());
      default:
        return const QuizHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _dbService.userDataStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
            ),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        if (userData != null && snapshot.data != null) {
          userData['uid'] = snapshot.data!.id;
        }

        return Scaffold(
          // 💡 본문이 네비게이션 바 영역까지 확장되도록 설정 (투명 효과의 핵심)
          extendBody: true,
          body: _getScreen(_selectedIndex, userData),
          bottomNavigationBar: Container(
            // 💡 상단에 미세한 경계선을 주거나 그림자를 조절하여 가독성 확보
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              // 💡 배경색에 투명도 적용 (withValues 사용)
              backgroundColor: Colors.white.withValues(alpha: 0.95),
              elevation: 0, // 그림자를 Container에서 제어하므로 0으로 설정
              selectedItemColor: const Color(0xFF7B61FF),
              unselectedItemColor: Colors.grey.withValues(alpha: 0.8),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: '홈',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events_outlined),
                  activeIcon: Icon(Icons.emoji_events),
                  label: '랭킹',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.play_circle_outline),
                  activeIcon: Icon(Icons.play_circle_fill),
                  label: '퀴즈 시작',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: '마이페이지',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
