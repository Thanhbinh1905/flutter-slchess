import '../constants/constants.dart';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Để sử dụng jsonEncode
import 'package:shared_preferences/shared_preferences.dart';

import './matchService.dart';
import '../models/match.dart';

class MatchMakingSerice {
  static final String _wsGameUrl = WebsocketConstants.game;
  static const String _wsQueueUrl = WebsocketConstants.queueing;
  static const String _matchMakingApiUrl = ApiConstants.matchMaking;

  static WebSocketChannel startGame(String matchId, String idToken) {
    final WebSocketChannel channel = IOWebSocketChannel.connect(
      Uri.parse(_wsGameUrl),
      headers: {
        'Authorization': idToken, // Thêm token vào header
      },
    );
    return channel;
  }

  void makeMove(String move, WebSocketChannel channel) {
    channel.sink.add(jsonEncode({
      "type": "gameData",
      "data": {"action": "move", "move": move},
      "createdAt": DateTime.now().toIso8601String()
    }));
  }

  void disconnect(WebSocketChannel channel) {
    channel.sink.close();
  }

  Future<MatchModel?> connectToQueue(String idToken) async {
    final WebSocketChannel channel = IOWebSocketChannel.connect(
      Uri.parse(_wsQueueUrl),
      headers: {
        'Authorization': idToken,
      },
    );

    channel.sink.add(jsonEncode({"action": "queueing"}));

    MatchModel? matchData;

    channel.stream.listen(
      (message) {
        final data = jsonDecode(message);
        if (data.containsKey("matchId")) {
          matchData = handleQueued(message);
        }
      },
      onError: (error) {
        print("Error: $error");
      },
      onDone: () {
        print("Connection closed");
      },
    );
    return matchData;
  }

  Future<MatchModel?> getQueue(String idToken, String gameMode, double rating,
      {int minRating = 0, int maxRating = 100}) async {
    // Cập nhật giá trị mặc định cho minRating và maxRating nếu cần
    minRating = minRating == 0 ? (rating - 50).toInt() : minRating;
    maxRating = maxRating == 100 ? (rating + 50).toInt() : maxRating;

    try {
      final response = await http.post(
        Uri.parse(_matchMakingApiUrl),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type':
              'application/json', // Đảm bảo rằng Content-Type được thiết lập
        },
        body: jsonEncode({
          "minRating": minRating,
          "maxRating": maxRating,
          "gameMode": gameMode
        }),
      );

      if (response.statusCode == 200) {
        print('Queue retrieved successfully!');

        // MatchModel data = MatchService().getMatchFromJson(response.body);
        // print(data.toJson());

        return handleQueued(response.body);
      } else if (response.statusCode == 202) {
        print('Queue creation in progress...');
        connectToQueue(idToken);
      } else {
        print("Error: [Status ${response.statusCode}] ${response.body}");
      }
    } catch (e) {
      print("Error when getting queue: $e");
    }
    return null;
  }

  MatchModel handleQueued(String message) {
    return MatchService().getMatchFromJson(message);
  }
}

void main() {
  const String token =
      "eyJraWQiOiIwUG5IR3RNYWJGSFM1TkNvWkt1Vjd5UktnRUNpZkdPemVqdVJId2VGUkNRPSIsImFsZyI6IlJTMjU2In0.eyJhdF9oYXNoIjoiaUtsZG13azZFakJMdnYwZS1abDhHdyIsInN1YiI6IjY5ZWU3NGY4LTQwZjEtNzA3NC0yNGNmLTg2Zjg0MThiMDlmZCIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLmFwLXNvdXRoZWFzdC0yLmFtYXpvbmF3cy5jb21cL2FwLXNvdXRoZWFzdC0yX0Z2aEQ1amc2diIsImNvZ25pdG86dXNlcm5hbWUiOiJ0ZXN0dXNlcjEiLCJvcmlnaW5fanRpIjoiMDk0ZDA3YzEtMDEyZS00OTk1LWExN2MtZDM3MjM1MTMzMzJiIiwiYXVkIjoiMjUxbGIwN25jYWU4YmpmOXBkZjlmaHJvZWQiLCJldmVudF9pZCI6ImEzNjhhYjM2LWU5ZWEtNDAzOS1hZWE0LWUxYzMzNTVlYzAxNCIsInRva2VuX3VzZSI6ImlkIiwiYXV0aF90aW1lIjoxNzQxOTQ0Mjc4LCJleHAiOjE3NDE5NDc4NzgsImlhdCI6MTc0MTk0NDI3OCwianRpIjoiNmRlNDEwYjUtMDg3Ni00OWVhLWJmYjctY2Q0OGU4M2I5YjZmIiwiZW1haWwiOiJ0ZXN0dXNlcjFAZ21haWwuY29tIn0.nZxQTYPOXrAB7-qZu4a9axgiicHQcKw1i1tu99MOFQeN9FjyLmfcMTLSXgFZ7iRFPRN9Kjfffq2fqBgfTn1t27um0bOAdGwCZToeBuUGLxuiere6-bD_Bo186-rQ8fqLdyGXIrBdHEeyrlJazRnfWDWk58IQBBlF0oCf4pbRwcwjRciZZYktmn6eDqcC83JYR1cN-v568B4bpb24UEYv1INIQamDLhZBDxiMH3bRIceFuttyjD4GlCwyYBtZPe4jfsa4hITW-zqNc2T4VtM72UFJL_R8yzRS48IH44Eh08JtLgft8Zo2rULQhS_7rBPB3ZGv2XUQbf4btWm00aUrPg"; // Thay thế bằng token thực tế
  // print("Token: $token"); // In ra token để kiểm tra

  MatchMakingSerice().getQueue(token, "10+0", 1200);
}
