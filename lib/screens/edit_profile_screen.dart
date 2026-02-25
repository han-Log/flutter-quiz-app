import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'package:login/theme/app_theme.dart'; // 💡 공통 테마 사용

class EditProfileScreen extends StatefulWidget {
  final String currentNickname;
  final String currentProfileUrl;

  const EditProfileScreen({
    super.key,
    required this.currentNickname,
    required this.currentProfileUrl,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  File? _newProfileImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.text = widget.currentNickname;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_isLoading) return;

    // 닉네임 비어있는지 체크
    if (_nicknameController.text.trim().isEmpty) {
      Get.snackbar("알림", "닉네임을 입력해주세요.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? currentUid = _authService.currentUser?.uid;
      if (currentUid == null) throw Exception("인증 오류");

      String? finalProfileUrl = widget.currentProfileUrl;
      if (_newProfileImage != null) {
        finalProfileUrl = await _storageService.uploadProfileImage(
          _newProfileImage!,
          currentUid,
        );
      }

      await _dbService.updateUserProfile(
        uid: currentUid,
        nickname: _nicknameController.text.trim(),
        profileUrl: finalProfileUrl,
      );

      Get.back(result: true);
      Get.snackbar("성공", "프로필이 업데이트되었습니다.");
    } catch (e) {
      Get.snackbar("오류", "변경 실패: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // 💡 마이페이지와 동일한 배경색
      appBar: AppBar(
        title: const Text(
          "프로필 수정",
          style: TextStyle(
            color: Color(0xFF101828),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 💡 1. 프로필 이미지 편집 섹션
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: _newProfileImage != null
                          ? FileImage(_newProfileImage!)
                          : (widget.currentProfileUrl.isNotEmpty
                                    ? NetworkImage(widget.currentProfileUrl)
                                    : const AssetImage(
                                        'assets/images/default_profile.png',
                                      ))
                                as ImageProvider,
                    ),
                  ),
                  // 📷 카메라 아이콘 버튼
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF7B61FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 🏷️ 닉네임 섹션 타이틀
            const Text(
              "닉네임",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            // 💡 2. 닉네임 입력 카드
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _nicknameController,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "사용할 닉네임을 입력하세요",
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),

            // 💡 3. 완료 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
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
                        "수정 완료",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 이미지 선택 로직 분리
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image != null) {
      setState(() => _newProfileImage = File(image.path));
    }
  }
}
