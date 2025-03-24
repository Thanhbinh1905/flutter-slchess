import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import './userService.dart';

import '../models/user.dart';

class CognitoAuth {
  late AppLinks _appLinks;
  final storage = const FlutterSecureStorage();
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

  Future<void> getToken(String code) async {
    try {
      final tokenResponse = await http.post(
        Uri.https(
          cognitoUrl!,
          '/oauth2/token',
        ),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'client_id': cognitoClientId,
          'code': code,
          'redirect_uri': 'slchess://callback',
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokens = json.decode(tokenResponse.body);

        // Lưu các token vào secure storage
        await storage.write(
            key: ACCESS_TOKEN_KEY, value: tokens['access_token']);
        await storage.write(key: ID_TOKEN_KEY, value: tokens['id_token']);
        if (tokens['refresh_token'] != null) {
          await storage.write(
              key: REFRESH_TOKEN_KEY, value: tokens['refresh_token']);
        }

        // print('Đã lưu token thành công');

        // Lấy và lưu thông tin người dùng
        await userService.saveSelfUserInfo(
            tokens['access_token'], tokens['id_token']);

        // UserModel? player = await userService.getPlayer();

        // print("player: ${player!.toJson()}");

        // Chuyển đến màn hình home
        navigateToHome();
      } else {
        print('Lỗi lấy token: ${tokenResponse.body}');
      }
    } catch (e) {
      print('Lỗi xử lý token: $e');
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
  Future<String?> getStoredAccessToken() async {
    return await storage.read(key: ACCESS_TOKEN_KEY);
  }

  Future<String?> getStoredIdToken() async {
    return await storage.read(key: ID_TOKEN_KEY);
  }

  // Hàm xóa token (logout)
  Future<void> clearTokens() async {
    await storage.delete(key: ACCESS_TOKEN_KEY);
    await storage.delete(key: ID_TOKEN_KEY);
    await storage.delete(key: REFRESH_TOKEN_KEY);
  }
}
