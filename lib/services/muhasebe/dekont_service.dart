// lib/services/muhasebe/dekont_service.dart
//
// Havale/EFT: kulübün banka hesapları ve üyenin dekontları. Dekont işleme
// (onay, bağlama, ret) yalnız web'de; mobilde yalnız üye uçları var.

import 'dart:convert';
import 'dart:typed_data';

import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/6_muhasebe/banka_hesabi_model.dart';
import 'package:fitcall/models/6_muhasebe/dekont_model.dart';
import 'package:fitcall/services/api_client.dart';

class DekontDosyasi {
  final String ad;
  final String tur;
  final Uint8List baytlar;

  const DekontDosyasi({required this.ad, required this.tur, required this.baytlar});

  bool get pdfMi => tur == 'application/pdf';
}

class DekontService {
  static Future<List<BankaHesabiModel>> hesaplar() async {
    final res = await ApiClient.postParsed<List<BankaHesabiModel>>(
      uyeBankaHesaplariUrl,
      const {},
      BankaHesabiModel.listFromJson,
    );
    return res.data ?? const [];
  }

  static Future<DekontlarimSonucu> dekontlarim() async {
    final res = await ApiClient.postParsed<DekontlarimSonucu>(
      uyeDekontlarimUrl,
      const {},
      DekontlarimSonucu.fromJson,
    );
    return res.data ??
        const DekontlarimSonucu(dekontlar: [], bekleyenSayisi: 0);
  }

  /// Dekontu yükler. [beyanTutar] ve [aciklama] isteğe bağlı.
  static Future<DekontModel?> yukle({
    required List<int> baytlar,
    required String dosyaAdi,
    required String dosyaTuru,
    String? beyanTutar,
    String? aciklama,
  }) async {
    final alanlar = <String, String>{
      if (beyanTutar != null && beyanTutar.trim().isNotEmpty)
        'beyan_tutar': beyanTutar.trim(),
      if (aciklama != null && aciklama.trim().isNotEmpty)
        'aciklama': aciklama.trim(),
    };
    final res = await ApiClient.postDosyaParsed<DekontModel>(
      uyeDekontYukleUrl,
      dosyaAlani: 'dosya',
      baytlar: baytlar,
      dosyaAdi: dosyaAdi,
      dosyaTuru: dosyaTuru,
      alanlar: alanlar,
      parser: (json) =>
          DekontModel.fromJson((json as Map).cast<String, dynamic>()),
    );
    return res.data;
  }

  static Future<String> geriCek(int dekontId) async {
    final res = await ApiClient.postParsed<void>(
      uyeDekontGeriCekUrl,
      {'dekont_id': dekontId},
      (_) {},
    );
    return res.mesaj;
  }

  static Future<DekontDosyasi> dosya(int dekontId) async {
    final res = await ApiClient.postParsed<DekontDosyasi>(
      uyeDekontDosyaUrl,
      {'dekont_id': dekontId},
      (json) {
        final m = (json as Map).cast<String, dynamic>();
        return DekontDosyasi(
          ad: (m['dosya_adi'] ?? 'dekont').toString(),
          tur: (m['dosya_turu'] ?? '').toString(),
          baytlar: base64Decode((m['icerik_b64'] ?? '').toString()),
        );
      },
      timeout: const Duration(seconds: 45),
    );
    return res.data!;
  }
}
