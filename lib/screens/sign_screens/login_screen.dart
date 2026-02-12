import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 💡 필수 추가
import '../../services/auth_service.dart';
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
  final AuthService _authService = AuthService(); // 인스턴스 유지
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const SizedBox(height: 80),
              const Text(
                "로그인",
                style: TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "내 계정에 로그인 하세요.",
                style: TextStyle(color: Color(0xFF475467), fontSize: 14),
              ),
              const SizedBox(height: 48),

              _buildLabel("Email"),
              _buildTextField(
                controller: _emailController,
                hint: "My Email",
                icon: Icons.mail_outline,
              ),
              const SizedBox(height: 20),

              _buildLabel("Password"),
              _buildTextField(
                controller: _passwordController,
                hint: "My Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (val) =>
                              setState(() => _rememberMe = val!),
                          activeColor: const Color(0xFF7B61FF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text("Remember Me", style: TextStyle(fontSize: 14)),
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
                      "Forgot Password",
                      style: TextStyle(
                        color: Color(0xFF7B61FF),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 1. 이메일 로그인 버튼
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A72FF), Color(0xFF7B61FF)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    // 💡 에러 해결: 변수에 담지 않고 함수만 실행
                    await _authService.loginWithEmail(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                    );

                    if (!mounted) return;

                    // 💡 직접 로그인 상태 확인
                    if (FirebaseAuth.instance.currentUser != null) {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "로그인",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "OR",
                      style: TextStyle(color: Color(0xFF98A2B3)),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 40),

              // 2. 구글 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // 💡 에러 해결: userCredential 변수를 지우고 함수만 실행
                    await _authService.signInWithGoogle();

                    if (!mounted) return;

                    // 💡 직접 로그인 상태 확인
                    if (FirebaseAuth.instance.currentUser != null) {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 30),
                  label: const Text(
                    "Google로 로그인",
                    style: TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Color(0xFF475467)),
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
                      "Sign Up Here",
                      style: TextStyle(
                        color: Color(0xFF7B61FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // UI 빌더 함수들은 그대로 유지합니다.
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF344054),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF7B61FF)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
