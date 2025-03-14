import 'package:flutter/material.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Play Screen', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Xử lý khi nhấn nút play
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
