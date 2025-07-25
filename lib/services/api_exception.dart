class ApiException implements Exception {
  final String code; // ör. TOKEN_ERROR, TIMEOUT, UNKNOWN
  final String message;
  final int? statusCode; // HTTP hata kodu (varsa)

  ApiException(this.code, this.message, {this.statusCode});

  @override
  String toString() => 'Hata kodu:($code): $message';
}
