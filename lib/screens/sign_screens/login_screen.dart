import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart'; // 💡 AppColors 사용을 위해 임포트
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _rememberMe = false;
  bool _isLoading = false;

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleLogin(Future<String?> loginMethod) async {
    setState(() => _isLoading = true);
    final String? errorMsg = await loginMethod;
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (errorMsg == null) {
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } else {
      _showSnack(errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 💡 상단 뒤로가기 버튼을 위해 AppBar 추가 (WelcomeScreen으로 돌아가기)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.deepPurple,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. 상단 캐릭터 로고 (WelcomeScreen과의 일관성)
              Image.asset(
                'assets/images/Wellcome_charactor.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 10),
              const Text(
                "반가워요!",
                style: TextStyle(
                  color: AppColors.deepPurple,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "이메일로 간편하게 로그인하세요",
                style: TextStyle(
                  color: AppColors.explainTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),

              // 2. 입력 필드 영역
              _buildLabel("Email Address"),
              _buildTextField(
                controller: _emailController,
                hint: "이메일을 입력해주세요",
                icon: Icons.alternate_email_rounded,
              ),
              const SizedBox(height: 20),

              _buildLabel("Password"),
              _buildTextField(
                controller: _passwordController,
                hint: "비밀번호를 입력해주세요",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),

              // 3. 부가 옵션 (자동로그인 / 비번찾기)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (val) => setState(() => _rememberMe = val!),
                        activeColor: AppColors.primaryPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Text(
                        "로그인 유지",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.deepPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "비밀번호 찾기",
                      style: TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 4. 로그인 버튼
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : () => _handleLogin(
                        _authService.loginWithEmail(
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                        ),
                      ),
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: _isLoading
                          ? [Colors.grey.shade300, Colors.grey.shade400]
                          : [const Color(0xFF8A72FF), AppColors.primaryPurple],
                    ),
                    boxShadow: [
                      if (!_isLoading)
                        BoxShadow(
                          color: AppColors.primaryPurple.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "로그인하기",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 5. 회원가입 유도
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "아직 회원이 아니신가요? ",
                    style: TextStyle(color: AppColors.explainTextColor),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "회원가입",
                      style: TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 💡 라벨 위젯 커스텀
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.deepPurple,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // 💡 입력창 위젯 커스텀 (HomeScreen의 카드 스타일 적용)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), // 웰컴스크린 가이드 카드와 같은 배경색
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(
          color: AppColors.deepPurple,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.primaryPurple, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
