import 'package:flutter/material.dart';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_slchess/core/models/match_model.dart';
import 'package:flutter_slchess/core/models/gamestate_model.dart';
import 'package:flutter_slchess/core/services/matchmaking_service.dart';
import 'package:flutter_slchess/core/services/match_ws_service.dart';
import 'package:flutter_slchess/core/services/cognito_auth_service.dart';
import '../widgets/error_dialog.dart';

import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class Chessboard extends StatefulWidget {
  final MatchModel matchModel;
  final bool isOnline;
  final bool isWhite;
  final bool enableSwitchBoard;

  const Chessboard(
      {super.key,
      required this.matchModel,
      required this.isOnline,
      required this.isWhite,
      this.enableSwitchBoard = false});

  @override
  State<Chessboard> createState() => _ChessboardState();
}

class _ChessboardState extends State<Chessboard> {
  // Game state
  chess.Chess game = chess.Chess();
  List<String> listFen = [];
  int halfmove = 0;
  late List<List<String?>> board;
  late String fen;
  bool isWhiteTurn = true;
  bool isPaused = false;
  String? lastMoveFrom;
  String? lastMoveTo;

  // Time control
  late String timeControl;
  late int timeIncrement;
  late int whiteTime;
  late int blackTime;
  late DateTime lastUpdate;
  Timer? timer;
  late Stopwatch _stopwatch;

  // Move validation
  Set<String> validSquares = {};
  List<chess.Move> validMoves = [];
  String? selectedSquare;

  // UI control
  late ScrollController _scrollController;
  late bool isOnline;
  late String server;
  bool enableFlip = true;
  late bool isWhite;

  // Websocket and services
  CognitoAuth cognitoAuth = CognitoAuth();
  late MatchWebsocketService matchService;
  late MatchModel matchModel;

  @override
  void initState() {
    super.initState();
    _initializeGameState();
    _initializeTimeControl();

    if (isOnline) {
      _initializeOnlineGame();
    } else {
      _initializeOfflineGame();
    }

    _initializeUIControls();
    _startClock();
  }

  void _initializeGameState() {
    matchModel = widget.matchModel;
    isWhite = widget.isWhite;
    isOnline = widget.isOnline;
    server = matchModel.server;
  }

  void _initializeTimeControl() {
    timeControl = matchModel.gameMode.split("+")[0];
    timeIncrement = int.parse(matchModel.gameMode.split("+")[1]);
    whiteTime = int.parse(timeControl) * 60 * 1000;
    blackTime = whiteTime;
  }

  void _initializeUIControls() {
    _stopwatch = Stopwatch();
    _scrollController = ScrollController();
    _scrollToBottomAfterBuild();
  }

  void _startClock() {
    _stopwatch.start();
    timer = Timer.periodic(const Duration(milliseconds: 100), _updateClock);
  }

  void _updateClock(Timer t) {
    if (!_stopwatch.isRunning) return;

    final elapsed = _stopwatch.elapsedMilliseconds;
    _stopwatch.reset();
    _stopwatch.start();

    setState(() {
      if (isWhiteTurn) {
        if (halfmove > 0 || isOnline) {
          whiteTime -= elapsed;
          if (whiteTime <= 0) {
            whiteTime = 0;
            t.cancel();
            showGameEndDialog(context, "White loss", "onTime");
          }
        }
      } else {
        blackTime -= elapsed;
        if (blackTime <= 0) {
          blackTime = 0;
          t.cancel();
          showGameEndDialog(context, "Black loss", "onTime");
        }
      }
    });
  }

  Future<void> _initializeOfflineGame() async {
    const fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    listFen.add(fen);
    game.load(fen);
    board = parseFEN(listFen.last);
  }

  Future<void> _initializeOnlineGame() async {
    board =
        parseFEN('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');

    String? storedIdToken = await cognitoAuth.getStoredIdToken();
    matchService = MatchWebsocketService.startGame(
        matchModel.matchId, storedIdToken!, server);

    matchService.listen(
      onGameState: _handleGameStateUpdate,
      onEndgame: _handleGameEnd,
      onStatusChange: _handleStatusChange,
      context: context,
    );
  }

