class ApiConstants {
  static const String identifier = "5m1o9s40ui";
  static String get matchMaking =>
      "https://$identifier.execute-api.ap-southeast-2.amazonaws.com/dev/matchmaking";

  static String get getUserInfo =>
      "https://$identifier.execute-api.ap-southeast-2.amazonaws.com/dev/user";

  static String get getSelfUserInfoUrl =>
      "https://slchess-dev.auth.ap-southeast-2.amazoncognito.com/oauth2/userInfo";
  static String get getUploadImageUrl =>
      "https://$identifier.execute-api.ap-southeast-2.amazonaws.com/dev/avatar/upload";
  static String get getPulzzesUrl =>
      "https://$identifier.execute-api.ap-southeast-2.amazonaws.com/dev/puzzles";
  static String get getPulzzeUrl =>
      "https://$identifier.execute-api.ap-southeast-2.amazonaws.com/dev/puzzle";
}

class WebsocketConstants {
  static const String serverEndpoint = "localhost:7202";

  static String get queueing =>
      "wss://93lhu5pndi.execute-api.ap-southeast-2.amazonaws.com/dev";
  static String get game => "ws://$serverEndpoint/game/";
}

List<Map<String, String>> timeControls = [
  {"key": "1 phút", "value": "1+0"},
  {"key": "1 | 1", "value": "1+1"},
  {"key": "1 | 2", "value": "1+2"},
  {"key": "2 | 1", "value": "2+1"},
  {"key": "2 | 2", "value": "2+2"},
  {"key": "3 phút", "value": "3+0"},
  {"key": "3 | 2", "value": "3+2"},
  {"key": "5 phút", "value": "5+0"},
  {"key": "5 | 3", "value": "5+3"},
  {"key": "5 | 5", "value": "5+5"},
  {"key": "10 phút", "value": "10+0"},
  {"key": "10 | 5", "value": "10+5"},
  {"key": "15 | 10", "value": "15+10"},
  {"key": "25 | 10", "value": "25+10"},
  {"key": "30 phút", "value": "30+0"},
  {"key": "45 | 15", "value": "45+15"},
  {"key": "60 | 30", "value": "60+30"},
];
