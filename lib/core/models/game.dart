import 'player.dart';

enum GameStatus { active, completed, abandoned }

enum Result { DRAW, WHITE_CHECKMATE, BLACK_CHECKMATE, TIMEOUT }

class Game {
  final String id;
  final Player whitePlayer;
  final Player blackPlayer;
  final DateTime startTime;
  final String timeControl;
  final bool isOnline;
  DateTime? endTime;
  GameStatus status;
  String? winner;
  List<String> moves;

  Game({
    required this.id,
    required this.whitePlayer,
    required this.blackPlayer,
    required this.startTime,
    required this.isOnline,
    required this.timeControl,
    this.endTime,
    this.status = GameStatus.active,
    this.winner,
    this.moves = const [],
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      whitePlayer: Player.fromJson(json['whitePlayer']),
      blackPlayer: Player.fromJson(json['blackPlayer']),
      isOnline: json['isOnline'] ?? false,
      timeControl: json['timeControl'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      status: GameStatus.values.byName(json['status']),
      winner: json['winner'],
      moves: List<String>.from(json['moves']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'whitePlayer': whitePlayer.toJson(),
      'blackPlayer': blackPlayer.toJson(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status.name,
      'winner': winner,
      'moves': moves,
    };
  }
}

// {
//   "matchId": "a418b2c9-bccd-49b7-a646-536061113ddf",
//   "players": [
//     {
//       "id": "199e84a8-6031-70c7-efe5-89fdf66ba8a6",
//       "rating": 1200.2,
//       "newRatings": [
//         200,
//         200,
//         200
//       ]
//     },
//     {
//       "id": "199e84a8-6031-70c7-efe5-89fdf66ba8a6",
//       "rating": 1200.2,
//       "newRatings": [
//         200,
//         200,
//         200
//       ]
//     }
//   ],
//   "pgn": "e2e4 e7e5 d1h5 b8c6 f1c4 g8f6 d1f7",
//   "startedAt": "2025-02-20T04:25:37.975024301Z",
//   "endedAt": "2025-02-20T04:25:37.975024301Z"
// }