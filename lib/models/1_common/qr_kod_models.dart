import 'dart:convert';

class QrKodVerifyResponse {
  final bool success;
  final String message;
  final String? gecerlilikSuresi;
  final int? kalanGirisHakki;

  QrKodVerifyResponse({
    required this.success,
    required this.message,
    this.gecerlilikSuresi,
    this.kalanGirisHakki,
  });

  /// Esnek parse: farklı backend formatlarına toleranslı
  factory QrKodVerifyResponse.fromAny(dynamic json,
      {bool defaultSuccess = false}) {
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      final msg = (map['message'] ?? map['mesaj'] ?? '').toString();
      final sure = (map['gecerlilik_suresi'] ?? map['valid_until']) as String?;
      final kalan = map['kalan_giris_hakki_sayisi'];
      final successVal = map['success'];
      final ok = successVal is bool ? successVal : defaultSuccess;
      return QrKodVerifyResponse(
        success: ok,
        message:
            msg.isNotEmpty ? msg : (ok ? 'İşlem başarılı' : 'İşlem başarısız'),
        gecerlilikSuresi: sure,
        kalanGirisHakki: (kalan is int) ? kalan : null,
      );
    }
    // Beklenmeyen gövde
    return QrKodVerifyResponse(
      success: defaultSuccess,
      message: defaultSuccess ? 'İşlem başarılı' : 'İşlem başarısız',
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'gecerlilik_suresi': gecerlilikSuresi,
        'kalan_giris_hakki_sayisi': kalanGirisHakki,
      };

  @override
  String toString() => jsonEncode(toJson());
}
