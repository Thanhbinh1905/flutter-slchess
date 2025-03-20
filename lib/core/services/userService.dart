import 'dart:convert';
import '../models/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Để sử dụng jsonEncode
import '../constants/constants.dart';

class UserService {
  static const String getUserApiUrl = ApiConstants.getUserInfo;

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
}

void main() async {
  const String token =
      "eyJraWQiOiI5R1lvVTlFOFQ1amxFQUx2dG04QmxpTHlNZ2NJblg0a0xmejhKQXhQZFlRPSIsImFsZyI6IlJTMjU2In0.eyJhdF9oYXNoIjoiVXd5X1ZPVnIzQmZTS2g4S2RNT1JLQSIsInN1YiI6IjA5Y2UyNGM4LTEwZjEtNzA3OS1lNTU0LTBlZWM4MzZkOWY0ZiIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLmFwLXNvdXRoZWFzdC0yLmFtYXpvbmF3cy5jb21cL2FwLXNvdXRoZWFzdC0yX3o1ODQ3NERyWCIsImNvZ25pdG86dXNlcm5hbWUiOiJ0ZXN0dXNlcjEiLCJvcmlnaW5fanRpIjoiNjc1ZTE5MDAtMjU1ZC00Y2JlLTkxNzEtNGZlN2ZhMDYyNjRkIiwiYXVkIjoibnJoa2wxdGMzNG1pcDYyZGttNDRsamJrNSIsImV2ZW50X2lkIjoiYWE4YmI1MmEtNzYxNi00MmFlLTg0MDctZjdhYjQxMmI1NWJjIiwidG9rZW5fdXNlIjoiaWQiLCJhdXRoX3RpbWUiOjE3NDE5NTY3MDAsImV4cCI6MTc0MTk2MDMwMCwiaWF0IjoxNzQxOTU2NzAwLCJqdGkiOiI2OTRlN2MwYy1hZGFiLTQ1MGQtODQ2MS0yNjIzNjc3OWI3ZTQiLCJlbWFpbCI6InRlc3R1c2VyMUBnbWFpbC5jb20ifQ.n6d4EdQaB8vyThfmUVZU533MidXxUjMs9V6K1Ru-ZNLv_rShg5tTWvzhtU_CxWCAVRW2oMi66OKL54iuNGj3mstBz6u1SMASZBZ41XL8bQdmo95lc9nUdtJsfnfK5a5BZTwW2HzOrjkLhIS2ZlwnXIWQn838EpJsNHoTL0HgLKiXwA1FH91y3CL-vBHWL05yGclRMC9KACJL3iBA4H3-cmf1HKa2J8Iz6PPmRJbyKpl8YMUYqOBCkkNNdjwry-o7W_euAhlJ8br8fR-HfjNhfAcI0ycd_l597HHm6pnD6jHXL4I86JOc_cJF7Jmp2tDTJ5hgtS80VDOCWK96PvCGsg";
  const String userId = "493e7478-9011-70ab-927b-072b311240e8";

  UserModel user1 = await UserService().getUserInfo(userId, token);

  print(user1.toJson());
}
