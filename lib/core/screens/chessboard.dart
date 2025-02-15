import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;

class Chessboard extends StatefulWidget {
  const Chessboard({super.key});

  @override
  State<Chessboard> createState() => _ChessboardState();
}

class _ChessboardState extends State<Chessboard> {
  late List<List<String?>> board;
  late String fen;
  Set<String> validSquares = {}; // Danh sách các ô hợp lệ
  List<chess.Move> validMoves = [];
  String? selectedSquare; // Ô được chọn ban đầu

  @override
  void initState() {
    super.initState();
    // FEN string: vị trí mở đầu của cờ vua
    fen =
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'; // Đảm bảo FEN có đủ 6 trường
    board = parseFEN(fen);
  }

  /// Hàm parseFEN: chuyển chuỗi FEN thành mảng 2 chiều 8x8
  List<List<String?>> parseFEN(String fen) {
    // Khởi tạo bàn cờ 8x8 với giá trị mặc định là null (ô trống)
    List<List<String?>> board =
        List.generate(8, (_) => List<String?>.filled(8, null));
    // Tách chuỗi FEN theo dấu '/' để lấy từng hàng
    List<String> rows = fen.split('/');

    // Duyệt qua từng hàng (FEN bắt đầu từ hàng trên cùng)
    for (int i = 0; i < 8; i++) {
      String row = rows[i];
      int col = 0;
      // Duyệt từng ký tự trong chuỗi của hàng đó
      for (int j = 0; j < row.length; j++) {
        String char = row[j];
        // Nếu ký tự là số thì nghĩa là có số ô trống liên tiếp
        if (RegExp(r'\d').hasMatch(char)) {
          int emptyCount = int.parse(char);
          col += emptyCount;
        } else {
          // Kiểm tra xem col có nằm trong khoảng hợp lệ không
          if (col < 8) {
            // Nếu ký tự là chữ, đặt quân cờ tương ứng tại ô [i][col]
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

  List<chess.Move> _genMove(String move, String fen) {
    // Khởi tạo đối tượng Chess
    var game = chess.Chess();

    // Thiết lập trạng thái bàn cờ từ FEN
    bool success = game.load(fen);
    if (!success) {
      print("FEN không hợp lệ!");
      return []; // Trả về danh sách rỗng nếu FEN không hợp lệ
    }

    // Lấy danh sách các nước đi hợp lệ
    List<chess.Move> moves = game.generate_moves({'square': move});

    return moves; // Trả về danh sách các nước đi hợp lệ
  }

  /// Hàm chuyển ký hiệu quân cờ thành đường dẫn ảnh
  Widget _buildPiece(String? piece) {
    if (piece == null) return const SizedBox.shrink();

    String assetName = '';
    switch (piece) {
      case 'r':
        assetName = 'assets/pieces/Chess_rdt60.png';
        break;
      case 'n':
        assetName = 'assets/pieces/Chess_ndt60.png';
        break;
      case 'b':
        assetName = 'assets/pieces/Chess_bdt60.png';
        break;
      case 'q':
        assetName = 'assets/pieces/Chess_qdt60.png';
        break;
      case 'k':
        assetName = 'assets/pieces/Chess_kdt60.png';
        break;
      case 'p':
        assetName = 'assets/pieces/Chess_pdt60.png';
        break;
      case 'R':
        assetName = 'assets/pieces/Chess_rlt60.png';
        break;
      case 'N':
        assetName = 'assets/pieces/Chess_nlt60.png';
        break;
      case 'B':
        assetName = 'assets/pieces/Chess_blt60.png';
        break;
      case 'Q':
        assetName = 'assets/pieces/Chess_qlt60.png';
        break;
      case 'K':
        assetName = 'assets/pieces/Chess_klt60.png';
        break;
      case 'P':
        assetName = 'assets/pieces/Chess_plt60.png';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Image.asset(
      assetName,
      fit: BoxFit.contain,
    );
  }

  String parsePieceCoordinate(int col, int row) {
    const columns = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    row = 8 - row;
    return columns[col] + row.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Board with Images'),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: 64,
            itemBuilder: (context, index) {
              int row = index ~/ 8;
              int col = index % 8;
              String coor = parsePieceCoordinate(col, row);

              // Kiểm tra xem ô hiện tại có nằm trong danh sách ô hợp lệ không
              bool isValidSquare = validSquares.contains(coor);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selectedSquare == null ||
                        !validSquares.contains(coor)) {
                      // Nếu chưa chọn ô nào, lấy các nước đi hợp lệ từ ô hiện tại
                      selectedSquare = coor;
                      validMoves = _genMove(coor, fen);
                      validSquares = _toSanMove(validMoves)
                          .map((move) => move.replaceAll(RegExp(r'[+#!?]'),
                              '')) // Loại bỏ ký hiệu đặc biệt
                          .map((move) => move
                              .substring(move.length - 2)) // Lấy 2 ký tự cuối
                          .toSet();
                    } else if (validSquares.contains(coor)) {
                      // print("bat dau di chuyebn");
                      // print(selectedSquare);
                      // print(coor);
                      // Nếu ô hiện tại là ô hợp lệ, thực hiện di chuyển
                      var game = chess.Chess();
                      game.load(fen);
                      chess.Move move = validMoves.firstWhere((m) =>
                          m.fromAlgebraic == selectedSquare &&
                          m.toAlgebraic == coor);

                      bool success = game.move(move);
                      if (success) {
                        // Cập nhật FEN và bàn cờ
                        fen = game.fen;
                        board = parseFEN(fen);
                      }
                      // Đặt lại trạng thái
                      selectedSquare = null;
                      validSquares = {};
                      // print(game.ascii);
                      if (game.game_over) {
                        print("Game over");
                        var turnColor = game.turn;
                        if (game.in_checkmate) {
                          print("$turnColor CHECKMATE");
                        } else if (game.in_draw) {
                          late String resultStr;
                          if (game.in_stalemate) {
                            resultStr = "Stalemate";
                          } else if (game.in_threefold_repetition) {
                            resultStr = "Repetition";
                          } else if (game.insufficient_material) {
                            resultStr = "Insufficient material";
                          }
                          print(resultStr);
                        }
                        String pgn = game.pgn();
                        print(pgn);
                      }
                    } else {
                      // Nếu nhấn vào ô không hợp lệ, đặt lại trạng thái
                      selectedSquare = null;
                      validSquares = {};
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: (row + col) % 2 == 0 ? Colors.white : Colors.grey,
                    border: Border.all(
                      color: isValidSquare ? Colors.green : Colors.black12,
                      width: isValidSquare ? 3 : 1,
                    ),
                  ),
                  child: Center(
                    // Sử dụng _buildPiece để hiển thị ảnh thay vì chữ
                    child: _buildPiece(board[row][col]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
