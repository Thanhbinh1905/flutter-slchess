import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import '../services/friendship_service.dart';
import '../services/amplify_auth_service.dart';
import '../services/user_service.dart';
import '../models/friendship_model.dart';
import '../models/user.dart';
import '../widgets/widgets.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FriendshipService _friendshipService = FriendshipService();
  final AmplifyAuthService _authService = AmplifyAuthService();
  final UserService _userService = UserService();
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  FriendshipModel? _friendshipList;
  final Map<String, UserModel> _friendUsers = {};

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final idToken = await _authService.getIdToken();
      if (idToken == null) {
        throw Exception('Không thể lấy token xác thực');
      }

      final friends = await _friendshipService.getFriendshipList(idToken);

      // Load thông tin chi tiết của từng người bạn
      for (var friend in friends.items) {
        try {
          final userInfo =
              await _userService.getUserInfo(friend.friendId, idToken);
          _friendUsers[friend.friendId] = userInfo;
        } catch (e) {
          print('Lỗi khi lấy thông tin người dùng ${friend.friendId}: $e');
        }
      }

      setState(() {
        _friendshipList = friends;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddFriendDialog() {
    final TextEditingController friendIdController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm bạn'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: friendIdController,
                decoration: const InputDecoration(
                  labelText: 'Nhập ID người dùng',
                  hintText: 'Ví dụ: 123456',
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (friendIdController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập ID người dùng'),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isLoading = true;
                      });

                      try {
                        final idToken = await _authService.getIdToken();
                        if (idToken == null) {
                          throw Exception('Không thể lấy token xác thực');
                        }

                        final result = await _friendshipService.addFriend(
                          idToken,
                          friendIdController.text.trim(),
                        );

                        print(result);

                        if (mounted) {
                          Navigator.pop(context);
                          if (result == 200) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã gửi lời mời kết bạn'),
                              ),
                            );
                          } else if (result == 409) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Không thể tự kết bạn'),
                              ),
                            );
                          }
                          // _loadFriends(); // Tải lại danh sách bạn bè
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Gửi lời mời'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/bg_dark.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, top: 16.0, bottom: 16.0, right: 8.0),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm bạn bè...',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  iconSize: 24,
                  onPressed: _showAddFriendDialog,
                  tooltip: 'Thêm bạn',
                ),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Lỗi: $_error',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadFriends,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _friendshipList == null || _friendshipList!.items.isEmpty
                        ? const Center(
                            child: Text(
                              'Chưa có bạn bè nào',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _friendshipList!.items.length,
                            itemBuilder: (context, index) {
                              final friend = _friendshipList!.items[index];
                              final userInfo = _friendUsers[friend.friendId];
                              final userName =
                                  userInfo?.username ?? 'Đang tải...';
                              print(userInfo?.toJson());

                              if (_searchQuery.isNotEmpty &&
                                  !userName
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase())) {
                                return const SizedBox.shrink();
                              }

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: Avatar(userInfo!.picture),
                                  title: Text(
                                    userName,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    'Rating: ${userInfo.rating.toStringAsFixed(0) ?? '...'}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.message,
                                        color: Colors.white),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                              friend: userInfo,
                                              conversationId:
                                                  friend.conversationId),
                                        ),
                                      );
                                    },
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProfileScreen(user: userInfo),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
