import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class MessageService {
  final WebSocketChannel channel;
  MessageService._(this.channel);

  factory MessageService.startMessage(String conversationId, String idToken) {
    final String endpoint = dotenv.env['REALTIME_URL']!;
    final String host = dotenv.env['APPSYNC_HOST']!;
    final channel = IOWebSocketChannel.connect(
      Uri.parse(endpoint),
      headers: {
        'Sec-WebSocket-Protocol': 'graphql-ws',
        'Authorization': idToken,
        'host': host,
      },
    );
    return MessageService._(channel);
  }

  void listen({
    required void Function(Message message) onMessage,
    required void Function() onStatusChange,
  }) {
    channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'type') {
        onStatusChange();
      } else if (data['type'] == 'data') {
        onMessage(Message.fromJson(data['data']));
      }
    });
  }

  Future<Message?> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    required String senderUsername,
    required String idToken,
  }) async {
    final messageId = const Uuid().v4();
    final String host = dotenv.env['APPSYNC_URL']!;

    const String mutation = r'''
      mutation SendMessage($input: SendMessageInput!) {
        sendMessage(input: $input) {
          Id
          ConversationId
          SenderId
          Username
          Content
          CreatedAt
        }
      }
    ''';

    final variables = {
      "input": {
        "id": messageId,
        "conversationId": conversationId,
        "senderId": senderId,
        "Username": senderUsername,
        "content": content,
      }
    };

    final body = jsonEncode({
      "query": mutation,
      "variables": variables,
    });

    try {
      final response = await http.post(
        Uri.parse(host),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              idToken, // hoặc 'Bearer $idToken' tùy cấu hình AppSync
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errors'] != null) {
          print('GraphQL errors: ${data['errors']}');
          return null;
        }
        final msg = Message.fromJson(data['data']['sendMessage']);
        return msg;
      } else {
        print('Lỗi gửi tin nhắn: ${response.body}');
      }
    } catch (e) {
      print('Lỗi gửi tin nhắn: $e');
    }
    return null;
  }
}
