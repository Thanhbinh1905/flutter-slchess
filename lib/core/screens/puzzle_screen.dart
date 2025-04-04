import 'package:flutter/material.dart';
import 'package:flutter_slchess/core/models/puzzle_model.dart';
import 'package:flutter_slchess/core/services/puzzle_service.dart';
import 'package:flutter_slchess/core/services/cognito_auth_service.dart';
import 'package:flutter_slchess/core/widgets/error_dialog.dart';
import 'package:flutter_slchess/core/models/chessboard_model.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  final PuzzleService _puzzleService = PuzzleService();
  final CognitoAuth _cognitoAuth = CognitoAuth();
  List<Puzzle>? _puzzles;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPuzzles();
  }

  Future<void> _loadPuzzles() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final String? idToken = await _cognitoAuth.getStoredIdToken();
      if (idToken == null) {
        throw Exception("Vui lòng đăng nhập lại");
      }

      final Puzzles puzzles =
          await _puzzleService.getPuzzleFromCacheOrApi(idToken);

      setState(() {
        _puzzles = puzzles.puzzles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openPuzzle(Puzzle puzzle) async {
    try {
      final String? idToken = await _cognitoAuth.getStoredIdToken();
      if (idToken == null) {
        throw Exception("Vui lòng đăng nhập lại");
      }

      // Kiểm tra puzzle có đầy đủ thông tin không
      if (puzzle.puzzleId.isEmpty ||
          puzzle.fen.isEmpty ||
          puzzle.moves.isEmpty) {
        throw Exception("Thông tin puzzle không đầy đủ");
      }

      // Chuyển đến màn hình puzzle
      if (!mounted) return;

      // Đảm bảo tất cả các tham số đều không null và truyền dưới dạng Map<String, dynamic>
      final Map<String, dynamic> arguments = <String, dynamic>{
        'puzzle': puzzle,
        'idToken': idToken
      };

      // Kiểm tra lại các giá trị trong arguments
      arguments.forEach((key, value) {
        if (value == null) {
          throw Exception("Giá trị '$key' không được để trống");
        }
      });

      // Đảm bảo arguments không null khi truyền vào pushNamed
      if (arguments.isNotEmpty) {
        // Sử dụng await để đợi kết quả trả về từ màn hình puzzle
        final result = await Navigator.pushNamed(context, '/puzzle_board',
            arguments: Map<String, dynamic>.from(arguments));

        // Nếu có kết quả trả về và kết quả là true (puzzle đã được giải)
        if (result == true) {
          // Làm mới danh sách puzzle
          _loadPuzzles();
        }
      } else {
        throw Exception("Không thể tạo tham số cho màn hình puzzle");
      }
    } catch (e) {
      print("Lỗi khi chuyển đến màn hình puzzle: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: ${e.toString()}")),
        );
      }
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lỗi'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1B1A),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadPuzzles,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_puzzles == null || _puzzles!.isEmpty) {
      return const Center(
        child: Text(
          'Không có puzzle nào',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPuzzles,
      child: ListView.builder(
        itemCount: _puzzles!.length,
        itemBuilder: (context, index) {
          final puzzle = _puzzles![index];
          return _buildPuzzleItem(puzzle);
        },
      ),
    );
  }

  Widget _buildPuzzleItem(Puzzle puzzle) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF2A2B2A),
      child: ListTile(
        title: Text(
          'Puzzle #${puzzle.puzzleId}',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Rating: ${puzzle.rating} | Themes: ${puzzle.themes.join(", ")}',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        onTap: () => _openPuzzle(puzzle),
      ),
    );
  }
}
