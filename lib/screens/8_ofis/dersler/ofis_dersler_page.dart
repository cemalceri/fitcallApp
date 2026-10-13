// lib/screens/8_ofis/dersler/ofis_dersler_page.dart
//
// Ofis "Dersler" — web /etkinlik/ders-yonetimi sayfasının mobil karşılığı.
// Kabukta sekme olarak açılır; Ana Sayfa'daki bekleyen işlerden belirli bir
// gün ve süzgeçle de itilir. Görünüm OfisDerslerGorunumu'nda; burada yalnız
// API, tarih/süzgeç ve gezinme var.

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/10_ofis/ofis_ders_yonetimi_models.dart';
import 'package:fitcall/screens/8_ofis/dersler/widgets/ders_yonetim_sheet.dart';
import 'package:fitcall/screens/8_ofis/dersler/widgets/ofis_dersler_gorunumu.dart';
import 'package:fitcall/screens/8_ofis/plan_disi/plan_disi_kararlar_page.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/ofis/ofis_ders_yonetimi_service.dart';
import 'package:flutter/material.dart';

class OfisDerslerPage extends StatefulWidget {
  final DateTime? baslangicTarihi;
  final DersSuzgeci baslangicSuzgeci;

  const OfisDerslerPage({
    super.key,
    this.baslangicTarihi,
    this.baslangicSuzgeci = DersSuzgeci.tumu,
  });

  @override
  State<OfisDerslerPage> createState() => OfisDerslerPageState();
}

class OfisDerslerPageState extends State<OfisDerslerPage> {
  late DateTime _tarih = widget.baslangicTarihi ?? bugunKulup();
  late DersSuzgeci _suzgec = widget.baslangicSuzgeci;
  DersYonetimiGun? _gun;
  bool _yukleniyor = true;
  String? _hata;
  bool _topluOnay = false;

  /// Geç dönen eski gün cevabı yeni seçilen günün üstüne yazmasın.
  int _istekNo = 0;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  /// Sekmeye dönünce / uygulama öne gelince: iskeletsiz tazeler.
  void sessizYenile() => _yukle(iskelet: false);

  /// Ana Sayfa'daki "Bugün" kartından gelince: bugün, tüm dersler.
  void bugune() {
    setState(() => _suzgec = DersSuzgeci.tumu);
    _gunDegistir(bugunKulup());
  }

  Future<void> _yukle({bool iskelet = true}) async {
    final no = ++_istekNo;
    setState(() {
      if (iskelet) _yukleniyor = true;
      _hata = null;
    });
    try {
      final gun = await OfisDersYonetimiService.gun(_tarih);
      if (!mounted || no != _istekNo) return;
      setState(() {
        _gun = gun;
        _yukleniyor = false;
      });
    } on ApiException catch (e) {
      if (!mounted || no != _istekNo) return;
      // Tazelemede (işlem sonrası, sekmeye dönüş) hata: eldeki liste silinmez.
      if (!iskelet && _gun != null) {
        setState(() => _yukleniyor = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
        return;
      }
      setState(() {
        _hata = e.message;
        _yukleniyor = false;
      });
    }
  }

  void _gunDegistir(DateTime yeni) {
    setState(() => _tarih = DateTime(yeni.year, yeni.month, yeni.day));
    _yukle();
  }

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime(2024),
      lastDate: bugunKulup().add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
    );
    if (secilen != null) _gunDegistir(secilen);
  }

  /// Sayfadaki dersin güncel hâli (işlemden sonra sayfa tazelenir).
  /// Tazeleme başarısızsa null: sayfa "güncel değil" der.
  Future<YonetimDersi?> _dersiTazele(int id) async {
    try {
      final gun = await OfisDersYonetimiService.gun(_tarih);
      if (!mounted || gun == null) return null;
      setState(() => _gun = gun);
      for (final d in gun.dersler) {
        if (d.id == id) return d;
      }
    } on ApiException {
      return null;
    }
    return null;
  }

  Future<void> _dersSec(YonetimDersi ders) async {
    await dersYonetimSayfasiAc(
      context,
      ders: ders,
      nedenler: _gun?.yapilmadiNedenleri ?? const [],
      yenile: () => _dersiTazele(ders.id),
      onPlanDisi: _planDisiAc,
    );
  }

  Future<void> _planDisiAc() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlanDisiKararlarPage()),
    );
    if (mounted) _yukle(iskelet: false);
  }

  Future<void> _topluOnayla() async {
    final sayi = _gun?.topluOnaylanabilir ?? 0;
    if (sayi == 0) return;
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Dersleri onayla'),
        content: Text(
          'Antrenörün "yapıldı" dediği $sayi ders "Yapıldı" olarak onaylanacak. '
          'Antrenörün yapılmadı dediği ya da bildirmediği derslere dokunulmaz.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Onayla')),
        ],
      ),
    );
    if (onay != true || !mounted) return;
    setState(() => _topluOnay = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final mesaj = await OfisDersYonetimiService.gunuOnayla(_tarih);
      messenger.showSnackBar(SnackBar(content: Text(mesaj)));
      await _yukle(iskelet: false);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _topluOnay = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: OfisDerslerGorunumu(
          tarih: _tarih,
          gun: _gun,
          yukleniyor: _yukleniyor,
          hata: _hata,
          suzgec: _suzgec,
          topluOnayDevam: _topluOnay,
          geriVar: Navigator.of(context).canPop(),
          // Takvim günüyle: Duration(days: 1) yaz saati geçişinde aynı güne
          // dönebiliyor (yurt dışındaki cihaz).
          onOnceki: () =>
              _gunDegistir(DateTime(_tarih.year, _tarih.month, _tarih.day - 1)),
          onSonraki: () =>
              _gunDegistir(DateTime(_tarih.year, _tarih.month, _tarih.day + 1)),
          onTarihSec: _tarihSec,
          onBugun: () => _gunDegistir(bugunKulup()),
          onSuzgec: (s) => setState(() => _suzgec = s),
          onDersSec: _dersSec,
          onTopluOnay: _topluOnayla,
          onYenile: () => _yukle(iskelet: false),
          onYenidenDene: _yukle,
        ),
      ),
    );
  }
}
