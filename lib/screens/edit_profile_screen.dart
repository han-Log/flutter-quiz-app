import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

// 내 프로필 정보를 바꾸는 설정 스크린
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

      // 💡 핵심: 성공적으로 수정되었다면 'true'를 가지고 돌아갑니다.
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
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("프로필 수정")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 50,
                );
                if (image != null)
                  setState(() => _newProfileImage = File(image.path));
              },
              child: CircleAvatar(
                radius: 60,
                // [2026-02-22] withValues 적용
                backgroundColor: const Color(0xFF7B61FF).withValues(alpha: 0.1),
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
            const SizedBox(height: 30),
            TextField(controller: _nicknameController),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("완료"),
            ),
          ],
        ),
      ),
    );
  }
}
