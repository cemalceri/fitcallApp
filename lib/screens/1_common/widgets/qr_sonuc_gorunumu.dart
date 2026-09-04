// lib/screens/1_common/widgets/qr_sonuc_gorunumu.dart
//
// QR doğrulama sonuç ekranı.
//
// Bu ekran kapıda, ayakta, arka arkaya kullanılıyor: görevlinin telefona
// yaklaşmadan "geçti mi geçmedi mi" görmesi gerekiyor. Bu yüzden sonuç tek bir
// kart değil, tüm gövdeyi kaplayan renkli bir panel; durum rengi ekranın
// tamamından okunuyor.
//
// Hata mesajını olduğu gibi basmak yetmiyordu ("kayıt bulunamadı" görevliye ne
// yapacağını söylemiyor). Backend'in hata KODU başlığa, ikona, renge ve bir
// "şimdi ne yapmalı" satırına çevriliyor.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Doğrulama sonucunun anlamı. Renk/ikon/başlık bundan türer.
enum QrSonucTipi {
  basarili,
  suresiDolmus,
  bulunamadi,
  gecersiz,
  iptalEdilmis,
  etkinlikUygunDegil,
  hata,
}

/// Ekranın çizeceği tek veri paketi.
class QrSonucu {
  final QrSonucTipi tip;

  /// Backend'in kendi mesajı. Başarıda kişinin adını taşır
  /// ("Hoşgeldiniz, Ayşe Yılmaz" / "Misafir (Ayşe misafiri)"), bu yüzden
  /// başarıda ekranın kahraman satırı odur.
  final String mesaj;

  /// Okutma anı — görevli "az önce mi okuttum" diye bakıyor.
  final DateTime zaman;

  const QrSonucu({
    required this.tip,
    required this.mesaj,
    required this.zaman,
  });

  bool get basarili => tip == QrSonucTipi.basarili;

  /// Backend hata kodunu ekran durumuna çevirir.
  ///
  /// Kodlar `api/common/qr_code/metots.py` içindeki
  /// UygulamadanOkutulanQRKodDogrulaApiView'dan geliyor.
  factory QrSonucu.hatadan(ApiException hata, {DateTime? zaman}) {
    final tip = switch (hata.code) {
      'QR_EXPIRED' => QrSonucTipi.suresiDolmus,
      'QR_NOT_FOUND' => QrSonucTipi.bulunamadi,
      'INVALID_QR' => QrSonucTipi.gecersiz,
      'ENTRY_CANCELED' => QrSonucTipi.iptalEdilmis,
      'EVENT_PASSIVE' ||
      'EVENT_NOT_STARTED' ||
      'EVENT_FINISHED' =>
        QrSonucTipi.etkinlikUygunDegil,
      _ => QrSonucTipi.hata,
    };
    return QrSonucu(
      tip: tip,
      mesaj: hata.message,
      zaman: zaman ?? DateTime.now(),
    );
  }
}

/// Sonuç panelinin görsel gövdesi — API çağrısı yok, veriyle beslenir
/// (bkz. CLAUDE.md "Layout / overflow discipline").
class QrSonucGorunumu extends StatelessWidget {
  final QrSonucu sonuc;

  /// Birincil eylem: kapıda sıra beklerken hemen bir sonrakini okutmak.
  final VoidCallback onYenidenTara;

  /// İkincil eylem: ekrandan çıkmak.
  final VoidCallback? onBitir;

  const QrSonucGorunumu({
    super.key,
    required this.sonuc,
    required this.onYenidenTara,
    this.onBitir,
  });

  static final _saat = DateFormat('HH:mm', 'tr_TR');

