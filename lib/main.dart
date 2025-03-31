import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_slchess/core/models/chessboard_model.dart';
import 'core/screens/login.dart';
import 'core/screens/homescreen.dart';
import 'core/screens/chessboard.dart';
import 'core/screens/offline_game.dart';
import 'core/screens/matchmaking.dart';

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
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/board':
            final args = settings.arguments as ChessboardModel;
            return MaterialPageRoute(
              builder: (context) => Chessboard(
                matchModel: args.match,
                isOnline: args.isOnline,
                isWhite: args.isWhite,
              ),
            );
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/offline_game':
            return MaterialPageRoute(
                builder: (context) => const OfflineGameScreen());
          case '/home':
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          case '/matchmaking':
            final gameMode = settings.arguments as String;
            return MaterialPageRoute(
                builder: (context) => MatchMakingScreen(gameMode: gameMode));
          default:
            return MaterialPageRoute(builder: (context) => const HomeScreen());
        }
      },
    );
  }
}
