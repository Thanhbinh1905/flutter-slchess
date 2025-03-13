enum Status { CONNECTED, DISCONNECTED }

class Player {
  final String username;
  final List ratingChanges;
  int rating;
  int wins;
  int losses;
  int draws;

  Player({
    required this.ratingChanges,
    required this.username,
    this.rating = 1200,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      ratingChanges: json['ratingChanges'] ?? [],
      username: json['username'],
      rating: json['rating'] ?? 1200,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      draws: json['draws'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'rating': rating,
      'wins': wins,
      'losses': losses,
      'draws': draws,
    };
  }
}
