// lib/screens/7_yonetici/ekip/ekip_detay_page.dart
//
// Bir ofis çalışanının bir günü: giriş saati, işlem dağılımı ve zaman sıralı
// akış. Gün okla ya da takvimden değişir; bugünden ileri gidilmez.

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/ekip_models.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/7_yonetici/ekip/widgets/ekip_gorunumu.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EkipDetayPage extends StatefulWidget {
  final int kullaniciId;
  final String adSoyad;

  const EkipDetayPage({
    super.key,
    required this.kullaniciId,
    required this.adSoyad,
  });

  @override
  State<EkipDetayPage> createState() => _EkipDetayPageState();
}

class _EkipDetayPageState extends State<EkipDetayPage> {
  late DateTime _gun = bugunKulup();
  EkipDetayData? _data;
  bool _yukleniyor = true;
  String? _hata;
  int _istekNo = 0;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  /// [onceki]: gün değişimiyle çağrıldıysa önceki gün. İstek başarısız olursa
  /// tarih ona döner ki başlıktaki gün ile akış birbirini tutsun.
  Future<void> _yukle({DateTime? onceki}) async {
    final no = ++_istekNo;
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final sonuc = await YoneticiApiService.getEkipDetay(
        kullaniciId: widget.kullaniciId,
        gun: _gun,
      );
      if (!mounted || no != _istekNo) return;
      setState(() {
        _data = sonuc.data;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted || no != _istekNo) return;
      final mesaj = e is ApiException ? e.message : 'İşlemler alınamadı.';
      setState(() {
        if (onceki != null) _gun = onceki;
        _hata = mesaj;
        _yukleniyor = false;
      });
      if (_data != null) ShowMessage.error(context, mesaj);
    }
  }

  bool get _bugunMu => DateUtils.isSameDay(_gun, bugunKulup());

  void _gunDegistir(DateTime gun) {
    final bugun = bugunKulup();
    final yeni = DateUtils.dateOnly(gun.isAfter(bugun) ? bugun : gun);
    if (DateUtils.isSameDay(yeni, _gun)) return;
    final onceki = _gun;
    _gun = yeni;
    _yukle(onceki: _data == null ? null : onceki);
  }

  Future<void> _gunSec() async {
    final bugun = bugunKulup();
    final secilen = await showDatePicker(
      context: context,
      initialDate: _gun,
      firstDate: DateTime(bugun.year - 2),
      lastDate: bugun,
      locale: const Locale('tr', 'TR'),
    );
    if (secilen != null) _gunDegistir(secilen);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final gunYazi = _bugunMu
        ? 'Bugün'
        : DateFormat('d MMMM y, EEEE', 'tr_TR').format(_gun);
    return Scaffold(
      appBar: AppBar(title: Text(widget.adSoyad)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Önceki gün',
                  onPressed: () =>
                      _gunDegistir(_gun.subtract(const Duration(days: 1))),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _gunSec,
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      gunYazi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Sonraki gün',
                  onPressed: _bugunMu
                      ? null
                      : () => _gunDegistir(_gun.add(const Duration(days: 1))),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          Expanded(child: _icerik()),
        ],
      ),
    );
  }

  Widget _icerik() {
    final data = _data;
    if (_yukleniyor && data == null) {
      return const IskeletKart(anaKartYuksekligi: 120);
    }
    if (_hata != null && data == null) {
      return BosDurum(
        ikon: Icons.error_outline_rounded,
        baslik: 'İşlemler alınamadı',
        aciklama: _hata!,
        eylemEtiketi: 'Tekrar dene',
        eylemIkonu: Icons.refresh_rounded,
        onEylem: _yukle,
        ikonRengi: context.cs.error,
      );
    }
    if (data == null) return const SizedBox.shrink();
    return RefreshIndicator(
      onRefresh: _yukle,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.s, Bosluk.l, Bosluk.xl),
        child: AnimatedOpacity(
          opacity: _yukleniyor ? 0.5 : 1,
          duration: const Duration(milliseconds: 150),
          child: EkipDetayGorunumu(data: data, bugun: bugunKulup()),
        ),
      ),
    );
  }
}
