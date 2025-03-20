import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/screens/login.dart';
import 'core/screens/homescreen.dart';
import 'core/screens/chessboard.dart';
import 'core/screens/offline_game.dart';
import 'core/screens/matchmaking.dart';

import 'core/models/game.dart';

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
      initialRoute: '/matchmaking',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/board':
            final game = settings.arguments as Game;
            return MaterialPageRoute(
              builder: (context) => Chessboard(game: game),
            );
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/offline_game':
            return MaterialPageRoute(
                builder: (context) => const OfflineGameScreen());
          case '/home':
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          case '/matchmaking':
            return MaterialPageRoute(
                builder: (context) => const MatchMakingScreen());
          default:
            return MaterialPageRoute(builder: (context) => const HomeScreen());
        }
      },
    );
  }
}
