class GameState {
  final String fen;
  final List<int> clocks;
  final String? outcome;
  final String? method;

  GameState({
    required this.fen,
    required this.clocks,
    this.outcome,
    this.method,
  });

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      fen: json['fen'] as String,
      clocks: List<int>.from(json['clocks']),
      outcome: json['outcome'] as String?,
      method: json['method'] as String?,
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
