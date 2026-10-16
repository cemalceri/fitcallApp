// lib/screens/8_ofis/ana_sayfa/widgets/ofis_ana_sayfa_gorunumu.dart
//
// Ofis Ana Sayfası'nın sunum gövdesi: takım renginde başlık (karşılama,
// bildirim, profil değiştir, çıkış), bugünün özeti (kimlik yüzeyi) ve bekleyen
// işler. Her iş satırı ilgili ekrana götürür. API çağrısı içermez.

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/10_ofis/ofis_ders_yonetimi_models.dart';
import 'package:fitcall/screens/1_common/1_notification/notifications_bell.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/kimlik_yuzeyi.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/1_common/widgets/profil_degistir_butonu.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OfisAnaSayfaGorunumu extends StatelessWidget {
  final String ofisAdi;
  final bool profilDegistir;
  final OfisBekleyenIsler? veri;
  final bool yukleniyor;
  final String? hata;
  final VoidCallback? onMenu;
  final Future<void> Function() onYenile;
  final VoidCallback onYenidenDene;
  final VoidCallback onOnay;
  final VoidCallback onPlanDisi;
  final VoidCallback onTeyit;
  final VoidCallback onBugununDersleri;
  final VoidCallback onDersKayitTalepleri;

  /// Bildirim zili (testte ağ/servis gerektirmeyen yer tutucu verilebilir).
  final Widget zil;

  const OfisAnaSayfaGorunumu({
    super.key,
    required this.ofisAdi,
    required this.profilDegistir,
    required this.veri,
    required this.yukleniyor,
    required this.hata,
    this.onMenu,
    required this.onYenile,
    required this.onYenidenDene,
    required this.onOnay,
    required this.onPlanDisi,
    required this.onTeyit,
    required this.onBugununDersleri,
    required this.onDersKayitTalepleri,
    this.zil = const NotificationsBell(),
  });

  static final _gun = DateFormat('d MMMM EEEE', 'tr_TR');

  String _selam() {
    final s = simdiKulup().hour;
    if (s < 12) return 'Günaydın';
    if (s < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    return RenkliDurumCubugu(
      child: RefreshIndicator(
        onRefresh: onYenile,
        child: ListView(
          // iOS esnemesi renkli başlığın üstünde boşluk açmasın.
          physics: const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            BaslikBandi(
              ustGuvenliAlan: false,
              padding: const EdgeInsets.fromLTRB(8, 8, 4, 12),
              child: _baslik(context),
            ),
            ..._govde(context),
          ],
        ),
      ),
    );
  }

  Widget _baslik(BuildContext context) {
    return Row(
      children: [
        if (onMenu != null)
          Padding(
            padding: const EdgeInsets.only(right: Bosluk.s),
            child: BaslikIkonButonu(
                ikon: Icons.menu_rounded, ipucu: 'Menü', onTap: onMenu!),
          )
        else
          const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_selam(), style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                ofisAdi.isNotEmpty ? ofisAdi : 'Ön büro',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        zil,
        if (profilDegistir) const ProfilDegistirButonu(),
        // Çıkış — üye/antrenör/yönetici başlıklarındakiyle aynı, onaylı.
        BaslikIkonButonu(
          ikon: Icons.logout_rounded,
          ipucu: 'Çıkış yap',
          onTap: () async {
            if (await cikisOnayla(context) && context.mounted) {
              AuthService.logout(context);
            }
          },
        ),
      ],
    );
  }

  List<Widget> _govde(BuildContext context) {
    if (hata != null) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 48),
          child: BosDurum(
            ikon: Icons.error_outline_rounded,
            baslik: 'Bekleyen işler alınamadı',
            aciklama: hata!,
            ikonRengi: context.renkler.hata,
            eylemEtiketi: 'Tekrar dene',
            eylemIkonu: Icons.refresh_rounded,
            onEylem: onYenidenDene,
          ),
        ),
      ];
    }
    if (yukleniyor || veri == null) {
      return const [
        SizedBox(height: 16),
        IskeletListe(satirSayisi: 4, kaydirilabilir: false),
      ];
    }
    final v = veri!;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: _BugunKarti(
            veri: v,
            tarih: _gun.format(bugunKulup()),
            onTap: onBugununDersleri),
      ),
      const ListeGrupBasligi(baslik: 'Bekleyen işler'),
      if (v.isYok)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: BosDurum(
            ikon: Icons.task_alt_rounded,
            baslik: 'Bekleyen iş yok',
            aciklama: 'Ders onayları, kayıt talepleri, plan dışı kararlar '
                've katılım bildirimleri güncel.',
            ikonRengi: context.renkler.basari,
          ),
        )
      else ...[
        _IsSatiri(
          ikon: Icons.fact_check_rounded,
          ton: v.onayBekleyen > 0 ? ListeTonu.uyari : ListeTonu.notr,
          baslik: 'Ders onayı',
          alt: v.onayBekleyen == 0
              ? 'Onay bekleyen ders yok'
              : 'Son ${v.pencereGun} gün · ${v.onayBekleyenAntrenorOnayli} '
                  'tanesini antrenör onayladı',
          sayi: v.onayBekleyen,
          birim: 'ders',
          onTap: onOnay,
        ),
        const ListeAyraci(),
        _IsSatiri(
          ikon: Icons.edit_calendar_rounded,
          ton: v.dersKayitTalebi > 0 ? ListeTonu.uyari : ListeTonu.notr,
          baslik: 'Ders kayıt talepleri',
          alt: v.dersKayitTalebi == 0
              ? 'Bekleyen talep yok'
              : 'Antrenörün programa eklenmesini istediği dersler',
          sayi: v.dersKayitTalebi,
          birim: 'talep',
          onTap: onDersKayitTalepleri,
        ),
        const ListeAyraci(),
        _IsSatiri(
          ikon: Icons.person_add_alt_1_rounded,
          ton: v.planDisiKisi > 0 ? ListeTonu.uyari : ListeTonu.notr,
          baslik: 'Plan dışı / misafir kararı',
          alt: v.planDisiKisi == 0
              ? 'Karar bekleyen kimse yok'
              : '${v.planDisiDers} derste ${v.planDisiKisi} kişi',
          sayi: v.planDisiKisi,
          birim: 'kişi',
          onTap: onPlanDisi,
        ),
        const ListeAyraci(),
        _IsSatiri(
          ikon: Icons.how_to_reg_rounded,
          ton: v.teyitKisi > 0 ? ListeTonu.bilgi : ListeTonu.notr,
          baslik: 'Katılım cevabı bekleyenler',
          alt: v.teyitKisi == 0
              ? 'Bugün ve yarın herkes cevap verdi'
              : _teyitAlt(v),
          sayi: v.teyitKisi,
          birim: 'kişi',
          onTap: onTeyit,
        ),
      ],
    ];
  }
}

