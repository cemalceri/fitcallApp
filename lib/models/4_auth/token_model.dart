import 'dart:convert';

/// Giriş sonucu dönen token bilgisini içeren model
class TokenModel {
  final String accessToken;
  final DateTime expireDate;

  TokenModel({
    required this.accessToken,
    required this.expireDate,
  });

  factory TokenModel.fromJson(dynamic response) {
    var jsonData = jsonDecode(utf8.decode(response.bodyBytes));
    return TokenModel(
      accessToken: jsonData['access_token'],
      expireDate: DateTime.parse(jsonData['expire_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'expire_date': expireDate.toIso8601String(),
    };
  }
}
