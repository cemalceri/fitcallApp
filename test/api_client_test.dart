// Hata yanıtı gövdesinden kullanıcıya gösterilecek mesaj: backend'in
// message/detail alanı öncelikli; HTML hata sayfası (Heroku/nginx, 413)
// ekrana basılmaz.

import 'package:fitcall/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiClient.hataGovdesiniCoz', () {
    test('backend kodu ve mesajı korunur', () {
      expect(
          ApiClient.hataGovdesiniCoz(
              400, '{"code": "TEYIT_DEGISTIRME_YASAK", "message": "Geç"}'),
          ('TEYIT_DEGISTIRME_YASAK', 'Geç'));
    });

    test('message yoksa detail', () {
      expect(ApiClient.hataGovdesiniCoz(401, '{"detail": "Token geçersiz"}'),
          ('HTTP_ERROR', 'Token geçersiz'));
    });

    test('HTML hata sayfası gösterilmez, duruma göre genel mesaj', () {
      const html = '<html><head><title>413 Request Entity Too Large</title>'
          '</head><body><h1>413</h1></body></html>';
      expect(ApiClient.hataGovdesiniCoz(413, html).$2, 'Dosya çok büyük.');
      expect(ApiClient.hataGovdesiniCoz(503, '<!DOCTYPE html><p>x</p>').$2,
          contains('Sunucuda bir sorun'));
    });

    test('kısa düz metin olduğu gibi, uzun metin genel mesaj', () {
      expect(ApiClient.hataGovdesiniCoz(400, 'Geçersiz tarih').$2,
          'Geçersiz tarih');
      expect(ApiClient.hataGovdesiniCoz(400, 'x' * 500).$2, 'İşlem başarısız.');
    });

    test('boş gövde', () {
      expect(
          ApiClient.hataGovdesiniCoz(404, '').$2, 'İstenen kayıt bulunamadı.');
    });
  });
}
