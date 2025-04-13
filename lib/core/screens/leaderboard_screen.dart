import 'package:flutter/material.dart';
import '../models/leaderboard_model.dart';
import '../services/leaderboard_service.dart';
import '../services/amplify_auth_service.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/user_ratings_service.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final AmplifyAuthService _authService = AmplifyAuthService();
  final UserService _userService = UserService();
  final UserRatingsService _userRatingsService = UserRatingsService();

  // Dữ liệu cho bảng xếp hạng API
  List<UserRating> _apiRatings = [];
  bool _isLoading = true;
  String? _error;

  // Lưu trữ thông tin người dùng đã tải
  final Map<String, UserModel> _userCache = {};
  String? _idToken;

  @override
  void initState() {
    super.initState();
    _loadApiRatings();
  }

  // Load dữ liệu từ API userRatings
  Future<void> _loadApiRatings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final idToken = await _authService.getIdToken();

      if (idToken == null) {
        setState(() {
          _error = 'Chưa đăng nhập';
          _isLoading = false;
        });
        return;
      }

      _idToken = idToken;

      final result =
          await _userRatingsService.getUserRatings(idToken, limit: 20);

      setState(() {
        _apiRatings = result.items;
        _isLoading = false;
      });

      // Tải thông tin người dùng cho mỗi ID
      _loadUserDetails();
    } catch (e) {
      safePrint('Lỗi khi lấy dữ liệu xếp hạng API: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Tải thông tin người dùng cho mỗi xếp hạng
  Future<void> _loadUserDetails() async {
    if (_idToken == null) return;

    for (var rating in _apiRatings) {
      try {
        // Kiểm tra xem đã tải thông tin người dùng này chưa
        if (!_userCache.containsKey(rating.userId)) {
          final user = await _userService.getUserInfo(rating.userId, _idToken!);
          setState(() {
            _userCache[rating.userId] = user;
          });
        }
      } catch (e) {
        safePrint('Không thể lấy thông tin người dùng ${rating.userId}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bảng Xếp Hạng',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0E1416),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_dark.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _buildRatingsContent(),
      ),
    );
  }

  Widget _buildRatingsContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Lỗi: $_error',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadApiRatings,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_apiRatings.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu xếp hạng',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Column(
      children: [
        _buildApiRatingsHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadApiRatings,
            color: Colors.white,
            backgroundColor: Colors.blue,
            child: ListView.builder(
              itemCount: _apiRatings.length,
              itemBuilder: (context, index) {
                final rating = _apiRatings[index];
                return _buildApiRatingRow(rating, index);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApiRatingsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: const Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              'XH',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Người chơi',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            'Điểm',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiRatingRow(UserRating rating, int index) {
    // Lấy thông tin người dùng từ cache nếu có
    final user = _userCache[rating.userId];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: index % 2 == 0
            ? Colors.black.withOpacity(0.3)
            : Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Xếp hạng
            SizedBox(
              width: 40,
              child: _buildRankWidget(index + 1),
            ),
            const SizedBox(width: 16),

            // Thông tin người dùng
            Expanded(
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: user != null && user.picture.isNotEmpty
                        ? NetworkImage("${user.picture}/small")
                        : null,
                    backgroundColor: Colors.blue.shade700,
                    child: user == null || user.picture.isEmpty
                        ? Text(
                            user?.username.substring(0, 1).toUpperCase() ??
                                rating.userId.substring(0, 2).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Tên người dùng hoặc ID
                  Expanded(
                    child: Text(
                      user?.username ??
                          'ID: ${rating.userId.substring(0, 10)}...',
                      style: const TextStyle(
                        color: Colors.white,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Điểm xếp hạng
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${rating.rating}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankWidget(int rank) {
    if (rank <= 3) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _getRankColor(rank),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getRankColor(rank).withOpacity(0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Text(
      '$rank',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade700; // Vàng
      case 2:
        return Colors.grey.shade400; // Bạc
      case 3:
        return Colors.brown.shade400; // Đồng
      default:
        return Colors.blue.shade700; // Xanh dương
    }
  }
}
