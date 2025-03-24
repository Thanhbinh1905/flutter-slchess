import 'player.dart';

class MatchModel {
  final String matchId;
  final Player player1;
  final Player player2;
  final String gameMode;
  final String server;
  final DateTime createdAt;
  bool isOnline;

  MatchModel(
      {required this.matchId,
      required this.player1,
      required this.player2,
      required this.gameMode,
      required this.server,
      required this.createdAt,
      this.isOnline = false});

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      matchId: json['matchId'],
      player1: Player.fromJson(json['player1']),
      player2: Player.fromJson(json['player2']),
      gameMode: json['gameMode'],
      server: json['server'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'player1': player1.toJson(),
      'player2': player2.toJson(),
      'gameMode': gameMode,
      'server': server,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
