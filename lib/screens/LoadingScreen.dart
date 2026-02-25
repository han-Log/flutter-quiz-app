import 'package:flutter/material.dart';
import 'package:login/theme/app_theme.dart';

class LoadingScreen extends StatefulWidget {
  final String message;
  // 💡 목적지 경로를 미리 받으면 더 유연하게 쓸 수 있습니다.
  final String nextRoute;

  const LoadingScreen({
    super.key,
    this.message = "수족관 물을 채우는 중...",
    this.nextRoute = '/main', // 기본값은 메인 화면
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 1. 애니메이션 설정
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // 🔥 2. 핵심: 페이지 전환 로직 추가
    // 로딩 화면을 보여줄 시간(예: 2초)을 설정합니다.
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        // 💡 pushReplacementNamed를 써야 뒤로가기를 눌러도 다시 로딩창으로 안 옵니다.
        Navigator.pushReplacementNamed(context, widget.nextRoute);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 캐릭터 애니메이션
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation.value),
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/Wellcome_charactor.png',
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 40),

            // 인디케이터
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryPurple,
              ),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),

            // 로딩 메시지
            Text(
              widget.message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.deepPurple,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "잠시만 기다려주세요!",
              style: TextStyle(fontSize: 13, color: AppColors.explainTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
