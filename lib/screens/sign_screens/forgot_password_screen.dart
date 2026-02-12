import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
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
                "비밀번호 재설정",
                style: TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "가입하신 이메일을 입력하시면\n비밀번호 재설정 링크를 보내드립니다.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF475467), fontSize: 14),
              ),
              const SizedBox(height: 48),

              // Email 입력창
              _buildLabel("Email Address"),
              _buildTextField(
                controller: _emailController,
                hint: "example@email.com",
                icon: Icons.mail_outline,
              ),

              const SizedBox(height: 40),

              // 재설정 링크 보내기 버튼
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
                    if (_emailController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("이메일을 입력해주세요.")),
                      );
                      return;
                    }

                    await AuthService().sendPasswordResetEmail(
                      _emailController.text.trim(),
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("재설정 이메일이 발송되었습니다."),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
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
                    "재설정 링크 보내기",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 통일된 라벨 스타일
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

  // 통일된 텍스트 필드 스타일
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
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
