import 'package:flutter/material.dart';
import '../constants/constants.dart'; // Đảm bảo import constants
import '../services/matchmaking_service.dart';
import '../services/userService.dart';
import '../models/user.dart';
import '../services/cognito_auth_service.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  String? selectedTimeControl; // Biến để lưu trữ giá trị đã chọn
  final UserService _userService = UserService();
  final CognitoAuth _cognitoAuth = CognitoAuth();
  UserModel? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _userService.getPlayer();

      if (user == null) {
        final String? accessToken = await _cognitoAuth.getStoredAccessToken();
        final String? idToken = await _cognitoAuth.getStoredIdToken();

        if (accessToken != null && idToken != null) {
          await _userService.saveSelfUserInfo(accessToken, idToken);
          final refreshedUser = await _userService.getPlayer();
          setState(() {
            _user = refreshedUser;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi khi tải thông tin người dùng: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Play Screen', style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    hint: const Text('Chọn thời gian chơi'),
                    value: selectedTimeControl,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedTimeControl = newValue;
                      });

                      print(selectedTimeControl);
                    },
                    items: timeControls.map<DropdownMenuItem<String>>(
                        (Map<String, String> control) {
                      return DropdownMenuItem<String>(
                        value: control['value'],
                        child: Text(control['key']!),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _user == null
                        ? null
                        : () {
                            if (selectedTimeControl == null ||
                                selectedTimeControl!.isEmpty) {
                              print("isEmpty!");
                              return;
                            }
                            print("Started queue: $selectedTimeControl");

                            Navigator.pushNamed(
                              context,
                              '/matchmaking',
                              arguments: {
                                'gameMode': selectedTimeControl,
                                'user': _user
                              },
                            );
                          },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play Now'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/offline_game');
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play Offline'),
                  ),
                ],
              ),
      ),
    );
  }
}
