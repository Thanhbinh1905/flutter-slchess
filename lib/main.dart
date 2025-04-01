import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_slchess/core/models/chessboard_model.dart';
import 'package:flutter_slchess/core/services/cognito_auth_service.dart';
import 'core/screens/login.dart';
import 'core/screens/homescreen.dart';
import 'core/screens/chessboard.dart';
import 'core/screens/offline_game.dart';
import 'core/screens/matchmaking.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // if (kIsWeb) {
  //   await handleWebCallback(); // Chờ xử lý callback trước khi chạy app
  // }

  runApp(const MyApp());
}

Future<void> handleWebCallback() async {
  final uri = Uri.base;
  final code = uri.queryParameters['code'];
  if (code != null) {
    await CognitoAuth().getToken(code); // Đợi lấy token xong
  }
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
