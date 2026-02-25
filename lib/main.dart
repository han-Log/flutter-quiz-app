import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

// 화면 임포트
import 'screens/sign_screens/login_screen.dart';
import 'screens/WelcomeScreen.dart';
import 'screens/quiz_home_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("⚠️ .env 로드 실패: $e");
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '상식 수족관', // 앱 타이틀 수정
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.notoSansKrTextTheme(Theme.of(context).textTheme),
      ),

      // 1. 초기 화면 설정 (StreamBuilder 로직 수정)
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            // ✅ 로그인이 되어 있으면 메인 수족관으로!
            return const MainScreen();
          } else {
            // ✅ 로그인이 안 되어 있으면 '현관문'인 웰컴 스크린으로!
            return const WelcomeScreen();
          }
        },
      ),

      // 2. Named Routes 등록 (경로 유지 및 웰컴 추가)
      getPages: [
        GetPage(
          name: '/welcome',
          page: () => const WelcomeScreen(),
        ), // 웰컴 경로 추가
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/main', page: () => const MainScreen()),
        GetPage(name: '/home', page: () => const QuizHomeScreen()),
      ],
    );
  }
}
