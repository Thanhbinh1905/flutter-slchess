import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/friendship_model.dart';
import '../constants/constants.dart';

class FriendshipService {
  final String _baseUrl = ApiConstants.friendUrl;

  /// Lấy danh sách bạn bè
  /// [userIdToken] - Token JWT cho xác thực

  Future<FriendshipModel> getFriendshipList(String userIdToken) async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Authorization': 'Bearer $userIdToken'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return FriendshipModel.fromJson(data);
      } else {
        throw Exception('Failed to load friendship list');
      }
    } catch (e) {
      throw Exception('Error getting friendship list: $e');
    }
  }
}
