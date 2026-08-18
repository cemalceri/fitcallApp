// lib/services/core/kayit_service.dart
//
// Giriş öncesi (token'sız) uçlar: üyelik başvurusu ve şifremi unuttum.
// Backend: api/auth/kayit_metots.py
//
// Hepsi `auth: false` — kullanıcının henüz oturumu yok.

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/4_auth/kayit_secenekleri_model.dart';
import 'package:fitcall/models/4_auth/sifre_sifirlama_model.dart';
import 'package:fitcall/services/api_client.dart';
import 'package:fitcall/services/api_result.dart';

/// Başvurunun sonucu: yeni kayıt mı, yoksa aynı kişi zaten sırada mı?
enum BasvuruDurumu { olusturuldu, mevcut }

class BasvuruSonucu {
  final BasvuruDurumu durum;

  /// Kullanıcıya gösterilecek metin — backend yazıyor, mobil kopyalamıyor.
  final String mesaj;

  const BasvuruSonucu({required this.durum, required this.mesaj});
}

class KayitService {
  /// Formun açılır listeleri (kulüpler, okullar, seçenekler).
  static Future<KayitSecenekleri> secenekler() async {
    final res = await ApiClient.getParsed<KayitSecenekleri>(
      kayitFormVerileriUrl,
      (json) => ApiParsing.parseObject(json, KayitSecenekleri.fromJson),
      auth: false,
    );
    return res.data ??
        const KayitSecenekleri(
          isletmeler: [],
          okullar: [],
          cinsiyetler: [],
          tenisGecmisi: [],
          programTercihleri: [],
        );
  }

  /// Üyelik başvurusunu gönderir. Doğrulama hatası `ApiException` olarak gelir.
  static Future<BasvuruSonucu> basvuruGonder(Map<String, dynamic> alanlar) async {
    final res = await ApiClient.postParsed<String>(
      uyeBasvuruUrl,
      alanlar,
      (json) => ((json as Map?)?['durum'] ?? 'olusturuldu').toString(),
      auth: false,
    );
    return BasvuruSonucu(
      durum: res.data == 'mevcut'
          ? BasvuruDurumu.mevcut
          : BasvuruDurumu.olusturuldu,
      mesaj: res.mesaj,
    );
  }

  /// Kullanıcı adı ya da cep telefonuyla sıfırlama akışını başlatır.
  static Future<SifreSifirlamaSonucu> sifremiUnuttum(String identifier) async {
    final res = await ApiClient.postParsed<SifreSifirlamaSonucu>(
      sifremiUnuttumUrl,
      {'identifier': identifier},
      (json) => ApiParsing.parseObject(json, SifreSifirlamaSonucu.fromJson),
      auth: false,
    );
    return res.data!;
  }

  /// Numaraya bağlı birden çok hesap varken seçilen hesaba link gönderir.
  static Future<SifreSifirlamaSonucu> secilenHesabaGonder({
    required String identifier,
    required int userId,
  }) async {
    final res = await ApiClient.postParsed<SifreSifirlamaSonucu>(
      sifreSifirlamaGonderUrl,
      {'identifier': identifier, 'user_id': userId},
      (json) => ApiParsing.parseObject(json, SifreSifirlamaSonucu.fromJson),
      auth: false,
    );
    return res.data!;
  }
}
