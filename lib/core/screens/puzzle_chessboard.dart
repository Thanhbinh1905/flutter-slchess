import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter_slchess/core/models/puzzle_model.dart';
import 'package:flutter_slchess/core/services/puzzle_service.dart';
import 'dart:math' as math;
import 'dart:async';

class PuzzleChessboard extends StatefulWidget {
  final Puzzle puzzle;
  final String idToken;

  const PuzzleChessboard({
    super.key,
    required this.puzzle,
    required this.idToken,
  });

  @override
  State<PuzzleChessboard> createState() => _PuzzleChessboardState();
}

class _PuzzleChessboardState extends State<PuzzleChessboard> {
  late chess.Chess game;
  late List<List<String?>> board;
  late List<String> solutionMoves;
  int currentMoveIndex = 0;
  bool isPlayerTurn = true;
  bool isPuzzleSolved = false;
  bool isPuzzleFailed = false;
  String? message;

  // Các biến UI
  Set<String> validSquares = {};
  List<chess.Move> validMoves = [];
  String? selectedSquare;
  bool enableFlip = false;
  bool isWhite = true;
  late ScrollController _scrollController;

  // Service
  final PuzzleService _puzzleService = PuzzleService();

  @override
  void initState() {
    super.initState();
    _initializePuzzle();
    _scrollController = ScrollController();

    // Đợi 1 giây sau khi khởi tạo, máy sẽ đi nước đầu tiên
  }

  void _initializePuzzle() {
    game = chess.Chess();

    // Kiểm tra FEN hợp lệ
    if (widget.puzzle.fen.isEmpty) {
      print("Lỗi: FEN trống");
      return;
    }

    game.load(widget.puzzle.fen);

    // Khởi tạo các biến trạng thái
    solutionMoves = widget.puzzle.moves.isEmpty
        ? []
        : List<String>.from(widget.puzzle.moves);
    board = parseFEN(widget.puzzle.fen);
    isWhite = widget.puzzle.fen.contains(' w ');
    isPlayerTurn = false;

    setState(() {
      message = "Đợi máy thực hiện nước đi đầu tiên...";
    });

    // Đợi 1 giây rồi thực hiện nước đi đầu tiên của máy
    Timer(const Duration(seconds: 1), () {
      if (solutionMoves.isNotEmpty) {
        _makeOpponentMove();
      }
    });
  }

  void _handleSquareSelected(String coor) {
    if (!isPlayerTurn || isPuzzleSolved || isPuzzleFailed) return;

    if (selectedSquare == null) {
      // Chọn quân cờ
      final row = 8 - int.parse(coor[1]);
      final col = coor.codeUnitAt(0) - 'a'.codeUnitAt(0);

      if (board[row][col] != null) {
        setState(() {
          selectedSquare = coor;
          validMoves = _genMove(coor, game);
          validSquares = _generateValidSquares(validMoves);
        });
      }
    } else if (selectedSquare == coor) {
      // Bỏ chọn quân cờ
      setState(() {
        selectedSquare = null;
        validSquares = {};
        validMoves = [];
      });
    } else {
      // Di chuyển quân cờ
      _handleMove(coor);
    }
  }

  void _handleMove(String to) {
    if (selectedSquare == null || !isPlayerTurn) return;

    final from = selectedSquare!;

    // Tìm nước đi hợp lệ
    chess.Move? validMove;
    for (var move in validMoves) {
      if (move.fromAlgebraic == from && move.toAlgebraic == to) {
        validMove = move;
        break;
      }
    }

    if (validMove != null) {
      String moveAlgebraic = validMove.fromAlgebraic + validMove.toAlgebraic;

      // Kiểm tra nước đi có đúng với nước đi tiếp theo trong solutionMoves không
      if (currentMoveIndex < solutionMoves.length &&
          moveAlgebraic != solutionMoves[currentMoveIndex]) {
        setState(() {
          message = "Nước đi không chính xác!";
          isPuzzleFailed = true;
          isPlayerTurn = false;
        });
        return;
      }

      _makeMove(validMove);

      setState(() {
        message = "Chính xác!";
        selectedSquare = null;
        validSquares = {};
        validMoves = [];
        isPlayerTurn = false;
        currentMoveIndex++;
      });

      // Kiểm tra xem puzzle đã được giải chưa
      if (currentMoveIndex >= solutionMoves.length) {
        _onPuzzleSolved();
      } else {
        // Thực hiện nước đi của máy sau 1 giây
        Timer(const Duration(milliseconds: 500), _makeOpponentMove);
      }
    }
  }

