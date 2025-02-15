import 'player.dart';

enum GameStatus { active, completed, abandoned }

enum Result { DRAW, WHITE_CHECKMATE, BLACK_CHECKMATE, TIMEOUT }

class Game {
  final String id;
  final Player whitePlayer;
  final Player blackPlayer;
  final DateTime startTime;
  DateTime? endTime;
  GameStatus status;
  String? winner;
  List<String> moves;

  Game({
    required this.id,
    required this.whitePlayer,
    required this.blackPlayer,
    required this.startTime,
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
