import 'package:flutter/material.dart';
import 'package:flutter_slchess/core/services/amplify_auth_service.dart';
import 'package:flutter_slchess/core/models/historymatch_model.dart';
import 'package:flutter_slchess/core/screens/analysis_chessboard.dart';
import 'package:intl/intl.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final AmplifyAuthService _authService = AmplifyAuthService();
  bool _isLoading = true;
  List<HistoryMatchModel> _matchHistory = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMatchHistory();
  }

  Future<void> _loadMatchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Mô phỏng việc tải lịch sử trận đấu từ API
      // Trong thực tế, bạn sẽ gọi API để lấy dữ liệu
      await Future.delayed(const Duration(seconds: 1));

      // Ở đây, chúng ta tạo một số dữ liệu giả định
      setState(() {
        _matchHistory = _generateMockMatches();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải lịch sử trận đấu: $e';
        _isLoading = false;
      });
    }
  }

  // Hàm tạo dữ liệu mẫu để hiển thị
  List<HistoryMatchModel> _generateMockMatches() {
    final now = DateTime.now();

    return List.generate(10, (index) {
      final items = List.generate(10 + index, (moveIndex) {
        final playerStates = [
          PlayerState(
            clock: "${5 - moveIndex ~/ 20}m${30 - (moveIndex % 60)}s",
            status: "CONNECTED",
          ),
          PlayerState(
            clock: "${5 - moveIndex ~/ 18}m${45 - (moveIndex % 60)}s",
            status: "CONNECTED",
          ),
        ];

        return HistoryMatchItem(
          id: "item_$moveIndex",
          matchId: "match_$index",
          playerStates: playerStates,
          gameState: "ONGOING",
          move: HistoryMove(
            playerId: moveIndex % 2 == 0 ? "player1" : "player2",
            uci: _getRandomMove(),
          ),
          ply: moveIndex,
          timestamp: now.subtract(Duration(days: index, minutes: moveIndex)),
        );
      });

      return HistoryMatchModel(items: items);
    });
  }

  String _getRandomMove() {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    const ranks = ['1', '2', '3', '4', '5', '6', '7', '8'];

    final fromFile = files[DateTime.now().millisecond % 8];
    final fromRank = ranks[DateTime.now().microsecond % 8];
    final toFile = files[(DateTime.now().millisecond + 3) % 8];
    final toRank = ranks[(DateTime.now().microsecond + 2) % 8];

    return "$fromFile$fromRank$toFile$toRank";
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy - HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_dark.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadMatchHistory,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : SafeArea(child: _buildContent()),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildImportPgnButton(),
          const SizedBox(height: 16),
          _buildAnalysisOptions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phân tích bàn cờ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Phân tích các ván cờ của bạn',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportPgnButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
        onTap: () {
          // TODO: Implement PGN import
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tính năng đang được phát triển')),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.upload_file,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhập PGN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Phân tích ván cờ từ file PGN',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tạo bàn cờ phân tích',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCreateBoardButton(
            title: 'Bàn cờ mới',
            subtitle: 'Bắt đầu từ vị trí chuẩn',
            icon: Icons.add_circle_outline,
            color: Colors.blue.shade700,
            onTap: () => _createNewAnalysisBoard(),
          ),
          const SizedBox(height: 16),
          _buildCreateBoardButton(
            title: 'Nhập FEN',
            subtitle: 'Tạo từ vị trí tùy chỉnh',
            icon: Icons.edit_note,
            color: Colors.green.shade700,
            onTap: () => _showFenInputDialog(),
          ),
          const SizedBox(height: 16),
          _buildCreateBoardButton(
            title: 'Phân tích ván đấu đã chơi',
            subtitle: 'Xem các ván đấu gần đây',
            icon: Icons.history,
            color: Colors.orange.shade700,
            onTap: () => _showHistoryMatchesList(),
          ),
          const SizedBox(
              height: 32), // Thêm khoảng cách dưới cùng để tránh bị cắt
        ],
      ),
    );
  }

  Widget _buildCreateBoardButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _createNewAnalysisBoard() {
    // Tạo một HistoryMatchModel trống với vị trí ban đầu
    final emptyMatch = HistoryMatchModel(items: []);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChessboardAnalysis(
          historyMatch: emptyMatch,
        ),
      ),
    );
  }

  void _showFenInputDialog() {
    final TextEditingController fenController = TextEditingController();
    fenController.text =
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập FEN'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nhập chuỗi FEN để tạo vị trí tùy chỉnh:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fenController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Nhập FEN...',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Tạo một HistoryMatchModel trống với FEN tùy chỉnh
              final fen = fenController.text.trim();
              if (fen.isNotEmpty) {
                final emptyMatch = HistoryMatchModel(items: []);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChessboardAnalysis(
                      historyMatch: emptyMatch,
                      initialFen: fen,
                    ),
                  ),
                );
              }
            },
            child: const Text('Tạo bàn cờ'),
          ),
        ],
      ),
    );
  }

  void _showHistoryMatchesList() {
    // Hiển thị danh sách các ván đấu đã chơi
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng đang được phát triển')),
    );
  }
}