  String _formatMoveForComparison(String move) {
    // Chuyển đổi nước đi để so sánh với định dạng trong puzzle
    // Ví dụ: "e2e4" -> "e2e4"
    return move;
  }

  void _makeMove(chess.Move move) {
    game.move(move);
    setState(() {
      board = parseFEN(game.fen);
    });
  }

  void _makeOpponentMove() {
    if (currentMoveIndex < solutionMoves.length) {
      final move = solutionMoves[currentMoveIndex];
      final from = move.substring(0, 2);
      final to = move.substring(2, 4);

      // Tìm nước đi hợp lệ
      chess.Move? validMove;
      for (var m in game.generate_moves()) {
        if (m.fromAlgebraic == from && m.toAlgebraic == to) {
          validMove = m;
          break;
        }
      }

      if (validMove != null) {
        _makeMove(validMove);

        setState(() {
          currentMoveIndex++;
          isPlayerTurn = true;
        });

        if (currentMoveIndex >= solutionMoves.length) {
          _onPuzzleSolved();
        }
      }
    }
  }

  void _onPuzzleSolved() {
    setState(() {
      isPuzzleSolved = true;
      message = "Puzzle đã được giải thành công!";
    });

    // Gửi thông báo đến server
    _puzzleService.solvedPuzzle(widget.idToken, widget.puzzle);
  }

  void _resetPuzzle() {
    setState(() {
      _initializePuzzle();
      selectedSquare = null;
      validSquares = {};
      validMoves = [];
      currentMoveIndex = 0;
      isPlayerTurn = true;
      isPuzzleSolved = false;
      isPuzzleFailed = false;
      message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Puzzle #${widget.puzzle.puzzleId}',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0E1416),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFF1A1B1A),
        child: Column(
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFF0E1416),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rating: ${widget.puzzle.rating}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    isPlayerTurn ? 'Lượt của bạn' : 'Đợi máy...',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            // Chessboard
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(2),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                ),
                itemCount: 64,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return _buildChessSquare(index);
                },
              ),
            ),

            // Message
            if (message != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: isPuzzleSolved
                    ? Colors.green.shade800
                    : isPuzzleFailed
                        ? Colors.red.shade800
                        : const Color(0xFF0E1416),
                child: Text(
                  message!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),

            // Actions
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF0E1416),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _resetPuzzle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Thử lại'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (isPuzzleSolved) {
                        Navigator.pop(context, true);
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Gợi ý'),
                            content: Text(
                              'Nước đi đúng là: ${solutionMoves[currentMoveIndex]}',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isPuzzleSolved ? Colors.green : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isPuzzleSolved ? 'Tiếp theo' : 'Gợi ý'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChessSquare(int index) {
    int transformedIndex = enableFlip && !isWhite ? 63 - index : index;
    int row = transformedIndex ~/ 8;
    int col = transformedIndex % 8;
    String coor = parsePieceCoordinate(col, row);
    bool isValidSquare = validSquares.contains(coor);
    String? piece = board[row][col];

    return GestureDetector(
      onTap: () => _handleSquareSelected(coor),
      child: Container(
        decoration: BoxDecoration(
          color: (row + col) % 2 == 0
              ? const Color(0xFFEEEED2) // Màu ô trắng
              : const Color(0xFF769656), // Màu ô xanh
          border: Border.all(
            color: isValidSquare ? Colors.green : Colors.transparent,
            width: isValidSquare ? 2 : 0,
          ),
        ),
        child: Center(
          child: piece != null
              ? Image.asset(getPieceAsset(piece), width: 35, height: 35)
              : null,
        ),
      ),
    );
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

  List<chess.Move> _genMove(String move, chess.Chess game) {
    return game.generate_moves({'square': move});
  }

  Set<String> _generateValidSquares(List<chess.Move> moves) {
    return moves.map((move) => move.toAlgebraic).toSet();
  }

  String parsePieceCoordinate(int col, int row) {
    const columns = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    row = 8 - row;
    return columns[col] + row.toString();
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
}
