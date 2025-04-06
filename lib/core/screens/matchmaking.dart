import 'package:flutter/material.dart';
import '../services/matchmaking_service.dart';
import '../services/cognito_auth_service.dart';
import '../services/userService.dart';
import '../models/user.dart';
import '../models/chessboard_model.dart';
import '../models/match_model.dart';

class MatchMakingScreen extends StatefulWidget {
  final String gameMode;
  final UserModel? user;

  const MatchMakingScreen({
    super.key,
    required this.gameMode,
    this.user,
  });

  @override
  State<MatchMakingScreen> createState() => _MatchMakingScreenState();
}

class _MatchMakingScreenState extends State<MatchMakingScreen> {
  late String gameMode;
  bool isQueued = false;

  final MatchMakingSerice matchMakingService = MatchMakingSerice();
  final CognitoAuth cognitoAuth = CognitoAuth();
  final UserService userService = UserService();

  UserModel? _user;
  late ChessboardModel chessboardModel;
  UserModel? opponent;

  @override
  void initState() {
    super.initState();
    gameMode = widget.gameMode;
    _user = widget.user;
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

      // Chỉ tải user nếu chưa được truyền vào
      if (_user == null) {
        _user = await userService.getPlayer();

        if (_user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Không thể tìm thấy thông tin người dùng")),
            );
            Navigator.pop(context);
          }
          return;
        }
      }

      print("User info: ${_user!.toJson()}");
      if (!mounted) {
        print("Widget đã bị dispose");
        return;
      }

      final double userRating = _user!.rating;

      // Tìm trận đấu
      MatchModel? match;
      try {
        match = await matchMakingService.getQueue(
            storedIdToken, gameMode, userRating);

        if (match == null) {
          print("Không thể tìm trận đấu phù hợp");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Không thể tìm trận đấu phù hợp")),
            );
            Navigator.pop(context);
          }
          return;
        }

        // Lấy thông tin đối thủ
        try {
          opponent = match.player1.user.id == _user!.id
              ? await userService.getUserInfo(
                  match.player2.user.id, storedIdToken)
              : await userService.getUserInfo(
                  match.player1.user.id, storedIdToken);
        } catch (e) {
          print("Lỗi khi lấy thông tin đối thủ: $e");
          // Tiếp tục với thông tin đối thủ cơ bản từ match
          opponent = match.player1.user.id == _user!.id
              ? match.player2.user
              : match.player1.user;
        }

        if (!mounted) return;

        // Tạo model bàn cờ dù có thông tin đối thủ đầy đủ hay không
        chessboardModel = ChessboardModel(
          match: match,
          isOnline: true,
          isWhite: matchMakingService.isUserWhite(match, _user!),
        );

        if (mounted) {
          setState(() {
            isQueued = true;
          });

          Navigator.popAndPushNamed(context, "/board",
              arguments: chessboardModel);
        }
      } catch (e, stackTrace) {
        print("Lỗi khi tìm trận đấu: $e\n$stackTrace");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi tìm trận: ${e.toString()}")),
          );
          Navigator.pop(context);
        }
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
                      if (_user != null)
                        buildUserAvatar(_user!)
                      else
                        const CircularProgressIndicator(),
                      const SizedBox(width: 10),
                      if (isQueued && opponent != null) ...[
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
                        buildUserAvatar(opponent!),
                      ] else ...[
                        const CircularProgressIndicator(),
                        const SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: const SizedBox(
                            width: 50,
                            height: 50,
                            child: Image(
                              image: AssetImage('assets/default_avt.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
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
                    child: const Text("Quay lại"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildUserAvatar(UserModel user) {
  return Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(0.1),
      border: Border.all(color: Colors.white, width: 2),
      image: user.picture.isNotEmpty
          ? DecorationImage(
              image: NetworkImage("${user.picture}/large"),
              fit: BoxFit.cover,
            )
          : const DecorationImage(
              image: AssetImage('assets/default_avt.jpg'),
              fit: BoxFit.cover,
            ),
    ),
  );
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
