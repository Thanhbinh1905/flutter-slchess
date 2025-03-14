import '../constants/constants.dart';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Để sử dụng jsonEncode

class matchMaking {
  static final String _wsGameUrl = WebsocketConstants().game;
  static final String _wsQueueUrl = WebsocketConstants().queueing;
  static final String _matchMakingApiUrl = ApiConstants().matchMaking;

  void connectToQueue(String idToken) {
    final WebSocketChannel channel = IOWebSocketChannel.connect(
      Uri.parse(
          "wss://y0g2gcbj5i.execute-api.ap-southeast-2.amazonaws.com/dev"),
      headers: {
        'Authorization': idToken, // Thêm token vào header
      },
    );

    // Gửi dữ liệu dưới dạng chuỗi JSON
    channel.sink.add(jsonEncode({"action": "queueing"}));

    channel.stream.listen(
      (message) {
        print("Received: $message");
      },
      onError: (error) {
        print("Error: $error");
      },
      onDone: () {
        print("Connection closed");
      },
    );
  }

  Future<void> getQueue(String idToken, String gameMode, int rating,
      {int minRating = 0, int maxRating = 100}) async {
    // Cập nhật giá trị mặc định cho minRating và maxRating nếu cần
    minRating = minRating == 0 ? rating - 50 : minRating;
    maxRating = maxRating == 100 ? rating + 50 : maxRating;

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
        var data = jsonDecode(response.body);
        print(data);
      } else if (response.statusCode == 202) {
        print('Queue creation in progress...');
        connectToQueue(idToken);
      } else {
        print("Error: [Status ${response.statusCode}] ${response.body}");
      }
    } catch (e) {
      print("Error when getting queue: $e");
    }
  }
}

void main() {
  const String token =
      "eyJraWQiOiIwUG5IR3RNYWJGSFM1TkNvWkt1Vjd5UktnRUNpZkdPemVqdVJId2VGUkNRPSIsImFsZyI6IlJTMjU2In0.eyJhdF9oYXNoIjoiaUtsZG13azZFakJMdnYwZS1abDhHdyIsInN1YiI6IjY5ZWU3NGY4LTQwZjEtNzA3NC0yNGNmLTg2Zjg0MThiMDlmZCIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLmFwLXNvdXRoZWFzdC0yLmFtYXpvbmF3cy5jb21cL2FwLXNvdXRoZWFzdC0yX0Z2aEQ1amc2diIsImNvZ25pdG86dXNlcm5hbWUiOiJ0ZXN0dXNlcjEiLCJvcmlnaW5fanRpIjoiMDk0ZDA3YzEtMDEyZS00OTk1LWExN2MtZDM3MjM1MTMzMzJiIiwiYXVkIjoiMjUxbGIwN25jYWU4YmpmOXBkZjlmaHJvZWQiLCJldmVudF9pZCI6ImEzNjhhYjM2LWU5ZWEtNDAzOS1hZWE0LWUxYzMzNTVlYzAxNCIsInRva2VuX3VzZSI6ImlkIiwiYXV0aF90aW1lIjoxNzQxOTQ0Mjc4LCJleHAiOjE3NDE5NDc4NzgsImlhdCI6MTc0MTk0NDI3OCwianRpIjoiNmRlNDEwYjUtMDg3Ni00OWVhLWJmYjctY2Q0OGU4M2I5YjZmIiwiZW1haWwiOiJ0ZXN0dXNlcjFAZ21haWwuY29tIn0.nZxQTYPOXrAB7-qZu4a9axgiicHQcKw1i1tu99MOFQeN9FjyLmfcMTLSXgFZ7iRFPRN9Kjfffq2fqBgfTn1t27um0bOAdGwCZToeBuUGLxuiere6-bD_Bo186-rQ8fqLdyGXIrBdHEeyrlJazRnfWDWk58IQBBlF0oCf4pbRwcwjRciZZYktmn6eDqcC83JYR1cN-v568B4bpb24UEYv1INIQamDLhZBDxiMH3bRIceFuttyjD4GlCwyYBtZPe4jfsa4hITW-zqNc2T4VtM72UFJL_R8yzRS48IH44Eh08JtLgft8Zo2rULQhS_7rBPB3ZGv2XUQbf4btWm00aUrPg"; // Thay thế bằng token thực tế
  // print("Token: $token"); // In ra token để kiểm tra

  matchMaking().getQueue(token, "10+0", 1200);
}
