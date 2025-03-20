import './user.dart';

class Player {
  final String id;
  final int rating;
  List<int> newRatings;
  double rd;
  List<double> newRDs;

  Player({
    required this.id,
    required this.rating,
    this.rd = 0.0,
    this.newRatings = const [],
    this.newRDs = const [],
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      rating: json['rating'],
      rd: double.tryParse(json['rd']?.toString() ?? '') ?? 0.0,
      newRatings: List<int>.from(json['newRatings'] ?? []),
      newRDs: List<double>.from(json['newRDs'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rating': rating,
      'rd': rd,
      'newRatings': newRatings,
      'newRDs': newRDs,
    };
  }
}

void main() {
  const String token =
      "eyJraWQiOiI5R1lvVTlFOFQ1amxFQUx2dG04QmxpTHlNZ2NJblg0a0xmejhKQXhQZFlRPSIsImFsZyI6IlJTMjU2In0.eyJhdF9oYXNoIjoiVXd5X1ZPVnIzQmZTS2g4S2RNT1JLQSIsInN1YiI6IjA5Y2UyNGM4LTEwZjEtNzA3OS1lNTU0LTBlZWM4MzZkOWY0ZiIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLmFwLXNvdXRoZWFzdC0yLmFtYXpvbmF3cy5jb21cL2FwLXNvdXRoZWFzdC0yX3o1ODQ3NERyWCIsImNvZ25pdG86dXNlcm5hbWUiOiJ0ZXN0dXNlcjEiLCJvcmlnaW5fanRpIjoiNjc1ZTE5MDAtMjU1ZC00Y2JlLTkxNzEtNGZlN2ZhMDYyNjRkIiwiYXVkIjoibnJoa2wxdGMzNG1pcDYyZGttNDRsamJrNSIsImV2ZW50X2lkIjoiYWE4YmI1MmEtNzYxNi00MmFlLTg0MDctZjdhYjQxMmI1NWJjIiwidG9rZW5fdXNlIjoiaWQiLCJhdXRoX3RpbWUiOjE3NDE5NTY3MDAsImV4cCI6MTc0MTk2MDMwMCwiaWF0IjoxNzQxOTU2NzAwLCJqdGkiOiI2OTRlN2MwYy1hZGFiLTQ1MGQtODQ2MS0yNjIzNjc3OWI3ZTQiLCJlbWFpbCI6InRlc3R1c2VyMUBnbWFpbC5jb20ifQ.n6d4EdQaB8vyThfmUVZU533MidXxUjMs9V6K1Ru-ZNLv_rShg5tTWvzhtU_CxWCAVRW2oMi66OKL54iuNGj3mstBz6u1SMASZBZ41XL8bQdmo95lc9nUdtJsfnfK5a5BZTwW2HzOrjkLhIS2ZlwnXIWQn838EpJsNHoTL0HgLKiXwA1FH91y3CL-vBHWL05yGclRMC9KACJL3iBA4H3-cmf1HKa2J8Iz6PPmRJbyKpl8YMUYqOBCkkNNdjwry-o7W_euAhlJ8br8fR-HfjNhfAcI0ycd_l597HHm6pnD6jHXL4I86JOc_cJF7Jmp2tDTJ5hgtS80VDOCWK96PvCGsg";

  Map<String, dynamic> json = {
    "id": "39aef4b8-60c1-70f0-eca9-e2e5cbdf5e99",
    "rating": 1200,
    "newRatings": [1270.1, 1205.3, 1120.4]
  };
}