/// "Bugün 3 · yarın 4 kişi" — satır iki günü sayıyor, açılan ekran ilk günü.
String _teyitAlt(OfisBekleyenIsler v) {
  final bugun = bugunKulup();
  final parcalar = [
    for (final (gun, kisi) in v.teyitGunleri)
      '${gun == bugun ? 'Bugün' : 'Yarın'} $kisi',
  ];
  return parcalar.isEmpty
      ? 'Bugün ve yarın ${v.teyitDers} derste'
      : '${parcalar.join(' · ')} kişi';
}

class _BugunKarti extends StatelessWidget {
  final OfisBekleyenIsler veri;
  final String tarih;
  final VoidCallback onTap;

  const _BugunKarti({
    required this.veri,
    required this.tarih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KimlikYuzeyi(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bugün · $tarih',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: kimlikYazi(context, context.metin.labelLarge),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.gecis.onKimlik),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${veri.bugunDers} ders',
            style: kimlikYazi(context, context.metin.headlineMedium),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (veri.bugunIptal > 0)
                KimlikKapsulu('${veri.bugunIptal} iptal'),
              KimlikKapsulu(veri.bugunOnayBekleyen > 0
                  ? '${veri.bugunOnayBekleyen} onay bekliyor'
                  : 'Bekleyen onay yok'),
            ],
          ),
        ],
      ),
    );
  }
}

class _IsSatiri extends StatelessWidget {
  final IconData ikon;
  final ListeTonu ton;
  final String baslik;
  final String alt;
  final int sayi;
  final String birim;
  final VoidCallback onTap;

  const _IsSatiri({
    required this.ikon,
    required this.ton,
    required this.baslik,
    required this.alt,
    required this.sayi,
    required this.birim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListeSatiri(
      onGorsel: ListeAvatari(ikon: ikon, ton: ton),
      baslik: baslik,
      altBaslik: alt,
      // Sayı ana yazı renginde: uyarı tonu sayfa zemininde metin eşiğinin
      // altında kalıyor; ton avatarda.
      deger: sayi > 0 ? '$sayi' : null,
      altDeger: sayi > 0 ? birim : null,
      okGoster: true,
      onTap: onTap,
    );
  }
}
