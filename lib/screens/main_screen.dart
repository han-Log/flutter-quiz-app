import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login/screens/home_screen.dart';
import 'quiz_home_screen.dart';
import '../widgets/ranking_system.dart';
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
        // 💡 랭킹 페이지 호출
        return _buildRankingPage(userData?['uid']);
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

  // 🏆 랭킹 전용 페이지 구성
  Widget _buildRankingPage(String? myUid) {
    // 💡 Scaffold와 RankingSystem 사이에 SingleChildScrollView를 제거했습니다.
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "LEADER BOARD", // READER -> LEADER 오타 수정
          style: TextStyle(
            color: Color(0xFF2D1B69),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      // 💡 Expanded나 SingleChildScrollView 없이 RankingSystem만 넣습니다.
      // 💡 RankingSystem 내부에서 리스트를 관리하므로 이게 가장 깔끔합니다.
      body: RankingSystem(myUid: myUid),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _dbService.userDataStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;

        return Scaffold(
          body: _getScreen(_selectedIndex, userData),
          bottomNavigationBar: BottomNavigationBar(
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
        );
      },
    );
  }
}
