import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart'; // 💡 공통 테마 임포트

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  void _onResetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnack("이메일을 입력해주세요.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().sendPasswordResetEmail(email);

      if (!mounted) return;
      setState(() => _isLoading = false);

      _showSnack("재설정 이메일이 발송되었습니다.", isError: false);
      Navigator.pop(context); // 메일 발송 후 로그인 화면으로 복귀
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack("이메일 발송 중 오류가 발생했습니다.");
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
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 💡 일관성 있는 상단 뒤로가기 버튼
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
            children: [
              // 1. 상단 캐릭터와 타이틀
              Image.asset(
                'assets/images/Wellcome_charactor.png',
                width: 100,
                height: 100,
              ),
              const Text(
                "비밀번호 재설정",
                style: TextStyle(
                  color: AppColors.deepPurple,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "가입하신 이메일을 입력하시면\n비밀번호 재설정 링크를 보내드립니다.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.explainTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // 2. Email 입력 영역
              _buildLabel("Email Address"),
              _buildTextField(
                controller: _emailController,
                hint: "example@email.com",
                icon: Icons.alternate_email_rounded,
              ),

              const SizedBox(height: 40),

              // 3. 링크 보내기 버튼
              GestureDetector(
                onTap: _isLoading ? null : _onResetPassword,
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
                            "재설정 링크 보내기",
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
      ),
    );
  }

  // 💡 라벨 위젯 (통일된 스타일)
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

  // 💡 텍스트 필드 위젯 (통일된 스타일)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
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