  void _handleGameStateUpdate(GameState gameState) {
    setState(() {
      fen = gameState.fen;
      listFen.add(fen);
      board = parseFEN(fen);
      game.load(fen);
      whiteTime = gameState.clocks[0];
      blackTime = gameState.clocks[1];
      isWhiteTurn = game.turn.name == "WHITE";

      // Kiểm tra xem có nước đi mới từ server không
      if (gameState.lastMove != null) {
        // Nước đi có dạng "e2e4"
        if (gameState.lastMove!.length >= 4) {
          lastMoveFrom = gameState.lastMove!.substring(0, 2);
          lastMoveTo = gameState.lastMove!.substring(2, 4);
        }
      }
    });
  }

  void _handleGameEnd(GameState gameState) {
    final winner = gameState.outcome == "1-0"
        ? "WHITE"
        : gameState.outcome == "0-1"
            ? "BLACK"
            : null;
    showGameEndDialog(context, "$winner WON", gameState.method ?? "Unknown");
  }

  void _handleStatusChange() {
    // Cập nhật UI khi trạng thái người chơi thay đổi
    setState(() {});
  }

  void _scrollToBottomAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void switchTurn() {
    _stopwatch.reset();
    _stopwatch.start();
    setState(() {
      isWhiteTurn = !isWhiteTurn;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _stopwatch.stop();
    _scrollController.dispose();
    super.dispose();
  }

// decoration: const BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage('assets/bg_dark.png'),
//             fit: BoxFit.cover,
//           ),
//         ),
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_dark.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            if (!isOnline) gameHistory(game),
            _buildPlayerPanel(!isWhite),
            handleChessBoard(),
            _buildPlayerPanel(isWhite),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Offline Chess Games',
        style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: const Color(0xFF0E1416),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _showConfirmationDialog(context),
      ),
    );
  }

  Widget _buildPlayerPanel(bool isCurrentPlayer) {
    final playerName = isCurrentPlayer
        ? matchModel.player1.user.username
        : matchModel.player2.user.username;

    final time = formatTime(isCurrentPlayer ? whiteTime : blackTime);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.black87,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.supervised_user_circle,
                  color: Colors.grey.shade300,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  playerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BottomAppBar _buildBottomAppBar() {
    return BottomAppBar(
      color: const Color(0xFF282F33),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _bottomAppBarBtn(
              "Tùy chọn",
              () => _showOptionsMenu(context),
              icon: Icons.storage,
            ),
          ),
          if (!isOnline) ...[
            Expanded(
              child: _bottomAppBarBtn(
                isPaused ? "Tiếp tục" : "Tạm dừng",
                _togglePause,
                icon: isPaused ? Icons.play_arrow : Icons.pause,
              ),
            ),
            Expanded(
              child: _bottomAppBarBtn(
                "Quay lại",
                _moveBackward,
                icon: Icons.arrow_back_ios_new,
              ),
            ),
            Expanded(
              child: _bottomAppBarBtn(
                "Tiếp",
                _moveForward,
                icon: Icons.arrow_forward_ios,
              ),
            ),
          ]
        ],
      ),
    );
  }

  void _togglePause() {
    setState(() {
      if (isPaused) {
        _stopwatch.start();
      } else {
        _stopwatch.stop();
      }
      isPaused = !isPaused;
    });
  }

  void _moveBackward() {
    if (listFen.length > 1) {
      setState(() {
        if (halfmove > 0) {
          halfmove--;
        }
        fen = listFen[halfmove];
        board = parseFEN(fen);
        scrollToIndex(halfmove);
      });
    }
  }

  void _moveForward() {
    if (listFen.length > 1) {
      setState(() {
        if (halfmove < listFen.length - 1) {
          halfmove++;
        }
        fen = listFen[halfmove];
        board = parseFEN(fen);
        scrollToIndex(halfmove);
      });
    }
  }

  Widget handleChessBoard() {
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: 64,
              itemBuilder: (context, index) => _buildChessSquare(index),
            ),
          ),
        ),
        _buildRankCoordinates(),
        _buildFileCoordinates(),
      ],
    );
  }

  Widget _buildChessSquare(int index) {
    int transformedIndex = enableFlip && !isWhite ? 63 - index : index;
    int row = transformedIndex ~/ 8;
    int col = transformedIndex % 8;
    String coor = parsePieceCoordinate(col, row);
    bool isValidSquare = validSquares.contains(coor);
    bool isLastMoveFrom = coor == lastMoveFrom;
    bool isLastMoveTo = coor == lastMoveTo;
    String? piece = board[row][col];

    return DragTarget<String>(
      onWillAcceptWithDetails: (data) => isValidSquare,
      onAcceptWithDetails: (data) => _handleMove(coor),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () => _handleMove(coor),
          child: Container(
            decoration: BoxDecoration(
              color: (row + col) % 2 == 0
                  ? const Color(0xFFEEEED2) // Màu ô trắng
                  : const Color(0xFF769656), // Màu ô xanh
              border: Border.all(
                color: isValidSquare
                    ? Colors.green
                    : isLastMoveFrom || isLastMoveTo
                        ? Colors.blueAccent
                        : Colors.transparent,
                width: isValidSquare || isLastMoveFrom || isLastMoveTo ? 2 : 0,
              ),
              boxShadow: isLastMoveTo
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: _buildDraggablePiece(piece, coor),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankCoordinates() {
    return Positioned.fill(
      child: Column(
        children: List.generate(8, (row) {
          return Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 2, top: 2),
                child: Text(
                  isWhite ? "${8 - row}" : "${row + 1}",
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: (row % 2 == 0) ? Colors.grey : Colors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFileCoordinates() {
    return Positioned.fill(
      child: Row(
        children: List.generate(8, (col) {
          return Expanded(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2, right: 2),
                child: Text(
                  isWhite
                      ? String.fromCharCode(97 + col)
                      : String.fromCharCode(104 - col),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: (col % 2 == 0) ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDraggablePiece(String? piece, String coor) {
    if (piece == null) return const SizedBox.shrink();

    final canDrag = (isWhiteTurn == isWhite || !isOnline) &&
        !isPaused &&
        (piece.toUpperCase() == piece) == isWhiteTurn;

    if (!canDrag) {
      return Image.asset(
        getPieceAsset(piece),
        fit: BoxFit.contain,
      );
    }

    return Draggable<String>(
      data: coor,
      feedback: Image.asset(
        getPieceAsset(piece),
        colorBlendMode: BlendMode.modulate,
      ),
      childWhenDragging: const SizedBox.shrink(),
      onDragStarted: () {
        setState(() {
          selectedSquare = coor;
          validMoves = _genMove(coor, game);
          validSquares = _toSanMove(validMoves).toSet();
        });
      },
      onDragEnd: (details) {
        if (!details.wasAccepted) {
          setState(() {
            selectedSquare = null;
            validSquares = {};
          });
        }
      },
      child: Image.asset(
        getPieceAsset(piece),
        fit: BoxFit.contain,
      ),
    );
  }

  void _handleMove(String coor) {
    // Kiểm tra các điều kiện khi di chuyển
    if (whiteTime <= 0 || blackTime <= 0) {
      return;
    }

    if (isOnline && isWhiteTurn != isWhite) {
      return;
    }

    setState(() {
      if (selectedSquare == null || !validSquares.contains(coor)) {
        // Chọn quân cờ
        selectedSquare = coor;
        validMoves = _genMove(coor, game);
        validSquares = _toSanMove(validMoves).toSet();
      } else if (validSquares.contains(coor)) {
        // Di chuyển quân cờ
        _processMove(coor);
      } else {
        // Reset selection
        selectedSquare = null;
        validSquares = {};
      }
    });
  }

  void _processMove(String coor) {
    chess.Move move = validMoves.firstWhere(
        (m) => m.fromAlgebraic == selectedSquare && m.toAlgebraic == coor);

    bool success = game.move(move);
    if (success) {
      fen = game.fen;
      listFen.add(fen);
      board = parseFEN(fen);

      // Lưu thông tin nước đi gần nhất
      lastMoveFrom = selectedSquare;
      lastMoveTo = coor;

      // Tăng thời gian sau khi di chuyển
      if (isWhiteTurn) {
        whiteTime += timeIncrement * 1000;
      } else {
        blackTime += timeIncrement * 1000;
      }

      _scrollToBottomAfterBuild();
      halfmove = listFen.length - 1;

      String sanMove = move.fromAlgebraic + move.toAlgebraic;

      if (isOnline) {
        matchService.makeMove(sanMove);
      }

      // Đổi lượt
      isWhiteTurn = !isWhiteTurn;

      if (enableFlip && !isOnline) {
        isWhite = !isWhite;
      }

      // Kiểm tra kết thúc ván đấu
      _checkGameEnd();
    }

    // Reset trạng thái lựa chọn
    selectedSquare = null;
    validSquares = {};
  }

  void _checkGameEnd() {
    if (game.game_over) {
      var turnColor = game.turn.name;

      if (game.in_checkmate) {
        showGameEndDialog(context,
            "${turnColor == 'WHITE' ? 'BLACK' : 'WHITE'} WON", "CHECKMATE");
      } else if (game.in_draw) {
        String resultStr;

        if (game.in_stalemate) {
          resultStr = "Stalemate";
        } else if (game.in_threefold_repetition) {
          resultStr = "Repetition";
        } else if (game.insufficient_material) {
          resultStr = "Insufficient material";
        } else {
          resultStr = "Draw";
        }

        showGameEndDialog(context, "Draw", resultStr);
      }
    }
  }

  String getPieceAsset(String piece) {
    switch (piece) {
      case 'r':
        return 'assets/pieces/Chess_rdt60.png';
      case 'n':
        return 'assets/pieces/Chess_ndt60.png';
      case 'b':
        return 'assets/pieces/Chess_bdt60.png';
      case 'q':
        return 'assets/pieces/Chess_qdt60.png';
      case 'k':
        return 'assets/pieces/Chess_kdt60.png';
      case 'p':
        return 'assets/pieces/Chess_pdt60.png';
      case 'R':
        return 'assets/pieces/Chess_rlt60.png';
      case 'N':
        return 'assets/pieces/Chess_nlt60.png';
      case 'B':
        return 'assets/pieces/Chess_blt60.png';
      case 'Q':
        return 'assets/pieces/Chess_qlt60.png';
      case 'K':
        return 'assets/pieces/Chess_klt60.png';
      case 'P':
        return 'assets/pieces/Chess_plt60.png';
      default:
        return '';
    }
  }

  Widget gameHistory(chess.Chess game) {
    List<dynamic> moves = game.getHistory();

    if (moves.isEmpty) {
      return Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: const Text(" ", style: TextStyle(color: Colors.white)),
      );
    }

    List<Widget> formattedMoves = List.generate(
      (moves.length / 2).floor(),
      (index) {
        String moveNumber = "${index + 1}.";
        String firstMove = moves[index * 2];
        String? secondMove =
            index * 2 + 1 < moves.length ? moves[index * 2 + 1] : null;

        return Row(
          children: [
            GestureDetector(
              onTap: () => onMoveSelected(index * 2),
              child: Row(children: [
                Text(
                  moveNumber,
                  style: const TextStyle(color: Colors.white),
                ),
                moveSelect(index * 2 + 1, firstMove),
              ]),
            ),
            if (secondMove != null)
              GestureDetector(
                onTap: () => onMoveSelected(index * 2 + 1),
                child: moveSelect(index * 2 + 2, secondMove),
              ),
            const SizedBox(width: 4),
          ],
        );
      },
    );

    if (moves.length % 2 != 0) {
      formattedMoves.add(GestureDetector(
        onTap: () => onMoveSelected(moves.length - 1),
        child: Row(
          children: [
            Text("${(moves.length / 2).ceil()}. ",
                style: const TextStyle(color: Colors.white)),
            moveSelect(moves.length, moves.last)
          ],
        ),
      ));
    }

    return Container(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        child: Row(children: formattedMoves),
      ),
    );
  }

  Widget moveSelect(int index, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
          bottomLeft: Radius.circular(2),
          bottomRight: Radius.circular(2),
        ),
        color: halfmove == index ? const Color(0xFF666666) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: halfmove == index ? Colors.white : Colors.grey[400],
          fontWeight: halfmove == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  void scrollToIndex(int index) {
    if (index >= 0 && index < listFen.length) {
      double position = index * 50.0;
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.linearToEaseOut,
      );
    }
  }

  String formatTime(int milliseconds) {
    int seconds = (milliseconds ~/ 1000);
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    int remainingMilliseconds = milliseconds % 1000;

    if (milliseconds < 10000) {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')},${(remainingMilliseconds ~/ 100).toString()}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  List<List<String?>> parseFEN(String fen) {
    List<List<String?>> board =
        List.generate(8, (_) => List<String?>.filled(8, null));
    List<String> rows = fen.split('/');

    if (rows.isNotEmpty && rows[0].contains(' ')) {
      rows[0] = rows[0].split(' ')[0];
    }

    for (int i = 0; i < math.min(8, rows.length); i++) {
      String row = rows[i];
      int col = 0;

      for (int j = 0; j < row.length; j++) {
        String char = row[j];

        if (RegExp(r'\d').hasMatch(char)) {
          int emptyCount = int.parse(char);
          col += emptyCount;
        } else {
          if (col < 8) {
            board[i][col] = char;
            col++;
          }
        }
      }
    }

    return board;
  }

  List<String> _toSanMove(List<chess.Move> moves) {
    return moves.map((move) => move.toAlgebraic).toList();
  }

  List<chess.Move> _genMove(String move, chess.Chess game) {
    return game.generate_moves({'square': move});
  }

  String parsePieceCoordinate(int col, int row) {
    const columns = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    row = 8 - row;
    return columns[col] + row.toString();
  }

  void onMoveSelected(int index) {
    if (index < 0 || index >= listFen.length - 1) return;

    setState(() {
      fen = listFen[index + 1];
      board = parseFEN(fen);
      halfmove = index + 1;
    });
  }

  Widget _bottomAppBarBtn(String text, VoidCallback onPressed,
      {IconData? icon}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOnline) ...[
                _buildMenuItem(context, Icons.flag, "Chấp nhận thua", () {
                  Navigator.pop(context);
                  matchService.resign();
                }),
                _buildMenuItem(context, Icons.flag, "Hòa cờ", () {
                  Navigator.pop(context);
                  matchService.offerDraw();
                }),
              ],
              if (!isOnline)
                _buildMenuItem(context, Icons.sync_disabled,
                    "${enableFlip ? "Tắt" : "Bật"} chức năng xoay bàn cờ", () {
                  setState(() {
                    enableFlip = !enableFlip;
                  });
                  Navigator.pop(context);
                }),
              _buildMenuItem(context, Icons.copy, "Sao chép PGN", () {
                // TODO: Implement copy PGN
                Navigator.pop(context);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 28),
      title: Text(text, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Xác nhận"),
          content: const Text("Bạn có chắc chắn muốn hủy ván đấu không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Không"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text("Có"),
            ),
          ],
        );
      },
    );
  }

  void showGameEndDialog(
      BuildContext context, String resultTitle, String resultContent) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 30),
                    Text(
                      resultTitle,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Text(resultContent, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton(context, "Tái đấu", () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    }),
                    _buildButton(context, "Ván cờ mới", () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton(BuildContext context, String text, VoidCallback onPress) {
    return ElevatedButton(
      onPressed: onPress,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[300],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child:
          Text(text, style: const TextStyle(fontSize: 16, color: Colors.black)),
    );
  }
}
