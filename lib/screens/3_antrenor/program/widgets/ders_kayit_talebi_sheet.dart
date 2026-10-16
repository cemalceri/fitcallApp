// lib/screens/3_antrenor/program/widgets/ders_kayit_talebi_sheet.dart
//
// Antrenörün "Ders kayıt talebi" formu: tarih, kort, başlangıç, bitiş ve
// açıklama (hepsi zorunlu). Kortta, ders arasında 1 dakikada doldurulsun diye
// her alan dolu açılır (bkz. TalepVarsayilani); antrenör çoğu zaman yalnız
// açıklamayı yazar. Ofis kaydı oluşturunca ders programa eklenir.

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/1_common/widgets/alt_sayfa.dart';
import 'package:fitcall/screens/1_common/widgets/buton_yukleniyor.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_kayit_talebi_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formun açılış değerleri.
class TalepVarsayilani {
  final DateTime tarih;
  final int? kortId;
  final DateTime baslangic;
  final DateTime bitis;

  const TalepVarsayilani({
    required this.tarih,
    required this.kortId,
    required this.baslangic,
    required this.bitis,
  });

  /// Kural (antrenörle konuşuldu):
  /// - kort: o saatteki ya da sıradaki kendi dersinin kortu, yoksa ilk kort;
  /// - başlangıç: bugünse şu ana en yakın 30 dakika, başka günse o günkü ilk
  ///   dersinin saati (yoksa 09:00);
  /// - bitiş: başlangıç + kendi dersinin süresi (dersi yoksa 60 dakika).
  factory TalepVarsayilani.hesapla({
    required HaftalikProgram program,
    required DateTime gun,
    required DateTime simdi,
  }) {
    final gunBasi = DateTime(gun.year, gun.month, gun.day);
    final bugun = gunBasi.year == simdi.year &&
        gunBasi.month == simdi.month &&
        gunBasi.day == simdi.day;
    final benim = program.benimAntrenorId;

    final derslerim = program
        .gununDersleri(gunBasi)
        .where((d) => !d.iptalMi && benim != null && d.antrenorId == benim)
        .toList();

    ProgramDersi? referans;
    if (bugun) {
      for (final d in derslerim) {
        if (d.bitis.isAfter(simdi)) {
          referans = d;
          break;
        }
      }
    } else if (derslerim.isNotEmpty) {
      referans = derslerim.first;
    }

    final DateTime baslangic;
    if (bugun) {
      baslangic = yakin30Dakika(simdi);
    } else if (referans != null) {
      baslangic = referans.baslangic;
    } else {
      baslangic = DateTime(gunBasi.year, gunBasi.month, gunBasi.day, 9);
    }
    final sure =
        referans != null && referans.sureDakika > 0 ? referans.sureDakika : 60;

    return TalepVarsayilani(
      tarih: gunBasi,
      kortId: referans?.kortId ??
          (program.kortlar.isNotEmpty ? program.kortlar.first.id : null),
      baslangic: baslangic,
      bitis: baslangic.add(Duration(minutes: sure)),
    );
  }

  /// Şu ana en yakın 30 dakikalık dilim (17:12 → 17:00, 17:20 → 17:30).
  static DateTime yakin30Dakika(DateTime t) {
    final dakika = t.hour * 60 + t.minute;
    final yuvarli = ((dakika + 15) ~/ 30) * 30;
    final gunBasi = DateTime(t.year, t.month, t.day);
    final sonuc = gunBasi.add(Duration(minutes: yuvarli));
    // 23:45 sonrası ertesi güne taşmasın
    return sonuc.day == t.day
        ? sonuc
        : DateTime(t.year, t.month, t.day, 23, 30);
  }
}

class DersKayitTalebiSheet extends StatefulWidget {
  final List<SecenekKort> kortlar;
  final TalepVarsayilani varsayilan;

  const DersKayitTalebiSheet({
    super.key,
    required this.kortlar,
    required this.varsayilan,
  });

  /// Gönderilirse sunucunun mesajını döner, vazgeçilirse null.
  static Future<String?> ac(
    BuildContext context, {
    required List<SecenekKort> kortlar,
    required TalepVarsayilani varsayilan,
  }) {
    return altSayfaGoster<String>(
      context,
      cocuk: DersKayitTalebiSheet(kortlar: kortlar, varsayilan: varsayilan),
    );
  }

  @override
  State<DersKayitTalebiSheet> createState() => _DersKayitTalebiSheetState();
}

class _DersKayitTalebiSheetState extends State<DersKayitTalebiSheet> {
  late DateTime _tarih = widget.varsayilan.tarih;
  // Dersin kortu listede yoksa (pasif kort) seçici boş açılır; antrenör seçer.
  late int? _kortId =
      widget.kortlar.any((k) => k.id == widget.varsayilan.kortId)
          ? widget.varsayilan.kortId
          : null;

  /// Gün içindeki dakika (30'un katı).
  late int _basDakika = _dakika(widget.varsayilan.baslangic);
  late int _bitDakika = _dakika(widget.varsayilan.bitis);

  final _aciklama = TextEditingController();
  bool _gonderiliyor = false;
  String? _hata;

  static int _dakika(DateTime t) => t.hour * 60 + t.minute;

