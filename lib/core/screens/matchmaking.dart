import 'package:flutter/material.dart';
import '../services/matchmaking_service.dart';
import '../services/cognito_auth_service.dart';
import '../services/userService.dart';
import '../models/user.dart';
import '../models/match.dart';

class MatchMakingScreen extends StatefulWidget {
  final String gameMode;
  const MatchMakingScreen({super.key, required this.gameMode});

  @override
  State<MatchMakingScreen> createState() => _MatchMakingScreenState();
}

class _MatchMakingScreenState extends State<MatchMakingScreen> {
  late String gameMode;
  bool isQueued = false;

  MatchMakingSerice matchMakingSerice = MatchMakingSerice();
  CognitoAuth cognitoAuth = CognitoAuth();
  UserService userService = UserService();
  MatchMakingSerice matchMakingService = MatchMakingSerice();

  late UserModel? player;
  late MatchModel? match;

  @override
  void initState() {
    super.initState();
    gameMode = widget.gameMode;
    _initializeMatchmaking();
  }

  Future<void> _initializeMatchmaking() async {
    try {
      // Kiểm tra token không null
      final String? storedIdToken = await cognitoAuth.getStoredIdToken();
      if (storedIdToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vui lòng đăng nhập lại")),
          );
        }
        return;
      }

      // Kiểm tra player không null
      player = await userService.getPlayer();
      if (player == null || !mounted) {
        print("Người chơi không tồn tại hoặc widget đã bị dispose");
        return;
      }

      final double playerRating = player!.rating;

      do {
        match = await matchMakingService.getQueue(
          storedIdToken,
          gameMode,
          playerRating,
        );
        print("match == null : ${match == null}");
        if (match == null && mounted) {
          print("Không tìm thấy trận đấu, đang chờ...");
          await Future.delayed(
              const Duration(seconds: 2)); // Đợi 2 giây trước khi thử lại
        }
      } while (match == null && mounted);

      // Cập nhật state chỉ khi widget còn tồn tại
      setState(() {
        isQueued = true;
        match!
          ..isOnline = true
          ..isWhite = matchMakingService.isUserWhite(match!, player!);
      });

      // Chuyển trang
      Navigator.popAndPushNamed(context, "/board", arguments: match);
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
                      // Avatar User
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25), // Bo góc tròn
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

                      // Avatar Enemy
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
                        Navigator.pop(context); // Quay lại trang trước
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
