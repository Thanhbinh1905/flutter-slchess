import 'dart:convert';
import '../models/match.dart';
import '../models/player1.dart';
import './userService.dart';

class MatchService {
  Match getMatchFromJson(String jsonString) {
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    return Match.fromJson(jsonData);
  }

  Player getPlayer1FromMatch(Match match) {
    return match.player1;
  }

  Player getPlayer2FromMatch(Match match) {
    return match.player2;
  }

  bool isUserWhite() {
    return true;
  }
}

// Example usage
void main() {
  String jsonString =
      '{"matchId":"09ce24c8-10f1-7079-e554-0eec836d9f4f","player1":{"id":"29de44c8-4001-70ab-a072-4ea2e2214471","rating":1200,"newRatings":[1200,1200,1200]},"player2":{"id":"493e7478-9011-70ab-927b-072b311240e8","rating":1200,"newRatings":[1200,1200,1200]},"gameMode":"10+0","server":"SERVER_IP","createdAt":"2025-03-14T09:38:27.628085952Z"}';
  Match match = MatchService().getMatchFromJson(jsonString);

  print(match.player1.toJson());
}
