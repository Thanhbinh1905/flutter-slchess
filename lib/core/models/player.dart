import './user.dart';
import '../services/userService.dart';
import '../services/cognito_auth_service.dart';

class Player {
  final UserModel user;
  final int rating;
  final List<int> newRatings;
  final double rd;
  final List<double> newRDs;

  Player({
    required this.user,
    required this.rating,
    this.rd = 0.0,
    this.newRatings = const [],
    this.newRDs = const [],
  });

  static Future<Player> fromJson(Map<String, dynamic> json) async {
    final cognitoAuth = CognitoAuth();
    final userService = UserService();

    try {
      final storedIdToken = await cognitoAuth.getStoredIdToken();
      final user = await userService.getUserInfo(json['id'], storedIdToken!);

      return Player(
        user: user,
        rating: json['rating'],
        rd: (json['rd'] != null)
            ? double.tryParse(json['rd'].toString()) ?? 0.0
            : 0.0,
        newRatings: List<int>.from(json['newRatings'] ?? []),
        newRDs: List<double>.from(json['newRDs'] ?? []),
      );
    } catch (e) {
      throw Exception('Error creating Player: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': user.id,
      'rating': rating,
      'rd': rd,
      'newRatings': newRatings,
      'newRDs': newRDs,
    };
  }
}
