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
  int _previousIndex = 0;

  final DatabaseService _dbService = DatabaseService();
  late Stream<DocumentSnapshot> _userDataStream;

  final List<IconData> _icons = [
    Icons.home_outlined,
    Icons.emoji_events_outlined,
    Icons.play_circle_outline,
    Icons.person_outline,
  ];

  final List<IconData> _activeIcons = [
    Icons.home,
    Icons.emoji_events,
    Icons.play_circle_fill,
    Icons.person,
  ];

  final List<String> _labels = ['홈', '랭킹', '퀴즈 시작', '마이페이지'];

  @override
  void initState() {
    super.initState();
    _userDataStream = _dbService.userDataStream;
  }

  Widget _getScreen(int index, Map<String, dynamic>? userData) {
    switch (index) {
      case 0:
        return const HomeScreen(key: ValueKey<int>(0));
      case 1:
        return RankingScreen(
          key: const ValueKey<int>(1),
          myUid: userData?['uid'],
        );
      case 2:
        return const QuizHomeScreen(key: ValueKey<int>(2));
      case 3:
        return userData != null
            ? MyProfileScreen(key: const ValueKey<int>(3), userData: userData)
            : const Center(
                key: ValueKey<int>(3),
                child: CircularProgressIndicator(),
              );
      default:
        return const QuizHomeScreen(key: ValueKey<int>(0));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 플로팅 바를 위해 전체 너비에서 마진을 뺀 만큼으로 너비 계산을 수정합니다.
    final double horizontalMargin = 20.0; // 좌우 마진
    final double barWidth =
        MediaQuery.of(context).size.width - (horizontalMargin * 2);
    final double tabWidth = barWidth / 4;

    return StreamBuilder<DocumentSnapshot>(
      stream: _userDataStream,
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
          extendBody: true, // 본문이 네비바 뒤까지 보이게 설정
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final key = child.key as ValueKey<int>?;
              final int childIndex = key?.value ?? 0;

              final bool isGoingRight = _selectedIndex > _previousIndex;
              final bool isIncoming = childIndex == _selectedIndex;

              final double offsetX = isGoingRight
                  ? (isIncoming ? 1.0 : -1.0)
                  : (isIncoming ? -1.0 : 1.0);

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: Offset(offsetX, 0.0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOutCubic,
                        ),
                      ),
                  child: child,
                ),
              );
            },
            child: _getScreen(_selectedIndex, userData),
          ),

          // 💡 수정된 플로팅 네비게이션 바
          bottomNavigationBar: Container(
            margin: EdgeInsets.fromLTRB(
              horizontalMargin,
              0,
              horizontalMargin,
              25,
            ), // 좌우 20, 아래 25 띄우기
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85), // 살짝 투명하게
              borderRadius: BorderRadius.circular(35), // 캡슐 모양 곡률
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1), // 그림자를 조금 더 선명하게
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5), // 아래로 그림자 드리우기
                ),
              ],
            ),
            child: Stack(
              children: [
                // 💡 배경 물방울 애니메이션 (이제 barWidth 기준으로 움직임)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: _selectedIndex.toDouble()),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  builder: (context, value, child) {
                    double leftPosition = value * tabWidth;

                    double diff = (value - value.roundToDouble()).abs();
                    double scale = 1.0 - (diff * 0.8); // 쪼그라드는 정도 살짝 조절

                    return Positioned(
                      left: leftPosition,
                      top: 0,
                      bottom: 0,
                      child: SizedBox(
                        width: tabWidth,
                        child: Center(
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 70,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF7B61FF,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                  25,
                                ), // 곡률 맞춰주기
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                Row(
                  children: List.generate(4, (index) {
                    bool isSelected = _selectedIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (_selectedIndex == index) return;
                          setState(() {
                            _previousIndex = _selectedIndex;
                            _selectedIndex = index;
                          });
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: isSelected ? 1.2 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              child: Icon(
                                isSelected
                                    ? _activeIcons[index]
                                    : _icons[index],
                                color: isSelected
                                    ? const Color(0xFF7B61FF)
                                    : Colors.grey.withValues(alpha: 0.8),
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF7B61FF)
                                    : Colors.grey.withValues(alpha: 0.8),
                              ),
                              child: Text(_labels[index]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
