import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import '../../main.dart';
import './userService.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class CognitoAuth {
  late AppLinks _appLinks;
  final EncryptedSharedPreferences storage = EncryptedSharedPreferences();
  final userService = UserService();

  final cognitoUrl = dotenv.env['COGNITO_URL'];
  final cognitoClientId = dotenv.env['COGNITO_CLIENT_ID'];
  final redirectUri =
      kIsWeb ? '${Uri.base.origin}/callback' : 'slchess://callback';

  static const String ACCESS_TOKEN_KEY = "ACCESS_TOKEN";
  static const String ID_TOKEN_KEY = "ID_TOKEN";
  static const String REFRESH_TOKEN_KEY = "REFRESH_TOKEN";
  static const String USER_INFO_KEY = "USER_INFO";

  Future<void> initAppLinks() async {
    _appLinks = AppLinks();

    await _checkTokenAndNavigate();

    final uri = await _appLinks.getInitialAppLink();

    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri?.queryParameters['code'] != null) {
        getToken(uri!.queryParameters['code']!);
      }
    });

    try {
      if (uri?.queryParameters['code'] != null) {
        final lastProcessedCode =
            await storage.getString("LAST_PROCESSED_CODE");
        final currentCode = uri!.queryParameters['code']!;

        if (lastProcessedCode != currentCode) {
          await storage.setString("LAST_PROCESSED_CODE", currentCode);
          getToken(currentCode);
        } else {
          print('Code này đã được xử lý trước đó, bỏ qua');
        }
      }
    } catch (e) {
      print('Lỗi lấy initial link: $e');
    }
  }

  Future<void> _checkTokenAndNavigate() async {
    final accessToken = await getStoredAccessToken();
    final refreshToken = await getStoredRefreshToken();

    if (accessToken != null && !await isTokenExpired(accessToken)) {
      navigateToHome();
    } else if (refreshToken != null && !await isTokenExpired(refreshToken)) {
      await this.refreshToken();
      navigateToHome();
    } else {
      print("Token đã hết hạn hoặc không tồn tại");

      final currentRoute =
          ModalRoute.of(navigatorKey.currentContext!)?.settings.name;
      if (currentRoute != '/login') {
        Navigator.pushReplacementNamed(
          navigatorKey.currentContext!,
          '/login',
        );
      }
    }
  }

  Future<void> handleLogin() async {
    try {
      final url = Uri.https(
        cognitoUrl!,
        'login',
        {
          'client_id': cognitoClientId,
          'redirect_uri': redirectUri,
          'response_type': 'code',
          'scope': 'email openid phone',
        },
      );

      await launchUrl(url);
    } catch (e) {
      print('Lỗi đăng nhập: $e');
    }
  }

  Future<void> getToken(String code) async {
    try {
      final tokenResponse = await http.post(
        Uri.https(cognitoUrl!, '/oauth2/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': cognitoClientId,
          'code': code,
          'redirect_uri': redirectUri,
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokens = json.decode(tokenResponse.body);

        await Future.wait([
          storage.setString(ACCESS_TOKEN_KEY, tokens['access_token']),
          storage.setString(ID_TOKEN_KEY, tokens['id_token']),
          storage.setString(REFRESH_TOKEN_KEY, tokens['refresh_token']),
        ]);

        await userService.saveSelfUserInfo(
          tokens['access_token'],
          tokens['id_token'],
        );

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
        await Future.wait([
          storage.setString(ACCESS_TOKEN_KEY, tokens['access_token']),
          storage.setString(ID_TOKEN_KEY, tokens['id_token']),
        ]);
        print('Token đã được refresh.');

        navigateToHome();
      } else {
        print('Lỗi refresh token: ${response.body}');
        await clearTokens();
      }
    } catch (e) {
      print('Lỗi xử lý refresh token: $e');
    }
  }

  void navigateToHome() {
    Navigator.pushReplacementNamed(
      navigatorKey.currentContext!,
      '/home',
    );
  }

  Future<bool> isTokenExpired(String? token) async {
    if (token == null || token.isEmpty) {
      return true;
    }

    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      print('Lỗi khi kiểm tra token hết hạn: $e');
      return true;
    }
  }

  Future<String?> getStoredAccessToken() => storage.getString(ACCESS_TOKEN_KEY);
  Future<String?> getStoredIdToken() => storage.getString(ID_TOKEN_KEY);
  Future<String?> getStoredRefreshToken() =>
      storage.getString(REFRESH_TOKEN_KEY);

  Future<void> clearTokens() async {
    try {
      await storage.remove(ACCESS_TOKEN_KEY);
      await storage.remove(ID_TOKEN_KEY);
      await storage.remove(REFRESH_TOKEN_KEY);

      // Xóa thông tin người dùng từ Hive
      await userService.clearUserData();

      print("Đã xóa token và thông tin người dùng");
    } catch (e) {
      print("Lỗi khi xóa token: $e");
      rethrow;
    }
  }
}
