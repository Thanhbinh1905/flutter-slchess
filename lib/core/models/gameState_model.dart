class GameStateModel {
  final String outcome;
  final String method;
  final String fen;
  final List<int> clocks;

  GameStateModel({
    required this.outcome,
    required this.method,
    required this.fen,
    required this.clocks,
  });

  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    return GameStateModel(
      outcome: json['game']['outcome'],
      method: json['game']['method'],
      fen: json['game']['fen'],
      clocks: List<int>.from(json['game']['clocks'].map((clock) {
        final parts = clock.split('m');
        if (parts.length == 2) {
          final minutes = int.parse(parts[0]);
          final seconds = double.parse(parts[1].replaceAll('s', ''));
          return (minutes * 60 * 1000 + (seconds * 1000)).toInt();
        } else {
          final seconds = double.parse(parts[0].replaceAll('s', ''));
          return (seconds * 1000).toInt();
        }
      })),
    );
  }
}

enum Status { CONNECTED, DISCONNECTED }

class PlayerStateModel {
  final String id;
  final Status status;

  PlayerStateModel({
    required this.id,
    required this.status,
  });

  factory PlayerStateModel.fromJson(Map<String, dynamic> json) {
    return PlayerStateModel(
      id: json['id'],
      status: Status.values.byName(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.name.toLowerCase(),
    };
  }
}

void main() {
  var json = {
    "type": "gameState",
    "game": {
      "outcome": "*",
      "method": "NoMethod",
      "fen": "rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq d3 0 1",
      "clocks": ["9m53.619414155s", "10m0s"]
    }
  };

  print(json.runtimeType);
}
