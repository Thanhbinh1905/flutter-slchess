enum Membership { guest, premium }

class UserModel {
  final String id;
  final String username;
  String locate;
  String picture;
  double rating;
  Membership membership;
  DateTime createAt;

  UserModel({
    required this.id,
    required this.username,
    this.locate = "",
    this.picture = "",
    this.rating = 0,
    this.membership = Membership.guest,
    DateTime? createAt,
  }) : createAt = createAt ?? DateTime.now().toUtc();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      locate: json['locale'] ?? '',
      picture: json['phone'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      membership: Membership.values.byName(json['membership'] ?? 'guest'),
      createAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'locale': locate,
      'picture': picture,
      'rating': rating,
      'membership': membership.name.toLowerCase(),
      'createdAt': createAt.toIso8601String(),
    };
  }
}
