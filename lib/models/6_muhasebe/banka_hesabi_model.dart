// lib/models/6_muhasebe/banka_hesabi_model.dart
//
// Kulübün havale/EFT için üyeye gösterilen banka hesabı (işletme başına
// birden çok olabilir). Karekod, kulübün banka uygulamasının ürettiği para
// alma karekodunun görselidir.

class BankaHesabiModel {
  final int id;
  final String etiket;
  final String bankaAdi;
  final String aliciAdi;

  /// Boşluksuz IBAN: kopyalanan değer.
  final String iban;

  /// 4'lü gruplu IBAN: ekranda gösterilen değer.
  final String ibanGruplu;
  final String? karekodUrl;

  const BankaHesabiModel({
    required this.id,
    required this.etiket,
    required this.bankaAdi,
    required this.aliciAdi,
    required this.iban,
    required this.ibanGruplu,
    this.karekodUrl,
  });

  factory BankaHesabiModel.fromJson(Map<String, dynamic> json) {
    final iban = (json['iban'] ?? '').toString().replaceAll(' ', '');
    final gruplu = (json['iban_gruplu'] ?? '').toString();
    final karekod = json['karekod_url']?.toString();
    return BankaHesabiModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      etiket: (json['etiket'] ?? '').toString(),
      bankaAdi: (json['banka_adi'] ?? '').toString(),
      aliciAdi: (json['alici_adi'] ?? '').toString(),
      iban: iban,
      ibanGruplu: gruplu.isNotEmpty ? gruplu : ibanGrupla(iban),
      karekodUrl: (karekod == null || karekod.isEmpty) ? null : karekod,
    );
  }

  static List<BankaHesabiModel> listFromJson(dynamic json) {
    final liste = (json is Map ? json['hesaplar'] : json) as List? ?? const [];
    return liste
        .map((e) => BankaHesabiModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}

/// 'TR330006...' → 'TR33 0006 ...' (4'lü gruplar).
String ibanGrupla(String iban) {
  final temiz = iban.replaceAll(RegExp(r'\s'), '').toUpperCase();
  final parcalar = <String>[];
  for (var i = 0; i < temiz.length; i += 4) {
    parcalar.add(temiz.substring(i, i + 4 > temiz.length ? temiz.length : i + 4));
  }
  return parcalar.join(' ');
}
