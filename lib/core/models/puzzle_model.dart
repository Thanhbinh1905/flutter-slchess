class Puzzles {
  final List<Puzzle> puzzles;

  Puzzles({
    required this.puzzles,
  });

  factory Puzzles.fromJson(Map<String, dynamic> json) {
    return Puzzles(
      puzzles: List<Puzzle>.from(
          json['items'].map((puzzle) => Puzzle.fromJson(puzzle))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': puzzles.map((puzzle) => puzzle.toJson()).toList(),
    };
  }
}

class Puzzle {
  final String puzzleId;
  final String fen;
  final List<String> moves;
  final int rating;
  final int ratingDeviation;
  final int popularity;
  final int nbPlays;
  final List<String> themes;
  final String gameUrl;

  Puzzle({
    required this.puzzleId,
    required this.fen,
    required this.moves,
    required this.rating,
    required this.ratingDeviation,
    required this.popularity,
    required this.nbPlays,
    required this.themes,
    required this.gameUrl,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      puzzleId: json['puzzleid'],
      fen: json['fen'],
      moves: json['moves'].split(' '),
      rating: json['rating'],
      ratingDeviation: json['ratingdeviation'],
      popularity: json['popularity'],
      nbPlays: json['nbplays'],
      themes: List<String>.from(json['themes'].split(' ')),
      gameUrl: json['gameurl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'puzzleid': puzzleId,
      'fen': fen,
      'moves': moves,
      'rating': rating,
      'ratingdeviation': ratingDeviation,
      'popularity': popularity,
      'nbplays': nbPlays,
      'themes': themes.join(' '),
      'gameurl': gameUrl,
    };
  }
}

void main() {
  final hehe = {
    "items": [
      {
        "puzzleid": "td3j5",
        "fen": "4r1k1/3nqp1p/6p1/8/3b4/2P2N1P/1PQ2PPB/6K1 w - - 0 24",
        "moves": "c3d4 e7e1 f3e1 e8e1",
        "rating": 399,
        "ratingdeviation": 399,
        "popularity": 399,
        "nbplays": 399,
        "themes": "backRankMate endgame mate mateIn2 sacrifice short",
        "gameurl": "https://lichess.org/s9e4su3y#47",
        "openingtags": ""
      },
      {
        "puzzleid": "tZSwC",
        "fen": "6k1/1Q3p1p/4p1p1/1p6/5PPP/5R2/1r6/3r3K w - - 3 37",
        "moves": "f3f1 d1f1",
        "rating": 399,
        "ratingdeviation": 399,
        "popularity": 399,
        "nbplays": 399,
        "themes": "endgame hangingPiece mate mateIn1 oneMove queenRookEndgame",
        "gameurl": "https://lichess.org/gksvG8Eo#73",
        "openingtags": ""
      }
    ]
  };
  print(Puzzles.fromJson(hehe).puzzles[0].toJson());
}
