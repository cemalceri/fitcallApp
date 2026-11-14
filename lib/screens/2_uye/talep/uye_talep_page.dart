// lib/screens/2_uye/talep/uye_talep_page.dart
//
// Yeni ders / kort kiralama talebi: üç adımlı sihirbaz, Taleplerim'in "Yeni
// talep" düğmesinden açılır. Seçimler TalepTaslagi'nda taşınır;
// Taleplerim'deki "Düzenle" ve "Benzerini aç" sihirbazı dolu açar
// (Düzenle'de eski talep yenisi gönderilirken sunucuda geri çekilir).
// Görsel gövdeler widgets/talep_adimlari.dart'ta (API çağırmaz, test edilir).

import 'package:fitcall/models/2_uye/uye_talep_models.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/2_uye/talep/widgets/talep_adimlari.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/uye/uye_talep_service.dart';
import 'package:material_ui/material_ui.dart';

class UyeTalepPage extends StatefulWidget {
  /// Düzenle / Benzerini aç: dolu taslak. Route argümanı olarak da gelir.
  final TalepTaslagi? taslak;

  const UyeTalepPage({super.key, this.taslak});

  @override
  State<UyeTalepPage> createState() => _UyeTalepPageState();
}

class _UyeTalepPageState extends State<UyeTalepPage> {
  late TalepTaslagi _t;
  int _adim = 0;

  TalepBaslangic? _baslangic;
  String? _hata;

  TalepHarita? _harita;
  String? _haritaHata;
  DateTime? _hafta;

  TalepSecenekleri? _secenekler;
  String? _secenekHata;

  final _aciklama = TextEditingController();
  bool _gonderiliyor = false;

  @override
  void initState() {
    super.initState();
    _t = widget.taslak ?? TalepTaslagi();
    _aciklama.text = _t.aciklama;
    _yukle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (widget.taslak == null && arg is TalepTaslagi && _t.tur == null) {
      _t = arg;
      _aciklama.text = arg.aciklama;
    }
  }

