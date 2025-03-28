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