  _SonucStili _stil(BuildContext context) {
    final r = context.renkler;
    return switch (sonuc.tip) {
      QrSonucTipi.basarili => _SonucStili(
          ikon: Icons.check_rounded,
          renk: r.basari,
          zemin: r.basariZemin,
          etiket: 'Giriş onaylandı',
          ipucu: 'Turnikeden geçebilir.',
        ),
      QrSonucTipi.suresiDolmus => _SonucStili(
          ikon: Icons.timer_off_rounded,
          renk: r.uyari,
          zemin: r.uyariZemin,
          etiket: 'Kodun süresi dolmuş',
          ipucu: 'Uygulamasından yeni kod üretmesini isteyin.',
        ),
      QrSonucTipi.bulunamadi => _SonucStili(
          ikon: Icons.search_off_rounded,
          renk: r.hata,
          zemin: r.hataZemin,
          etiket: 'Kayıt bulunamadı',
          ipucu: 'Kod bu tesise ait değil. Üye adıyla kontrol edin.',
        ),
      QrSonucTipi.gecersiz => _SonucStili(
          ikon: Icons.block_rounded,
          renk: r.hata,
          zemin: r.hataZemin,
          etiket: 'Geçersiz kod',
          ipucu: 'Okutulan görsel bir giriş kodu değil.',
        ),
      QrSonucTipi.iptalEdilmis => _SonucStili(
          ikon: Icons.cancel_rounded,
          renk: r.hata,
          zemin: r.hataZemin,
          etiket: 'Giriş iptal edilmiş',
          ipucu: 'Davet geri çekilmiş. Daveti veren üyeye danışın.',
        ),
      QrSonucTipi.etkinlikUygunDegil => _SonucStili(
          ikon: Icons.event_busy_rounded,
          renk: r.uyari,
          zemin: r.uyariZemin,
          etiket: 'Etkinlik uygun değil',
          ipucu: 'Kod bir etkinliğe bağlı; saati henüz gelmemiş ya da geçmiş.',
        ),
      QrSonucTipi.hata => _SonucStili(
          ikon: Icons.error_outline_rounded,
          renk: r.notr,
          zemin: r.notrZemin,
          etiket: 'Doğrulanamadı',
          ipucu: 'Bağlantıyı kontrol edip tekrar deneyin.',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final stil = _stil(context);

    return Container(
      // Durum rengi yukarıdan aşağı sönerek yüzeye karışıyor: ekranın
      // tamamı sonucu söylüyor, kart sınırına bakmak gerekmiyor.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [stil.zemin, cs.surface],
          stops: const [0.0, 0.62],
        ),
      ),
      child: SafeArea(
        // Gövde kayar, eylemler altta sabit durur. Esnek boşluk (Spacer)
        // kaydırılabilir alanda çalışmaz — yükseklik sınırsız olduğu için
        // RenderFlex hata verir; bu yüzden ortalama Center ile yapılıyor.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    Bosluk.xl, Bosluk.xl, Bosluk.xl, Bosluk.l),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _rozet(context, stil),
                      const SizedBox(height: Bosluk.xl),
                      _durumEtiketi(context, stil),
                      const SizedBox(height: Bosluk.m),
                      _kahramanMetin(context),
                      const SizedBox(height: Bosluk.m),
                      _ipucu(context, stil),
                      const SizedBox(height: Bosluk.l),
                      _zamanDamgasi(context),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Bosluk.xl, 0, Bosluk.xl, Bosluk.l),
              child: _eylemler(context, stil),
            ),
          ],
        ),
      ),
    );
  }

  /// İçi dolu daire + çevresinde iki halka: uzaktan bakışta ilk yakalanan şey.
  Widget _rozet(BuildContext context, _SonucStili stil) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(Bosluk.m),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: stil.renk.withValues(alpha: 0.10),
        ),
        child: Container(
          padding: const EdgeInsets.all(Bosluk.s),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: stil.renk.withValues(alpha: 0.16),
          ),
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: stil.renk,
            ),
            child: Icon(stil.ikon, size: 48, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _durumEtiketi(BuildContext context, _SonucStili stil) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Bosluk.m, vertical: Bosluk.xs + 2),
        decoration: BoxDecoration(
          color: stil.renk.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Yaricap.xl),
        ),
        child: Text(
          stil.etiket,
          textAlign: TextAlign.center,
          style: context.metin.labelLarge?.copyWith(
            color: stil.renk,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  /// Başarıda kişinin adı, hatada backend'in açıklaması.
  Widget _kahramanMetin(BuildContext context) {
    return Text(
      sonuc.mesaj,
      textAlign: TextAlign.center,
      style: context.metin.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: context.cs.onSurface,
      ),
    );
  }

  Widget _ipucu(BuildContext context, _SonucStili stil) {
    return Text(
      stil.ipucu,
      textAlign: TextAlign.center,
      style: context.metin.bodyMedium?.copyWith(
        color: context.cs.onSurfaceVariant,
      ),
    );
  }

  Widget _zamanDamgasi(BuildContext context) {
    final cs = context.cs;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 15, color: cs.onSurfaceVariant),
          const SizedBox(width: Bosluk.xs + 2),
          Flexible(
            child: Text(
              'Okutuldu · ${_saat.format(sonuc.zaman)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  context.metin.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  /// Kapıda sıra varken asıl iş "bir sonrakini okut": birincil eylem o.
  Widget _eylemler(BuildContext context, _SonucStili stil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: onYenidenTara,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Sonrakini tara'),
          style: FilledButton.styleFrom(
            backgroundColor: stil.renk,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: Bosluk.l),
            textStyle: context.metin.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Yaricap.l),
            ),
          ),
        ),
        if (onBitir != null) ...[
          const SizedBox(height: Bosluk.s),
          TextButton(
            onPressed: onBitir,
            child: const Text('Bitir'),
          ),
        ],
      ],
    );
  }
}

class _SonucStili {
  final IconData ikon;
  final Color renk;
  final Color zemin;
  final String etiket;
  final String ipucu;

  const _SonucStili({
    required this.ikon,
    required this.renk,
    required this.zemin,
    required this.etiket,
    required this.ipucu,
  });
}
