import 'dart:convert';
import '../models/user.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UserService {
  static String getUserApiUrl = ApiConstants.getUserInfo;
  static String getSelfUserApiUrl = ApiConstants.getSelfUserInfoUrl;
  static String updateRatingUrl = ApiConstants.getSelfUserInfoUrl;

  static const String USER_BOX = 'userBox';

  Future<UserModel> getUserInfo(String userId, String idToken) async {
    try {
      final response = await http.get(Uri.parse("$getUserApiUrl/$userId"),
          headers: {'Authorization': idToken});
      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        print("API lỗi: ${response.statusCode}, Body: ${response.body}");
        throw Exception('Failed to load user info: ${response.statusCode}');
      }
    } catch (e) {
      print("Error when getting user info: $e");
      throw Exception('Error when getting user info');
    }
  }

  Future<void> updateRating(
      String userId, double newRating, String idToken) async {
    try {
      final response = await http.put(
        Uri.parse("$updateRatingUrl/$userId"),
        headers: {
          'Authorization': idToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'rating': newRating}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update rating: ${response.statusCode}');
      }

      // Cập nhật thông tin user trong Hive
      UserModel updatedUser = await getUserInfo(userId, idToken);
      await savePlayer(updatedUser);
    } catch (e) {
      print("Error when updating rating: $e");
      throw Exception('Error when updating rating');
    }
  }

  Future<void> saveSelfUserInfo(String accessToken, String idToken) async {
    try {
      // Đảm bảo box được khởi tạo trước khi sử dụng
      if (!Hive.isBoxOpen(USER_BOX)) {
        await Hive.openBox<UserModel>(USER_BOX);
      }

      final response = await http.get(
        Uri.parse(getSelfUserApiUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      print(
          "Self info response: ${response.statusCode}, body: ${response.body}");

      if (response.statusCode == 200) {
        String userId = jsonDecode(response.body)['sub'];
        UserModel user = await getUserInfo(userId, idToken);
        print("User data: ${user.toJson()}");
        await savePlayer(user);
      } else {
        throw Exception('Failed to load user info: ${response.statusCode}');
      }
    } catch (e) {
      print("Error when getting user info: $e");
      throw Exception('Error when getting user info: $e');
    }
  }

  Future<void> savePlayer(UserModel player) async {
    try {
      if (!Hive.isBoxOpen(USER_BOX)) {
        await Hive.openBox<UserModel>(USER_BOX);
      }

      final box = await Hive.openBox<UserModel>(USER_BOX);
      await box.put('currentPlayer', player);
      print("Player saved successfully: ${player.username}");
    } catch (e) {
      print("Error saving player to Hive: $e");
      throw Exception('Error saving player data: $e');
    }
  }

  Future<UserModel?> getPlayer() async {
    try {
      if (!Hive.isBoxOpen(USER_BOX)) {
        await Hive.openBox<UserModel>(USER_BOX);
      }

      final box = await Hive.openBox<UserModel>(USER_BOX);
      dynamic rawValue = box.get('currentPlayer');

      // Check if the retrieved object is of the correct type
      if (rawValue is UserModel) {
        print("Retrieved user: ${rawValue.username}");
        return rawValue;
      } else {
        print("Wrong type found in Hive box: ${rawValue.runtimeType}");
        // Clean up the corrupted data
        await box.delete('currentPlayer');
        return null;
      }
    } catch (e) {
      print("Error retrieving player from Hive: $e");
      return null;
    }
  }

  // Xóa thông tin người dùng - hữu ích khi đăng xuất
  Future<void> clearUserData() async {
    try {
      if (!Hive.isBoxOpen(USER_BOX)) {
        await Hive.openBox<UserModel>(USER_BOX);
      }

      final box = await Hive.openBox<UserModel>(USER_BOX);
      await box.delete('currentPlayer');
      print("User data cleared");
    } catch (e) {
      print("Error clearing user data: $e");
    }
  }
}

void main() async {
  const String accessToken =
      "eyJraWQiOiJkRXlGcVFoZUNBQnlOVzlpRWFIdFpKUUM0XC9OZXJrbU9aQUJWYzJpcHdUTT0iLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhOThlMzQxOC1iMDkxLTcwNzMtZGNhYS1mMGQ0ZmFiNGFjMTciLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAuYXAtc291dGhlYXN0LTIuYW1hem9uYXdzLmNvbVwvYXAtc291dGhlYXN0LTJfYm5rSExrNEl5IiwidmVyc2lvbiI6MiwiY2xpZW50X2lkIjoiYTc0Mmtpa2ludWdydW1oMTgzbWhqYTduZiIsIm9yaWdpbl9qdGkiOiIyYzJjN2FmZC1mODA0LTQxZTEtOGNiOC1mMmZlMGUwYjQ2MzMiLCJ0b2tlbl91c2UiOiJhY2Nlc3MiLCJzY29wZSI6InBob25lIG9wZW5pZCBwcm9maWxlIGVtYWlsIiwiYXV0aF90aW1lIjoxNzQzNzY2OTgwLCJleHAiOjE3NDM4NTMzODAsImlhdCI6MTc0Mzc2Njk4MCwianRpIjoiZGFiMjBjMjYtMmFkNy00YWI4LWIxZjYtZTY0OTVjZjdlYTJmIiwidXNlcm5hbWUiOiJ0ZXN0dXNlcjIifQ.IYqSY0iSqhNSMzsoffxC8IsGZrqD67f2ScCeEhjwZlV2iI_yqEUOqFcIJKKwjfPO3x5Bp_83Sx5qbuYkonjgpTw4YUQH3ZO0Vgw0FlzZyIizDm2RuMb0Bchp9Ay83WGdBSoIsuMGruyRwUkOreNo5xCZnP9gQgPw8Jglanr7q_Eh-Xv6iwxeCX1ThHI-hozcKtAIB-sBrbuUcVUWnXHyCpvbLX9ArlGUOk21Sgz0Qs9sOjnivlqM9SiOYZYo25s7nyltJHngmlb1piyBni83Ts0hKWtJDSaKmBEezXWoN3qGpzVcfYDCNdTSI8FeXr1y1szSzsIGuNSVbKBzxndL5g";
  const String idToken =
      "eyJraWQiOiJcL3I1OU5BYWtWakc0VWtwaFlFcHNlSHZ0bThkaDQyYlJPMFprcU5IV1Uxaz0iLCJhbGciOiJSUzI1NiJ9.eyJhdF9oYXNoIjoiUWNPUjVtWXJRczNxcTM0ZGtXQTY3QSIsInN1YiI6ImE5OGUzNDE4LWIwOTEtNzA3My1kY2FhLWYwZDRmYWI0YWMxNyIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLmFwLXNvdXRoZWFzdC0yLmFtYXpvbmF3cy5jb21cL2FwLXNvdXRoZWFzdC0yX2Jua0hMazRJeSIsImNvZ25pdG86dXNlcm5hbWUiOiJ0ZXN0dXNlcjIiLCJvcmlnaW5fanRpIjoiMmMyYzdhZmQtZjgwNC00MWUxLThjYjgtZjJmZTBlMGI0NjMzIiwiYXVkIjoiYTc0Mmtpa2ludWdydW1oMTgzbWhqYTduZiIsInRva2VuX3VzZSI6ImlkIiwiYXV0aF90aW1lIjoxNzQzNzY2OTgwLCJleHAiOjE3NDM4NTMzODAsImlhdCI6MTc0Mzc2Njk4MCwianRpIjoiOTllN2E0NzAtMDEwZC00ZTE3LWI2Y2ItNmEyNWE3YzAyZjI4IiwiZW1haWwiOiJ0ZXN0dXNlcjJAZ21haWwuY29tIn0.xs0v7orUyWKHnvO9q7WlB2_wrmcH6FV5VEt9sijdODWLAFgdsADkdn11IZI9wnj_lsQm4-669o7A7Fc8fe5xpALuQGvFVl_bPf_7cGi0M0jEyt51zVnyRgB8EiFSm727_DRDskFQrnYxuicVbnr3vkzP1JFD6YRipjutwa_gG3B1xdVsgl280N0p9x1l26TdrhUAP_RRLjZSWmyk0bSWRS_V7utwPnTmOrzQjp25wSwgL6TLkYyCEEfrsqqXT9v3oWiSfu6D-fnnAX0jUcKW367DwTbHTRWhrvS02HpJFR_RfnTos_JCln0NFr6Lrac9NpV0u9MVkKKm_PfM7Fd4MQ";

  final userService = UserService();
  await userService.saveSelfUserInfo(accessToken, idToken);

  UserModel? player = await userService.getPlayer();
}
