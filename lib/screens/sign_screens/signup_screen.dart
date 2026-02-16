import 'package:flutter/material.dart';
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

  // 💡 로딩 상태를 관리하여 중복 클릭을 방지합니다.
  bool _isLoading = false;

  void _onSignup() async {
    final email = _emailController.text.trim();
    final password = _pwController.text.trim();
    final confirmPw = _confirmPwController.text.trim();
    final nickname = _nicknameController.text.trim();

    // 1. 사전 유효성 검사 (입력값 체크)
    if (nickname.isEmpty) return _showSnack("닉네임을 입력해주세요.");
    if (email.isEmpty) return _showSnack("이메일을 입력해주세요.");

    // 💡 Firebase 정책에 따라 비밀번호 6자 미만(aaa 등) 사전 차단
    if (password.length < 6) {
      return _showSnack("비밀번호는 최소 6자리 이상이어야 합니다.");
    }

    if (password != confirmPw) {
      return _showSnack("비밀번호가 일치하지 않습니다.");
    }

    // 2. 가입 프로세스 시작
    setState(() => _isLoading = true);

    try {
      // 💡 AuthService의 signUpEmail이 String?을 반환하도록 설계되었습니다.
      final String? errorMsg = await _authService.signUpEmail(
        email,
        password,
        nickname,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (errorMsg == null) {
        // ✅ 가입 성공
        _showSnack("회원가입이 완료되었습니다!", isError: false);
        Navigator.pop(context); // 가입 성공 후 로그인 창으로 이동
      } else {
        // ❌ 가입 실패 (중복 이메일 등 한글 에러 메시지 출력)
        _showSnack(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack("회원가입 중 예상치 못한 오류가 발생했습니다.");
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating, // 디자인을 위해 플로팅 스타일 적용
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

              _buildLabel("Nickname"),
              _buildTextField(
                controller: _nicknameController,
                hint: "Your Nickname",
                icon: Icons.face_outlined,
              ),
              const SizedBox(height: 20),

              _buildLabel("Email"),
              _buildTextField(
                controller: _emailController,
                hint: "Your Email",
                icon: Icons.mail_outline,
              ),
              const SizedBox(height: 20),

              _buildLabel("Password"),
              _buildTextField(
                controller: _pwController,
                hint: "Your Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 20),

              _buildLabel("Confirm Password"),
              _buildTextField(
                controller: _confirmPwController,
                hint: "Confirm Your Password",
                icon: Icons.check_circle_outline,
                isPassword: true,
              ),

              const SizedBox(height: 70),

              // 가입하기 버튼
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [Colors.grey, Colors.grey] // 로딩 중 버튼 색상 비활성화 느낌
                        : [const Color(0xFF8A72FF), const Color(0xFF7B61FF)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onSignup, // 로딩 중 클릭 차단
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
