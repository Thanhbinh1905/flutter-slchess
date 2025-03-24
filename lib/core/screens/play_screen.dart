import 'package:flutter/material.dart';
import '../constants/constants.dart'; // Đảm bảo import constants
import '../services/matchMaking.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  String? selectedTimeControl; // Biến để lưu trữ giá trị đã chọn

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Column(
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
                // MatchMakingSerice().getQueue(idToken, gameMode, rating);
              },
              items: timeControls
                  .map<DropdownMenuItem<String>>((Map<String, String> control) {
                return DropdownMenuItem<String>(
                  value: control['value'],
                  child: Text(control['key']!),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Xử lý khi nhấn nút play
                if (selectedTimeControl == null ||
                    selectedTimeControl!.isEmpty) {
                  print("isEmpty!");
                  return;
                }
                print("Started queue: $selectedTimeControl");

                Navigator.pushNamed(context, '/matchmaking',
                    arguments: selectedTimeControl);
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
