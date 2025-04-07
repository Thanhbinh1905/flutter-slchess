import 'package:flutter/material.dart';
import '../constants/constants.dart'; // Đảm bảo import constants
import '../services/user_service.dart';
import '../models/user.dart';
import 'package:flutter_slchess/core/services/amplify_auth_service.dart';
import '../screens/matchmaking.dart';
import '../screens/puzzle_screen.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  String? selectedTimeControl; // Biến để lưu trữ giá trị đã chọn
  final UserService _userService = UserService();
  final AmplifyAuthService _amplifyAuthService = AmplifyAuthService();
  UserModel? _user;
  bool _isLoading = false;

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
      final user = await _userService.getPlayer();

      if (user == null) {
        final String? accessToken = await _amplifyAuthService.getAccessToken();
        final String? idToken = await _amplifyAuthService.getIdToken();

        if (accessToken != null && idToken != null) {
          await _userService.saveSelfUserInfo(accessToken, idToken);
          final refreshedUser = await _userService.getPlayer();
          if (!mounted) return;
          setState(() {
            _user = refreshedUser;
            _isLoading = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi khi tải thông tin người dùng: $e");
      if (!mounted) return;
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
