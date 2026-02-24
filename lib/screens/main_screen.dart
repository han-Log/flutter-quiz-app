import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login/screens/home_screen.dart';
import 'quiz_home_screen.dart';
// 💡 기존 RankingSystem 대신 새롭게 정의한 RankingScreen을 임포트합니다.
import 'ranking_screen.dart';
import '../services/database_service.dart';
import 'my_profile_screen.dart';

// 제일 처음 실행되는 화면(네비게이션)
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
        // 🏆 랭킹 페이지 호출 (RankingScreen으로 변경)
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

  // 💡 기존 _buildRankingPage는 RankingScreen 내부로 Scaffold가 이동했으므로
  // 더 이상 여기서 중첩해서 감쌀 필요가 없어 삭제하거나 간소화할 수 있습니다.

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
        // UID가 데이터 안에 없을 경우를 대비해 추가
        if (userData != null && snapshot.data != null) {
          userData['uid'] = snapshot.data!.id;
        }

        return Scaffold(
          body: _getScreen(_selectedIndex, userData),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  // 💡 요청하신 최신 문법 withValues 적용
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF7B61FF),
              unselectedItemColor: Colors.grey,
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
