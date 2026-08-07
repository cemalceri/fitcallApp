// lib/screens/1_common/hakedis/hakedis_ay_panosu_page.dart
//
// Hakediş ay panosu — yönetici ve antrenör tarafında ORTAK ekran.
//
// Hangi antrenörün verisi geleceğini [kaynak] belirler (bkz.
// hakedis_veri_kaynagi.dart): yönetici seçtiği antrenörü, antrenör yalnız
// kendini görür. Ekranın kendisi rolden habersizdir.
//
// 12 ayın tamamı tek istekte gelir; ay şeridinde gezinmek yeniden istek
// atmaz — sadece seçili index değişir. Yerleşim HakedisAyPanosu'nda
// (bu sayfa initState'te API çağırdığı için taşma testine giremiyor).

import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:fitcall/screens/1_common/hakedis/hakedis_ders_listesi_page.dart';
import 'package:fitcall/screens/1_common/hakedis/hakedis_veri_kaynagi.dart';
import 'package:fitcall/screens/1_common/hakedis/widgets/hakedis_ay_panosu.dart';
import 'package:fitcall/screens/1_common/hakedis/widgets/hakedis_stil.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:flutter/material.dart';

class HakedisAyPanosuPage extends StatefulWidget {
  final HakedisVeriKaynagi kaynak;

  /// Başlıkta duracak metin. Yönetici antrenörün adını verir; antrenör kendi
  /// ekranında "Hakediş Saatlerim" gibi sabit bir başlık kullanır.
  final String baslik;

  /// Başlığın altındaki açıklama satırı.
  final String altBaslik;

  /// Veri gelince başlık antrenörün gerçek adıyla güncellensin mi?
  /// Yöneticide açık (liste eskiyse ad düzelsin), antrenörde kapalı.
  final bool baslikVeridenGuncellensin;

  /// Açılışta seçili olacak ayın sırası (0 = içinde bulunulan ay).
  ///
  /// Yönetici listeden bir aya bakarken antrenöre dokunduğunda pano aynı ayda
  /// açılsın diye var; kullanıcı ay seçimini iki kez yapmasın.
  final int baslangicAyIndex;

  const HakedisAyPanosuPage({
    super.key,
    required this.kaynak,
    required this.baslik,
    this.altBaslik = 'Hakediş saatleri',
    this.baslikVeridenGuncellensin = false,
    this.baslangicAyIndex = 0,
  });

  @override
  State<HakedisAyPanosuPage> createState() => _HakedisAyPanosuPageState();
}

class _HakedisAyPanosuPageState extends State<HakedisAyPanosuPage> {
  HakedisOzet? _ozet;
  bool _yukleniyor = true;
  String? _hata;
  late int _seciliIndex = widget.baslangicAyIndex;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final sonuc = await widget.kaynak.ozet();
      if (!mounted) return;
      final gelen = sonuc.data;
      setState(() {
        _ozet = gelen;
        // Ay sayısı değişirse (backend penceresi) seçili index taşmasın.
        if (gelen != null && _seciliIndex >= gelen.aylar.length) {
          _seciliIndex = 0;
        }
        _yukleniyor = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.message;
        _yukleniyor = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hata = 'Veriler yüklenirken bir hata oluştu.';
        _yukleniyor = false;
      });
    }
  }

  void _grupAc(HakedisAy ay, String rol, String durum) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HakedisDersListesiPage(
          kaynak: widget.kaynak,
          altBaslik: _baslik,
          yil: ay.yil,
          ay: ay.ay,
          ayEtiketi: ay.etiket,
          rol: rol,
          durum: durum,
        ),
      ),
    );
  }

  String get _baslik {
    if (widget.baslikVeridenGuncellensin) {
      final ad = _ozet?.antrenor.adSoyad;
      if (ad != null && ad.isNotEmpty) return ad;
    }
    return widget.baslik;
  }

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final ozet = _ozet;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _baslik,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17),
            ),
            Text(
              widget.altBaslik,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: renk.onSurfaceVariant),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: renk.outlineVariant),
        ),
      ),
      body: SafeArea(
        top: false,
        child: HakedisDurumGovdesi(
          yukleniyor: _yukleniyor,
          hata: _hata,
          bosMu: ozet == null || ozet.aylar.isEmpty,
          bosMesaj: 'Son 12 ayda ders kaydı yok',
          bosIkon: Icons.event_busy_rounded,
          onTekrarDene: _yukle,
          icerik: (_) => HakedisAyPanosu(
            ozet: ozet!,
            seciliIndex: _seciliIndex,
            onAySec: (i) => setState(() => _seciliIndex = i),
            onGrupTap: _grupAc,
            onYenile: _yukle,
          ),
        ),
      ),
    );
  }
}
