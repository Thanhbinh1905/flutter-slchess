import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthWebViewScreen extends StatefulWidget {
  const AuthWebViewScreen({super.key});

  @override
  State<AuthWebViewScreen> createState() => _AuthWebViewScreenState();
}

class _AuthWebViewScreenState extends State<AuthWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final cognitoUrl = dotenv.env['COGNITO_URL'];
    final cognitoClientId = dotenv.env['COGNITO_CLIENT_ID'];

    if (cognitoUrl == null || cognitoClientId == null) {
      throw Exception('Thiếu thông tin cấu hình Cognito trong file .env');
    }

    final signInUrl = 'https://$cognitoUrl/oauth2/authorize?'
        'client_id=$cognitoClientId'
        '&response_type=code'
        '&scope=email+openid+phone+aws.cognito.signin.user.admin'
        '&redirect_uri=slchess://callback/';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('slchess://callback')) {
              // Xử lý callback URL
              Navigator.of(context).pop(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(signInUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập'),
        backgroundColor: const Color(0xFF0E1416),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
