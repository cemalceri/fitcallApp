// lib/models/1_common/surum_notu_model.dart
//
// "Neler yeni?" sürüm notu: bir sürümün, AKTİF PROFİLE ait bloğu.
//
// Sunucu kuralları (backend: api/common/surum_notu/metots.py):
//   - Blok zaten role göre süzülmüş gelir; istemci ayrıca süzmez.
//   - Kurulu sürümle BİREBİR eşleşen blok gelir (sürüm penceresi yok).
//   - Gösterilecek bir şey yoksa `data: null` → model hiç kurulmaz.

import 'package:flutter/material.dart';

class SurumNotuBlogu {
  /// Sunucudaki `SurumNotuRolModel.id`; "görüldü" kaydı bununla yazılır.
  final int id;
  final String surum;
  final String rol;
  final String baslik;
  final String altBaslik;
  final List<SurumNotuMaddesi> maddeler;

  const SurumNotuBlogu({
    required this.id,
    required this.surum,
    this.rol = '',
    this.baslik = 'Neler yeni?',
    this.altBaslik = '',
    this.maddeler = const [],
  });

  factory SurumNotuBlogu.fromJson(Map<String, dynamic> json) {
    final ham = json['maddeler'];
    final maddeler = (ham is List)
        ? ham
            .whereType<Map>()
            .map((m) => SurumNotuMaddesi.fromJson(m.cast<String, dynamic>()))
            .toList()
        : <SurumNotuMaddesi>[];
    maddeler.sort((a, b) => a.sira.compareTo(b.sira));

    return SurumNotuBlogu(
      id: (json['id'] as num?)?.toInt() ?? 0,
      surum: (json['surum'] ?? '').toString(),
      rol: (json['rol'] ?? '').toString(),
      baslik: _dolu(json['baslik']) ? json['baslik'].toString() : 'Neler yeni?',
      altBaslik: (json['alt_baslik'] ?? '').toString(),
      maddeler: maddeler,
    );
  }

  static bool _dolu(dynamic v) => v != null && v.toString().trim().isNotEmpty;

  /// Popup başlığının altındaki satır. Sunucu alt başlık yazmadıysa madde
  /// sayısı yazılır — "Sizin için 3 yenilik".
  String get ozet {
    final alt = altBaslik.trim();
    if (alt.isNotEmpty) return alt;
    if (maddeler.isEmpty) return '';
    return 'Sizin için ${maddeler.length} yenilik';
  }

  bool get bos => maddeler.isEmpty;
}

class SurumNotuMaddesi {
  final int id;
  final String baslik;
  final String aciklama;

  /// "Hesabım › fotoğrafa dokun". Boşsa (ör. hata düzeltmeleri) çip çizilmez.
  final String yol;

  /// Sunucudan Material ikon ADI olarak gelir; [ikonVeri] ile çözülür.
  final String ikon;
  final int sira;

  const SurumNotuMaddesi({
    required this.id,
    required this.baslik,
    required this.aciklama,
    this.yol = '',
    this.ikon = '',
    this.sira = 0,
  });

  factory SurumNotuMaddesi.fromJson(Map<String, dynamic> json) {
    return SurumNotuMaddesi(
      id: (json['id'] as num?)?.toInt() ?? 0,
      baslik: (json['baslik'] ?? '').toString(),
      aciklama: (json['aciklama'] ?? '').toString(),
      yol: (json['yol'] ?? '').toString(),
      ikon: (json['ikon'] ?? '').toString(),
      sira: (json['sira'] as num?)?.toInt() ?? 0,
    );
  }

  bool get yolVar => yol.trim().isNotEmpty;

  /// İkon adının karşılığı; tanınmayan ad nötr varsayılana düşer.
  IconData get ikonVeri => surumNotuIkonu(ikon);
}

/// İkon adı → [IconData] BEYAZ LİSTESİ.
///
/// `IconData(codePoint, fontFamily: 'MaterialIcons')` ile dinamik üretmek
/// `--tree-shake-icons` ile derlenen sürümde boş kare çizer (kullanılmayan
/// glifler atılır). Bu yüzden eşleme sabit: sunucu tanınmayan bir ad
/// gönderirse [surumNotuVarsayilanIkon] çizilir, kare değil.
const Map<String, IconData> surumNotuIkonlari = {
  'photo_camera_rounded': Icons.photo_camera_rounded,
  'account_circle_rounded': Icons.account_circle_rounded,
  'manage_search_rounded': Icons.manage_search_rounded,
  'pending_actions_rounded': Icons.pending_actions_rounded,
  'fact_check_rounded': Icons.fact_check_rounded,
  'palette_rounded': Icons.palette_rounded,
  'bug_report_rounded': Icons.bug_report_rounded,
  'calendar_month_rounded': Icons.calendar_month_rounded,
  'notifications_active_rounded': Icons.notifications_active_rounded,
  'payments_rounded': Icons.payments_rounded,
  'qr_code_rounded': Icons.qr_code_rounded,
  'sports_tennis_rounded': Icons.sports_tennis_rounded,
  'speed_rounded': Icons.speed_rounded,
  'insights_rounded': Icons.insights_rounded,
  'people_rounded': Icons.people_rounded,
  'lock_rounded': Icons.lock_rounded,
  'star_rounded': Icons.star_rounded,
  'auto_awesome_rounded': Icons.auto_awesome_rounded,
  'help_rounded': Icons.help_rounded,
  'filter_list_rounded': Icons.filter_list_rounded,
};

const IconData surumNotuVarsayilanIkon = Icons.auto_awesome_rounded;

IconData surumNotuIkonu(String ad) =>
    surumNotuIkonlari[ad.trim()] ?? surumNotuVarsayilanIkon;