  /// 06:00 - 23:30 arası 30 dakikalık dilimler. Varsayılan değer dışarıda
  /// kalırsa (gece dersi) listeye eklenir, seçici boş görünmesin.
  List<int> _dilimler({int? dahil}) {
    final liste = [for (var d = 6 * 60; d <= 23 * 60 + 30; d += 30) d];
    if (dahil != null && !liste.contains(dahil)) {
      liste
        ..add(dahil)
        ..sort();
    }
    return liste;
  }

  String _saat(int dakika) =>
      '${(dakika ~/ 60).toString().padLeft(2, '0')}:${(dakika % 60).toString().padLeft(2, '0')}';

  DateTime _zaman(int dakika) => DateTime(_tarih.year, _tarih.month, _tarih.day)
      .add(Duration(minutes: dakika));

  @override
  void dispose() {
    _aciklama.dispose();
    super.dispose();
  }

  Future<void> _tarihSec() async {
    final simdi = simdiKulup();
    final secilen = await showDatePicker(
      context: context,
      initialDate: _tarih,
      // Sonradan bildirilen ders (akşam, ertesi gün) için geriye de izin var;
      // sınırı sunucu koyar.
      firstDate: simdi.subtract(const Duration(days: 7)),
      lastDate: simdi.add(const Duration(days: 60)),
    );
    if (secilen != null) setState(() => _tarih = secilen);
  }

  void _baslangicSec(int dakika) {
    final sure = _bitDakika - _basDakika;
    setState(() {
      _basDakika = dakika;
      // Süre korunur (antrenör çoğu zaman yalnız saati kaydırır).
      _bitDakika =
          (dakika + (sure > 0 ? sure : 60)).clamp(dakika + 30, 24 * 60);
    });
  }

  Future<void> _gonder() async {
    final aciklama = _aciklama.text.trim();
    String? hata;
    if (_kortId == null) {
      hata = 'Kort seçmelisiniz.';
    } else if (_bitDakika <= _basDakika) {
      hata = 'Bitiş saati başlangıçtan sonra olmalı.';
    } else if (aciklama.isEmpty) {
      hata = 'Açıklama zorunludur: hangi dersin yerine, ne değişti?';
    }
    if (hata != null) {
      setState(() => _hata = hata);
      return;
    }

    setState(() {
      _gonderiliyor = true;
      _hata = null;
    });
    try {
      final mesaj = await DersKayitTalebiService.olustur(
        kortId: _kortId!,
        baslangic: _zaman(_basDakika),
        bitis: _zaman(_bitDakika),
        aciklama: aciklama,
      );
      if (mounted) Navigator.pop(context, mesaj);
    } on ApiException catch (e) {
      if (mounted) setState(() => _hata = e.message);
    } catch (_) {
      if (mounted) setState(() => _hata = 'Talep gönderilemedi.');
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarihBicim = DateFormat('d MMMM yyyy, EEEE', 'tr_TR');
    final bitisDilimleri =
        _dilimler(dahil: _bitDakika).where((d) => d > _basDakika).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + Bosluk.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AltSayfaBasligi(
            ikon: Icons.edit_calendar_rounded,
            baslik: 'Ders kayıt talebi',
            altBaslik: 'Ofis onaylayınca programa ders olarak eklenir',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Bosluk.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: _gonderiliyor ? null : _tarihSec,
                  borderRadius: BorderRadius.circular(Yaricap.m),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tarih',
                      suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                    ),
                    child: Text(
                      tarihBicim.format(_tarih),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: Bosluk.m),
                DropdownButtonFormField<int>(
                  key: const ValueKey('talep_kort'),
                  initialValue: _kortId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Kort'),
                  items: [
                    for (final k in widget.kortlar)
                      DropdownMenuItem(
                        value: k.id,
                        child: Text(k.adi,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged:
                      _gonderiliyor ? null : (v) => setState(() => _kortId = v),
                ),
                const SizedBox(height: Bosluk.m),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('talep_bas_$_basDakika'),
                        initialValue: _basDakika,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'Başlangıç'),
                        items: [
                          for (final d in _dilimler(dahil: _basDakika))
                            DropdownMenuItem(value: d, child: Text(_saat(d))),
                        ],
                        onChanged: _gonderiliyor
                            ? null
                            : (v) {
                                if (v != null) _baslangicSec(v);
                              },
                      ),
                    ),
                    const SizedBox(width: Bosluk.m),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('talep_bit_${_basDakika}_$_bitDakika'),
                        initialValue: bitisDilimleri.contains(_bitDakika)
                            ? _bitDakika
                            : null,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Bitiş'),
                        items: [
                          for (final d in bitisDilimleri)
                            DropdownMenuItem(value: d, child: Text(_saat(d))),
                        ],
                        onChanged: _gonderiliyor
                            ? null
                            : (v) =>
                                setState(() => _bitDakika = v ?? _bitDakika),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Bosluk.m),
                TextField(
                  controller: _aciklama,
                  enabled: !_gonderiliyor,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Hangi dersin yerine? Ne değişti? Kimlerle?',
                    alignLabelWithHint: true,
                  ),
                ),
                if (_hata != null) ...[
                  const SizedBox(height: Bosluk.s),
                  Text(
                    _hata!,
                    style: TextStyle(color: context.cs.error, fontSize: 13),
                  ),
                ],
                const SizedBox(height: Bosluk.m),
                FilledButton.icon(
                  onPressed: _gonderiliyor ? null : _gonder,
                  icon: _gonderiliyor
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: ButonYukleniyorGostergesi(),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Talebi gönder'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
