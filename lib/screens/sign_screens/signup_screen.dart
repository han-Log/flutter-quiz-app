import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  final _nicknameController = TextEditingController();
  final AuthService _authService = AuthService();

  void _onSignup() async {
    if (_nicknameController.text.trim().isEmpty) {
      _showSnack("닉네임을 입력해주세요.");
      return;
    }
    if (_pwController.text != _confirmPwController.text) {
      _showSnack("비밀번호가 일치하지 않습니다.");
      return;
    }

    try {
      await _authService.signUpEmail(
        _emailController.text.trim(),
        _pwController.text.trim(),
        _nicknameController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      _showSnack("회원가입이 완료되었습니다!", isError: false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnack(_authService.getKoreanErrorMessage(e.code));
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    _confirmPwController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF101828)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "회원가입",
                style: TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "새로운 계정을 만들어보세요.",
                style: TextStyle(color: Color(0xFF475467), fontSize: 14),
              ),
              const SizedBox(height: 40),

              // 닉네임 입력창
              _buildLabel("Nickname"),
              _buildTextField(
                controller: _nicknameController,
                hint: "Your Nickname",
                icon: Icons.face_outlined,
              ),
              const SizedBox(height: 20),

              // Email 입력창
              _buildLabel("Email"),
              _buildTextField(
                controller: _emailController,
                hint: "Your Email",
                icon: Icons.mail_outline,
              ),
              const SizedBox(height: 20),

              // Password 입력창
              _buildLabel("Password"),
              _buildTextField(
                controller: _pwController,
                hint: "Your Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 20),

              // Password 확인 입력창
              _buildLabel("Confirm Password"),
              _buildTextField(
                controller: _confirmPwController,
                hint: "Confirm Your Password",
                icon: Icons.check_circle_outline,
                isPassword: true,
              ),

              const SizedBox(height: 70),

              // 가입하기 버튼 (LoginScreen과 동일한 그라데이션)
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
                  onPressed: _onSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "가입하기",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 로그인 화면과 통일된 라벨 스타일
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

  // 로그인 화면과 통일된 텍스트 필드 스타일
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
