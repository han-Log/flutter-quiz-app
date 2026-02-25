import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../screens/sign_screens/login_screen.dart';
import '../screens/LoadingScreen.dart'; // 💡 로딩 스크린 임포트

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthService authService = AuthService();
  bool _isLoading = false;

  // 💡 로그인 핸들러 수정
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    final String? errorMsg = await authService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (errorMsg == null) {
      // ✅ 로그인 성공 시: 로딩 화면으로 먼저 이동 (스택 완전 삭제)
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const LoadingScreen(message: "상식을 맛있게 차리고 있어요!"),
          ),
          (route) => false, // 이전 로그인 기록(스택) 모두 제거
        );
      }
    } else {
      // ❌ 실패 시: 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // 캐릭터 이미지 + 타이틀 (현재 유지 중인 오프셋 적용)
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(63, -20),
                    child: Text(
                      "상식 한 입",
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: AppColors.deepPurple,
                        letterSpacing: -1.5,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -100,
                    left: -190,
                    child: Image.asset(
                      'assets/images/Wellcome_charactor.png',
                      width: 400,
                      height: 400,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Transform.translate(
                offset: const Offset(62, 5),
                child: Text(
                  "어서오세요\n환영합니다!",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppColors.explainTextColor.withValues(alpha: 0.8),
                    height: 1.6,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              _buildGuideCard(),

              const Spacer(),

              // 구글 로그인 버튼
              _buildActionButton(
                label: "Google로 시작하기",
                icon: Icons.g_mobiledata_rounded,
                isPrimary: false,
                isLoading: _isLoading,
                onTap: _isLoading ? () {} : _handleGoogleLogin,
              ),

              const SizedBox(height: 12),

              // 이메일 로그인 버튼
              _buildActionButton(
                label: "이메일로 시작하기",
                icon: Icons.mail_rounded,
                isPrimary: true,
                isLoading: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- 가이드 및 버튼 위젯들 (생략 없이 유지) ---
  Widget _buildGuideCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Column(
        children: [
          _buildGuideItem(Icons.category_outlined, "다양한 분야의 AI 상식 퀴즈"),
          const SizedBox(height: 18),
          _buildGuideItem(Icons.trending_up_rounded, "정답을 맞힐수록 성장하는 캐릭터"),
          const SizedBox(height: 18),
          _buildGuideItem(Icons.calendar_today_rounded, "연속 출석으로 채워나가는 학습 잔디"),
        ],
      ),
    );
  }

  Widget _buildGuideItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryPurple),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.deepPurple,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primaryPurple : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isPrimary
              ? null
              : Border.all(color: const Color(0xFFD0D5DD), width: 1.2),
          boxShadow: [
            if (isPrimary)
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryPurple,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: isPrimary ? Colors.white : Colors.black87,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: TextStyle(
                        color: isPrimary ? Colors.white : Colors.black87,
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
