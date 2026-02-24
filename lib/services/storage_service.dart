import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

// Goole Storage 저장과 관련된 시스템
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfileImage(File imageFile, String uid) async {
    try {
      // 💡 해결책: 폴더 구조를 명확한 문자열 경로로 생성합니다.
      // .ref('profile_images/$uid.jpg') 형식이 가장 에러가 적습니다.
      final Reference ref = _storage.ref('profile_images/$uid.jpg');

      debugPrint("🚀 업로드 시도 경로: ${ref.fullPath}");

      // 파일 업로드 (Metadata를 추가하여 브라우저에서 바로 보이도록 설정)
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // 완료 대기
      final TaskSnapshot snapshot = await uploadTask;

      // 다운로드 URL 가져오기
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint("✅ Storage 업로드 성공: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      // 💡 여기서 에러가 난다면 Firebase 콘솔에서 Storage 탭을 한 번 눌러서 활성화했는지 확인하세요.
      debugPrint("❌ Storage 업로드 에러 상세: $e");
      return null;
    }
  }
}
