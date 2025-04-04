import 'package:flutter/material.dart';
import '../services/matchmaking_service.dart';
import '../services/cognito_auth_service.dart';
import '../services/userService.dart';
import '../models/user.dart';
import '../models/chessboard_model.dart';
import '../models/match_model.dart';

class MatchMakingScreen extends StatefulWidget {
  final String gameMode;
  const MatchMakingScreen({super.key, required this.gameMode});

  @override
  State<MatchMakingScreen> createState() => _MatchMakingScreenState();
}

class _MatchMakingScreenState extends State<MatchMakingScreen> {
  late String gameMode;
  bool isQueued = false;

  final MatchMakingSerice matchMakingService = MatchMakingSerice();
  final CognitoAuth cognitoAuth = CognitoAuth();
  final UserService userService = UserService();

  late UserModel? player;
  late ChessboardModel chessboardModel;

  @override
  void initState() {
    super.initState();
    gameMode = widget.gameMode;
    _initializeMatchmaking();
  }

  Future<void> _initializeMatchmaking() async {
    try {
      final String? storedIdToken = await cognitoAuth.getStoredIdToken();
      if (storedIdToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vui lòng đăng nhập lại")),
          );
        }
        return;
      }

      player = await userService.getPlayer();
      if (player == null || !mounted) {
        print("Người chơi không tồn tại hoặc widget đã bị dispose");
        return;
      }

      final double playerRating = player!.rating;

      // Tìm trận đấu
      MatchModel? match;
      while (match == null && mounted) {
        match = await matchMakingService.getQueue(
            storedIdToken, gameMode, playerRating);
        if (match == null) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      if (!mounted) return;

      // Tạo model bàn cờ
      chessboardModel = ChessboardModel(
        match: match!,
        isOnline: true,
        isWhite: matchMakingService.isUserWhite(match, player!),
      );

      if (mounted) {
        setState(() {
          isQueued = true;
        });

        Navigator.popAndPushNamed(context, "/board",
            arguments: chessboardModel);
      }
    } catch (e, stackTrace) {
      print("Lỗi khi khởi tạo matchmaking: $e\n$stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: mainContainer(
        child: Center(
          child: IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Image.asset(
                            'assets/default_avt.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (isQueued) ...[
                        const SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: Image.asset(
                              'assets/weapon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ] else
                        const CircularProgressIndicator(),
                      const SizedBox(width: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Image.asset(
                            'assets/default_avt.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    isQueued ? "Queued" : "Queueing.....",
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Quay lại")),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget mainContainer({Widget? child}) {
  return Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/bg_dark.png"),
        fit: BoxFit.cover,
      ),
    ),
    child: child ?? const Center(),
  );
}
