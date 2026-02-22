import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/sign_screens/login_screen.dart';
import 'screens/quiz_home_screen.dart';
import 'screens/main_screen.dart'; // 💡 MainScreen 임포트 추가

void main() async {
  // .env 파일 로드
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  // 파이어베이스 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Quiz App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),

      // 1. 초기 화면 설정 (로그인 상태 감시)
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 연결 상태 확인 중일 때
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 💡 로그인 데이터(snapshot.hasData)가 있으면 MainScreen으로 보냅니다.
          if (snapshot.hasData) {
            return const MainScreen();
          } else {
            // 로그인 데이터가 없으면 로그인 화면으로 보냅니다.
            return const LoginScreen();
          }
        },
      ),

      // 2. Named Routes 등록
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainScreen(), // 💡 메인 경로 등록
        '/home': (context) => const QuizHomeScreen(),
      },
    );
  }
}
