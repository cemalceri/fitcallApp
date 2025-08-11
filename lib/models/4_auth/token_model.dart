/// Giriş sonucu dönen token
class TokenModel {
  final String accessToken;
  final DateTime expireDate;

  TokenModel({required this.accessToken, required this.expireDate});

  factory TokenModel.fromMap(Map<String, dynamic> json) {
    return TokenModel(
      accessToken: json['access_token'] as String,
      expireDate: DateTime.parse(json['expire_date'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'expire_date': expireDate.toIso8601String(),
      };
}
