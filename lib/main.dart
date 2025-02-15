import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/screens/login.dart';
import 'core/screens/homescreen.dart';
import 'core/screens/chessboard.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Đảm bảo binding được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // Đảm bảo các plugin được load trước khi chạy app
  await Future.wait([
    dotenv.load(fileName: ".env"),
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/board',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/board': (context) => const Chessboard()
      },
    );
  }
}