  @override
  void dispose() {
    _aciklama.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() => _hata = null);
    try {
      final veri = await UyeTalepService.baslangic(uyeId: _t.uyeId);
      if (!mounted) return;
      setState(() {
        _baslangic = veri;
        _t.uyeId ??= veri.uyeId;
        if (!veri.surelerDk.contains(_t.sureDk) && veri.surelerDk.isNotEmpty) {
          _t.sureDk = veri.surelerDk.first;
        }
        // Dolu açılan taslağın türü artık uygun değilse seçim kalkar.
        if (_t.tur != null && !(veri.secenek(_t.tur!)?.uygun ?? false)) {
          _t.tur = null;
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _hata = e.message);
    } catch (_) {
      if (mounted) setState(() => _hata = 'Bilgiler alınamadı.');
    }
  }

  int get _sureDk {
    if (_t.tur == TalepTuru.telafi) {
      return _baslangic?.secenek(TalepTuru.telafi)?.sabitSureDk ?? _t.sureDk;
    }
    return _t.sureDk;
  }

  Future<void> _haritaYukle() async {
    setState(() {
      _harita = null;
      _haritaHata = null;
    });
    try {
      final h = await UyeTalepService.harita(
        uyeId: _t.uyeId!,
        tur: _t.tur!,
        sureDk: _sureDk,
        antrenorId: _t.antrenorId,
        hafta: _hafta ?? _t.baslangic,
      );
      if (!mounted) return;
      setState(() {
        _harita = h;
        _hafta = h.haftaBaslangic;
        // Seçili saat artık uygun değilse seçim kalkar.
        if (_t.baslangic != null && !_uygunMu(h, _t.baslangic!)) {
          final ayniHafta = !_t.baslangic!.isBefore(h.haftaBaslangic) &&
              _t.baslangic!
                  .isBefore(h.haftaBaslangic.add(const Duration(days: 7)));
          if (ayniHafta) _t.baslangic = null;
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _haritaHata = e.message);
    } catch (_) {
      if (mounted) setState(() => _haritaHata = 'Harita alınamadı.');
    }
  }

  bool _uygunMu(TalepHarita h, DateTime an) {
    for (final g in h.gunler) {
      if (g.tarih.year == an.year &&
          g.tarih.month == an.month &&
          g.tarih.day == an.day) {
        final saat =
            '${an.hour.toString().padLeft(2, '0')}:${an.minute.toString().padLeft(2, '0')}';
        return g.saatler.any((s) => s.saat == saat && s.uygun);
      }
    }
    return false;
  }

  Future<void> _secenekYukle() async {
    setState(() {
      _secenekler = null;
      _secenekHata = null;
    });
    try {
      final s = await UyeTalepService.secenekler(
        uyeId: _t.uyeId!,
        tur: _t.tur!,
        baslangic: _t.baslangic!,
        sureDk: _sureDk,
        degistirilenTalepId: _t.degistirilenTalepId,
      );
      if (!mounted) return;
      setState(() {
        _secenekler = s;
        if (_t.antrenorId != null &&
            !s.hocalar.any((h) => h.id == _t.antrenorId)) {
          _t.antrenorId = null;
        }
        if (_t.kortId != null && !s.kortlar.any((k) => k.id == _t.kortId)) {
          _t.kortId = null;
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _secenekHata = e.message);
    } catch (_) {
      if (mounted) setState(() => _secenekHata = 'Seçenekler alınamadı.');
    }
  }

  void _ileri() {
    setState(() => _adim++);
    if (_adim == 1) _haritaYukle();
    if (_adim == 2) _secenekYukle();
  }

  Future<bool> _geri() async {
    if (_adim == 0) return true;
    setState(() => _adim--);
    return false;
  }

  Future<void> _gonder() async {
    setState(() => _gonderiliyor = true);
    _t.aciklama = _aciklama.text.trim();
    _t.sureDk = _sureDk;
    try {
      final mesaj = await UyeTalepService.olustur(_t);
      if (!mounted) return;
      ShowMessage.success(context, mesaj);
      // Sihirbaz Taleplerim'den açılır; dönünce liste yenilenir.
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } catch (_) {
      if (mounted) ShowMessage.error(context, 'Talep gönderilemedi.');
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  static const _basliklar = ['Yeni talep', 'Ne zaman?', 'Son adım'];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _adim == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _geri();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_basliklar[_adim]),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child:
                LinearProgressIndicator(value: (_adim + 1) / 3, minHeight: 4),
          ),
        ),
        body: SafeArea(top: false, child: _govde()),
      ),
    );
  }

  Widget _govde() {
    final b = _baslangic;
    if (b == null) {
      if (_hata != null) {
        return BosDurum(
          ikon: Icons.error_outline_rounded,
          baslik: 'Açılamadı',
          aciklama: _hata!,
          eylemEtiketi: 'Tekrar dene',
          eylemIkonu: Icons.refresh_rounded,
          onEylem: _yukle,
        );
      }
      return const IskeletListe();
    }
    switch (_adim) {
      case 0:
        return TalepAdim1Gorunumu(
          veri: b,
          seciliTur: _t.tur,
          seciliUyeId: _t.uyeId ?? b.uyeId,
          onUyeSec: (id) {
            if (id == _t.uyeId) return;
            setState(() {
              _t = TalepTaslagi(uyeId: id, sureDk: _t.sureDk);
              _baslangic = null;
            });
            _yukle();
          },
          onTurSec: (tur) => setState(() {
            if (tur != _t.tur) {
              _t.tur = tur;
              _t.baslangic = null;
              if (!TalepTuru.hocali(tur)) _t.antrenorId = null;
            }
          }),
          onDevam:
              (_t.tur != null && b.acikMi && !b.limitDoldu) ? _ileri : null,
          onTaleplerim: () => Navigator.of(context).pop(),
        );
      case 1:
        return TalepAdim2Gorunumu(
          tur: _t.tur!,
          veri: b,
          sureDk: _sureDk,
          antrenorId: _t.antrenorId,
          harita: _harita,
          hata: _haritaHata,
          secili: _t.baslangic,
          onSure: (dk) {
            setState(() => _t.sureDk = dk);
            _haritaYukle();
          },
          onHoca: (id) {
            setState(() => _t.antrenorId = id);
            _haritaYukle();
          },
          onHafta: (yon) {
            _hafta = (_hafta ?? DateTime.now()).add(Duration(days: 7 * yon));
            _haritaYukle();
          },
          onSaatSec: (an) => setState(() => _t.baslangic = an),
          onYenidenDene: _haritaYukle,
          onDevam: _t.baslangic == null ? null : _ileri,
        );
      default:
        return TalepAdim3Gorunumu(
          tur: _t.tur!,
          veri: b,
          secenekler: _secenekler,
          hata: _secenekHata,
          antrenorId: _t.antrenorId,
          kortId: _t.kortId,
          esneme: _t.esneme,
          kisiSayisi: _t.kisiSayisi,
          aciklama: _aciklama,
          gonderiliyor: _gonderiliyor,
          onHoca: (id) => setState(() => _t.antrenorId = id),
          onKort: (id) => setState(() => _t.kortId = id),
          onEsneme: (v) => setState(() => _t.esneme = v),
          onKisi: (n) => setState(() => _t.kisiSayisi = n),
          onYenidenDene: _secenekYukle,
          onGonder: (_secenekler?.uyeBos ?? false) ? _gonder : null,
          onSureyiKisalt: _t.tur == TalepTuru.paket &&
                  b.surelerDk.isNotEmpty &&
                  _t.sureDk > b.surelerDk.first
              ? () {
                  setState(() => _t.sureDk = b.surelerDk.first);
                  _secenekYukle();
                }
              : null,
        );
    }
  }
}
