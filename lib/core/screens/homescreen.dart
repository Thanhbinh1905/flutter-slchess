import 'package:flutter/material.dart';
import '../services/cognito_auth.dart';
import 'play_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CognitoAuth _cognitoAuth = CognitoAuth();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SLChess'),
          actions: const [
            // IconButton(
            //   icon: const Icon(Icons.logout),
            //   onPressed: () async {
            //     await _cognitoAuth.clearTokens();
            //     if (context.mounted) {
            //       Navigator.pushReplacementNamed(context, '/login');
            //     }
            //   },
            // ),
          ],
        ),
        body: const TabBarView(
          children: [
            PlayPage(),
            Center(child: Text('Puzzles Screen')),
            Center(child: Text('Leaderboards Screen')),
            Center(child: Text('Settings Screen')),
          ],
        ),
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.play_arrow), text: "Play"),
            Tab(icon: Icon(Icons.extension), text: "Puzzles"),
            Tab(icon: Icon(Icons.leaderboard), text: "Leaderboards"),
            Tab(icon: Icon(Icons.settings), text: "Settings"),
          ],
        ),
      ),
    );
  }
}
