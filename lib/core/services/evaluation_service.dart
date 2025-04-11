import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_slchess/core/models/evaluation_model.dart';
import 'package:flutter_slchess/core/constants/constants.dart';
import 'package:chess/chess.dart';

class EvaluationService {
  final WebSocketChannel channel;

  EvaluationService._(this.channel);

  factory EvaluationService.startGame(String idToken) {
    final channel = IOWebSocketChannel.connect(
      Uri.parse(WebsocketConstants.wsUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': idToken,
      },
    );
    return EvaluationService._(channel);
  }

  void listen(
      {void Function(EvaluationModel evaluationModel)? onEvaluation,
      required BuildContext context}) {
    channel.stream.listen((message) {
      try {
        final data = jsonDecode(message);
        final evaluationModel = EvaluationModel.fromJson(data);
        onEvaluation?.call(evaluationModel);
      } catch (e) {
        print(e);
      }
    });
  }

  void sendEvaluation(String fen) {
    channel.sink.add(jsonEncode({
      'action': 'evaluate',
      'message': fen,
    }));
  }

  void close() {
    channel.sink.close();
  }

  List<dynamic> convertUciToSan(String uciMoves, String initialFen) {
    final chess = Chess.fromFEN(initialFen);
    final moves = uciMoves.split(' ');

    for (final move in moves) {
      if (move.length == 4) {
        final from = move.substring(0, 2);
        final to = move.substring(2, 4);
        chess.move({'from': from, 'to': to});
      }
    }

    return chess.getHistory();
  }
}

void main() {
  final service = EvaluationService.startGame('your_token');
  const uciMoves =
      "c1h6 g7h6 d4d5 f8g7 h3f4 e8g8 e2e3 g4d7 f4h5 g7h8 a1a2 d8a5 b1d2 f6f5 f1d3 a5c3 c2b1 a7a5 e1g1 b8a6 d2f3 a6c7 f3h4";
  final sanMoves = service.convertUciToSan(uciMoves,
      'rn1qkb1r/pp2p1pp/3p1p1n/2p5/2PP2b1/PP5N/2Q1PPPP/RNB1KB1R w KQkq - 0 4');
  print(sanMoves);
}
