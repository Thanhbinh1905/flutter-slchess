import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import '../../main.dart';
import './userService.dart';

class CognitoAuth {
  late AppLinks _appLinks;
  final EncryptedSharedPreferences storage = EncryptedSharedPreferences();
  final userService = UserService();

  final cognitoUrl = dotenv.env['COGNITO_URL'];
  final cognitoClientId = dotenv.env['COGNITO_CLIENT_ID'];

  // Các key để lưu token
  static const String ACCESS_TOKEN_KEY = "ACCESS_TOKEN";
  static const String ID_TOKEN_KEY = "ID_TOKEN";
  static const String REFRESH_TOKEN_KEY = "REFRESH_TOKEN";

  // Thêm key để lưu thông tin người dùng
  static const String USER_INFO_KEY = "USER_INFO";

  Future<void> initAppLinks() async {
    _appLinks = AppLinks();

    // Lắng nghe các deep link
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        final code = uri.queryParameters['code'];
        if (code != null) {
          getToken(code);
        }
      }
    });

    // Kiểm tra initial link
    try {
      final uri = await _appLinks.getInitialAppLink();
      if (uri != null) {
        final code = uri.queryParameters['code'];
        if (code != null) {
          getToken(code);
        }
      }
    } catch (e) {
      print('Lỗi lấy initial link: $e');
    }
  }

  Future<void> handleLogin() async {
    try {
      final url = Uri.https(
        cognitoUrl!,
        'login',
        {
          'client_id': cognitoClientId,
          'redirect_uri': 'slchess://callback',
          'response_type': 'code',
          'scope': 'email openid phone',
        },
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      print('Lỗi đăng nhập: $e');
    }
  }

  // Future<void> resetToken

  Future<void> getToken(String code) async {
    try {
      final tokenResponse = await http.post(
        Uri.https(cognitoUrl!, '/oauth2/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': cognitoClientId,
          'code': code,
          'redirect_uri': 'slchess://callback',
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokens = json.decode(tokenResponse.body);

        await storage.setString(ACCESS_TOKEN_KEY, tokens['access_token']);
        await storage.setString(ID_TOKEN_KEY, tokens['id_token']);
        await storage.setString(REFRESH_TOKEN_KEY, tokens['refresh_token']);

        // Tiếp tục lấy thông tin người dùng
        await userService.saveSelfUserInfo(
            tokens['access_token'], tokens['id_token']);

        navigateToHome();
      } else {
        print('❌ Lỗi lấy token: ${tokenResponse.body}');
      }
    } catch (e) {
      print('❌ Lỗi xử lý token: $e');
    }
  }

  Future<void> refreshToken() async {
    final refreshToken = await storage.getString(REFRESH_TOKEN_KEY);

    try {
      final response = await http.post(
        Uri.https(cognitoUrl!, '/oauth2/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'client_id': cognitoClientId!,
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final tokens = json.decode(response.body);
        await storage.setString(ACCESS_TOKEN_KEY, tokens['access_token']);
        print('Token đã được refresh.');
      } else {
        print('Lỗi refresh token: ${response.body}');
        await clearTokens(); // Xóa token nếu refresh thất bại
      }
    } catch (e) {
      print('Lỗi xử lý refresh token: $e');
    }
  }

  // Hàm điều hướng đến home screen
  void navigateToHome() {
    Navigator.pushReplacementNamed(
      navigatorKey.currentContext!,
      '/home',
    );
  }

  // Hàm lấy token đã lưu
  Future<String?> getStoredAccessToken() => storage.getString(ACCESS_TOKEN_KEY);

  Future<String?> getStoredIdToken() async {
    String? token = await storage.getString(ID_TOKEN_KEY);
    return token;
  }

  Future<String?> getStoredRefreshToken() =>
      storage.getString(REFRESH_TOKEN_KEY);

  Future<void> clearTokens() async {
    await storage.remove(ACCESS_TOKEN_KEY);
    await storage.remove(ID_TOKEN_KEY);
    await storage.remove(REFRESH_TOKEN_KEY);
  }
}
