import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

// 💡 여기를 StatelessWidget으로 수정했습니다.
// StatefulWidget은 createState()가 필요하지만, 이 클래스는 build만 있으면 되거든요!
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: const SignupBody(),
    );
  }
}

// 💡 실제 상태(State) 관리는 여기서 진행됩니다.
class SignupBody extends StatefulWidget {
  const SignupBody({super.key});

  @override
  State<SignupBody> createState() => _SignupBodyState();
}

class _SignupBodyState extends State<SignupBody> {
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  final _nicknameController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  void _onSignup() async {
    final email = _emailController.text.trim();
    final password = _pwController.text.trim();
    final confirmPw = _confirmPwController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (nickname.isEmpty) return _showSnack("닉네임을 입력해주세요.");
    if (email.isEmpty) return _showSnack("이메일을 입력해주세요.");
    if (password.length < 6) return _showSnack("비밀번호는 최소 6자리 이상이어야 합니다.");
    if (password != confirmPw) return _showSnack("비밀번호가 일치하지 않습니다.");

    setState(() => _isLoading = true);

    try {
      final String? errorMsg = await _authService.signUpEmail(
        email,
        password,
        nickname,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (errorMsg == null) {
        _showSnack("회원가입이 완료되었습니다!", isError: false);
        Navigator.pop(context);
      } else {
        _showSnack(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack("회원가입 중 오류가 발생했습니다.");
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const Text(
              "회원가입",
              style: TextStyle(
                color: AppColors.deepPurple,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "상식 한 입과 함께할 계정을 만들어보세요",
              style: TextStyle(
                color: AppColors.explainTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),

            _buildLabel("Nickname"),
            _buildTextField(
              controller: _nicknameController,
              hint: "사용하실 닉네임을 입력해주세요",
              icon: Icons.face_rounded,
            ),
            const SizedBox(height: 20),

            _buildLabel("Email Address"),
            _buildTextField(
              controller: _emailController,
              hint: "이메일 주소를 입력해주세요",
              icon: Icons.alternate_email_rounded,
            ),
            const SizedBox(height: 20),

            _buildLabel("Password"),
            _buildTextField(
              controller: _pwController,
              hint: "비밀번호 (6자 이상)",
              icon: Icons.lock_outline_rounded,
              isPassword: true,
            ),
            const SizedBox(height: 20),

            _buildLabel("Confirm Password"),
            _buildTextField(
              controller: _confirmPwController,
              hint: "비밀번호를 한 번 더 입력해주세요",
              icon: Icons.check_circle_outline_rounded,
              isPassword: true,
            ),

            const SizedBox(height: 50),

            GestureDetector(
              onTap: _isLoading ? null : _onSignup,
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
                        color: AppColors.primaryPurple.withValues(alpha: 0.25),
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
                          "가입하기",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
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
