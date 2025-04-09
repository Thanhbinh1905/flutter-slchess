import 'package:flutter/material.dart';
import 'package:flutter_slchess/core/models/user.dart';
import 'package:flutter_slchess/core/services/amplify_auth_service.dart';
import 'package:flutter_slchess/core/services/user_service.dart';
import 'package:flutter_slchess/core/services/matchresult_service.dart';
import 'package:flutter_slchess/core/models/matchresults_model.dart';
import 'dart:io';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  final MatchResultService _matchResultService = MatchResultService();
  final AmplifyAuthService _authService = AmplifyAuthService();
  UserModel? _user;
  MatchResultsModel? _matchResults;
  bool _isLoading = true;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print("Đang tải thông tin người dùng...");

      final user = await _userService.getPlayer();
      print(
          "Kết quả lấy người dùng: ${user != null ? 'Thành công' : 'Không có dữ liệu'}");

      if (user == null) {
        print("Không tìm thấy user trong Hive, thử lấy từ API...");
        final String? accessToken = await _authService.getAccessToken();
        final String? idToken = await _authService.getIdToken();

        if (accessToken != null && idToken != null) {
          await _userService.saveSelfUserInfo(accessToken, idToken);
          final refreshedUser = await _userService.getPlayer();
          if (!mounted) return;
          setState(() {
            _user = refreshedUser;
            _isLoading = false;
          });
        } else {
          throw Exception("Không thể lấy token đăng nhập");
        }
      } else {
        if (!mounted) return;
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }

      // Load match history
      if (_user != null) {
        final String? idToken = await _authService.getIdToken();
        if (idToken != null) {
          final results =
              await _matchResultService.getMatchResults(_user!.id, idToken);
          if (!mounted) return;
          setState(() {
            _matchResults = results;
          });
        }
      }
    } catch (e) {
      print("Lỗi chi tiết khi tải thông tin người dùng: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải thông tin người dùng: $e')),
        );
      }
    }
  }

  Future<void> _selectImage() async {
    // Điều hướng đến màn hình upload ảnh
    await Navigator.pushNamed(context, '/uploadImage');
    // Sau khi trở về từ màn hình upload, tải lại thông tin người dùng
    await _loadUserData();
  }

  void _logout() async {
    try {
      await _authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đăng xuất: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thông tin cá nhân')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Không thể tải thông tin người dùng'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        backgroundColor: const Color(0xFF0E1416),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _selectImage,
            tooltip: 'Cài đặt tài khoản',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_dark.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phần avatar và thông tin cơ bản
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _selectImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: _user!.picture.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Image.network(
                                      "${_user!.picture}/large",
                                      key: ValueKey(DateTime.now()
                                          .millisecondsSinceEpoch),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        print('Error loading image: $error');
                                        return const Icon(
                                          Icons.person,
                                          size: 80,
                                          color: Colors.white,
                                        );
                                      },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _user!.username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _user!.membership == Membership.premium
                            ? Colors.amber.withOpacity(0.8)
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _user!.membership == Membership.premium
                            ? 'Thành viên Premium'
                            : 'Thành viên thường',
                        style: TextStyle(
                          color: _user!.membership == Membership.premium
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Thông tin chi tiết
              _buildInfoSection('Thông tin chi tiết'),
              _buildInfoItem('Tên người dùng', _user!.username),
              _buildInfoItem('Vị trí',
                  _user!.locate.isEmpty ? 'Chưa cập nhật' : _user!.locate),
              _buildInfoItem('Rating', _user!.rating.toStringAsFixed(0)),
              _buildInfoItem(
                  'Ngày tạo tài khoản', _formatDate(_user!.createAt)),

              const SizedBox(height: 24),

              // Nút nâng cấp
              if (_user!.membership != Membership.premium)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Xử lý nâng cấp lên Premium
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Chức năng đang phát triển')),
                      );
                    },
                    icon: const Icon(Icons.upgrade),
                    label: const Text('Nâng cấp lên Premium'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Thêm phần lịch sử trận đấu
              _buildMatchHistory(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(
      String title, String description, IconData icon, bool unlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked
            ? Colors.blue.withOpacity(0.2)
            : Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: unlocked ? Border.all(color: Colors.blue, width: 1) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: unlocked ? Colors.blue : Colors.grey.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: unlocked ? Colors.blue : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: unlocked ? Colors.white : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            unlocked ? Icons.check_circle : Icons.lock,
            color: unlocked ? Colors.blue : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHistory() {
    if (_matchResults == null || _matchResults!.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Chưa có lịch sử trận đấu',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoSection('Lịch sử trận đấu gần đây'),
        ..._matchResults!.items.take(5).map((match) => _buildMatchItem(match)),
      ],
    );
  }

  Widget _buildMatchItem(MatchResultItem match) {
    final resultText = match.result == 1
        ? 'Thắng'
        : match.result == 0.5
            ? 'Hòa'
            : 'Thua';
    final resultColor = match.result == 1
        ? Colors.green
        : match.result == 0.5
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundImage: match.opponentId.isNotEmpty
                  ? NetworkImage(
                      "https://slchess-dev-avatars.s3.ap-southeast-2.amazonaws.com/${match.opponentId}/small")
                  : const AssetImage('assets/default_avt.jpg') as ImageProvider,
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rating: ${match.opponentRating.toInt()}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatDate(DateTime.parse(match.timestamp)),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  resultText,
                  style: TextStyle(
                    color: resultColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.analytics, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
