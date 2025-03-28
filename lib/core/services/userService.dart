import 'dart:convert';
import '../models/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Để sử dụng jsonEncode
import '../constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static String getUserApiUrl = ApiConstants.getUserInfo;
  static String getSelfUserApiUrl = ApiConstants.getSelfUserInfoUrl;

  Future<UserModel> getUserInfo(String userId, String idToken) async {
    try {
      final response = await http.get(Uri.parse("$getUserApiUrl/$userId"),
          headers: {'Authorization': idToken});
      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load user info: ${response.statusCode}');
      }
    } catch (e) {
      print("Error when getting user info: $e");
      throw Exception('Error when getting user info');
    }
  }

  Future<void> saveSelfUserInfo(String accessToken, String idToken) async {
    try {
      final response = await http.get(
        Uri.parse(getSelfUserApiUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        String userId = jsonDecode(response.body)['sub'];
        UserModel user =
            await getUserInfo(userId, idToken); // ⚠️ `await` để lấy UserModel
        await savePlayer(user); // Lưu user vào SharedPreferences
      } else {
        throw Exception('Failed to load user info: ${response.statusCode}');
      }
    } catch (e) {
      print("Error when getting user info: $e");
      throw Exception('Error when getting user info');
    }
  }

  Future<void> savePlayer(UserModel player) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player', jsonEncode(player.toJson()));
  }

  Future<UserModel?> getPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    String? playerData = prefs.getString('player');
    if (playerData == null) return null;
    return UserModel.fromJson(jsonDecode(playerData));
  }
}

void main() async {
  const String accessToken =
      "eyJraWQiOiJPQ0xsdWJsUFIzM3hiblNiakFuQmx5elNSeURvUUpTcEx1TUJtWWlVQ1pNPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI4OWNlNTQ0OC0wMDkxLTcwYzgtNTExZi0zZWUzNjBiNmE0ZjAiLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAuYXAtc291dGhlYXN0LTIuYW1hem9uYXdzLmNvbVwvYXAtc291dGhlYXN0LTJfS0l1anF3UzZuIiwidmVyc2lvbiI6MiwiY2xpZW50X2lkIjoiNG1oc2VyOG9xcDdrazlxYzJxdG1ldDRkdDAiLCJvcmlnaW5fanRpIjoiOWE3NjE3OGUtZmY5Yi00MzYyLTk5YzEtNjc4M2QyNGMyMTljIiwiZXZlbnRfaWQiOiI4ZDgwNmI3Ny1lYmExLTQ2NDAtYjg3OS0wMDAwY2I4ZGJlMzgiLCJ0b2tlbl91c2UiOiJhY2Nlc3MiLCJzY29wZSI6InBob25lIG9wZW5pZCBwcm9maWxlIGVtYWlsIiwiYXV0aF90aW1lIjoxNzQyODEyMjg4LCJleHAiOjE3NDI4OTg2ODgsImlhdCI6MTc0MjgxMjI4OCwianRpIjoiNTRhN2NmOGQtZjNiOS00ZThiLTk3MTctMmUxNTQ0MjM0MTU3IiwidXNlcm5hbWUiOiJ0ZXN0dXNlcjEifQ.ZEkktcmVPpQqpEZohPIuwRrLy0VZu3lQywRSz4O-FwqrdKySw33qrRuWYKpz4Q_ODCtELASSRPFQ0WNLWTdvWJf68BikZqXUKmFop_GPaosAX9FF8TqY2_UTb-0Uwx4AkwL0HrWEbpGzTuOiXpxbmG4WdbMms0H11qu_Rit9LrSpUmjQ3bffCJHKL5s7XqWlBXfk6YxJKNA5pdScCqqVghBhtFAm83_GTMgX8lnjfPqOICUajismwSUOOJi9PmZaOsRcHdOIrSrx2OpYuQvJb62ZUKg1R82m_ZT4HGXYDJoFgukgssXWGINkV2j4AhiZk7OgG4-FvyofukUEz6F-GA";
  const String idToken =
      "eyJraWQiOiI1WEhKMERESVlOQ2ZRbE9BVU1sWTNsQ2F4bklaYTZ3cHV6Zk5UclhGQlE0PSIsImFsZyI6IlJTMjU2In0.eyJhdF9oYXNoIjoiZ0F4akppZ24wTUgzZTFVbzhwYXo3USIsInN1YiI6Ijg5Y2U1NDQ4LTAwOTEtNzBjOC01MTFmLTNlZTM2MGI2YTRmMCIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLmFwLXNvdXRoZWFzdC0yLmFtYXpvbmF3cy5jb21cL2FwLXNvdXRoZWFzdC0yX0tJdWpxd1M2biIsImNvZ25pdG86dXNlcm5hbWUiOiJ0ZXN0dXNlcjEiLCJvcmlnaW5fanRpIjoiOWE3NjE3OGUtZmY5Yi00MzYyLTk5YzEtNjc4M2QyNGMyMTljIiwiYXVkIjoiNG1oc2VyOG9xcDdrazlxYzJxdG1ldDRkdDAiLCJldmVudF9pZCI6IjhkODA2Yjc3LWViYTEtNDY0MC1iODc5LTAwMDBjYjhkYmUzOCIsInRva2VuX3VzZSI6ImlkIiwiYXV0aF90aW1lIjoxNzQyODEyMjg4LCJleHAiOjE3NDI4OTg2ODgsImlhdCI6MTc0MjgxMjI4OCwianRpIjoiOTM3NWZkNGUtNjllMi00MjUzLWJhYzctMzBiODk4OGQzODg1IiwiZW1haWwiOiJ0ZXN0dXNlcjFAZ21haWwuY29tIn0.ofS9_lPGarBckQ0mEGZhYEF1BHeZZ4Bq5D2r_-Jwq0QwFoXR6F10zgtTl5n6CR0570NcRQcVFW814Kqs5Ktkz-oULVfKCKVh6YMXdw5P5MCekHSTQJ1vU3v8_vqTL1dcFMk3EcsUAYcoetce6_ucneaPinVz3Ld6OUL4TT9KiPDJo7M-pez_zzqLzE3JF3zbrPuHqV6L9xqsrSOgtHMgrkPp7lorhE0YeK5T8sWCcEmUDb5kFsRIfl7_-2X6qrvDq2umnM0s6tkRaCRHAprXl5FwBxPdO1lf1UCds2fROC3--JcS_xT3N3wRiZXBTPi9Z5wcgiwBp1zDJRCWX8SVmw";

  final userService = UserService();
  await userService.saveSelfUserInfo(accessToken, idToken);

  UserModel? player = await userService.getPlayer();
}
