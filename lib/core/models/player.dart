enum Status { CONNECTED, DISCONNECTED }

class Player {
  final String id;
  final String avatar;
  final String email;
  int rating;
  int wins;
  int losses;
  int draws;

  Player({
    required this.id,
    required this.avatar,
    required this.email,
    this.rating = 1200,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      avatar: json['avatar'],
      email: json['email'],
      rating: json['rating'] ?? 1200,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      draws: json['draws'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avatar': avatar,
      'email': email,
      'rating': rating,
      'wins': wins,
      'losses': losses,
      'draws': draws,
    };
  }
}
