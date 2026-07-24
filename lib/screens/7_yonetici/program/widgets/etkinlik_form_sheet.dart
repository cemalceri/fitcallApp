// lib/screens/7_yonetici/program/widgets/etkinlik_form_sheet.dart
//
// Ders oluşturma / düzenleme formu.
// Web'deki _etkinlik_kaydet_modal.html karşılığı; aynı alanlar ve aynı kurallar
// (30 dakikanın katları, en az bir üye, antrenör zorunlu). Doğrulamanın asıl
// yeri backend'deki ortak servis; buradaki kontroller sadece kullanıcıyı erken
// uyarmak için.

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'uye_secim_sheet.dart';

class EtkinlikFormSonucu {
  final EtkinlikKaydetIstegi istek;
  EtkinlikFormSonucu(this.istek);
}

class EtkinlikFormSheet extends StatefulWidget {
  final EtkinlikFormVerileri veriler;

  /// Yeni kayıtta ızgarada dokunulan slot (kort + başlangıç saati)
  final int? onSecilenKortId;
  final DateTime? onSecilenBaslangic;

  const EtkinlikFormSheet({
    super.key,
    required this.veriler,
    this.onSecilenKortId,
    this.onSecilenBaslangic,
  });

  static Future<EtkinlikKaydetIstegi?> ac(
    BuildContext context, {
    required EtkinlikFormVerileri veriler,
    int? onSecilenKortId,
    DateTime? onSecilenBaslangic,
  }) {
    return showModalBottomSheet<EtkinlikKaydetIstegi>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EtkinlikFormSheet(
        veriler: veriler,
        onSecilenKortId: onSecilenKortId,
        onSecilenBaslangic: onSecilenBaslangic,
      ),
    );
  }

  @override
  State<EtkinlikFormSheet> createState() => _EtkinlikFormSheetState();
}

class _EtkinlikFormSheetState extends State<EtkinlikFormSheet> {
  int? _urunId;
  int? _kortId;
  int? _antrenorId;
  int? _yardimciAntrenorId;
  String? _seviye;
  late DateTime _baslangic;
  late DateTime _bitis;
  late List<int> _uyeIdler;

  final _katsayiCtrl = TextEditingController(text: '1.0');
  final _ucretCtrl = TextEditingController(text: '0');
  final _aciklamaCtrl = TextEditingController();

  String? _hata;

  bool get _duzenleme => widget.veriler.etkinlik != null;

  @override
  void initState() {
    super.initState();
    final mevcut = widget.veriler.etkinlik;

    if (mevcut != null) {
      _urunId = mevcut.urunId;
      _kortId = mevcut.kortId;
      _antrenorId = mevcut.antrenorId;
      _yardimciAntrenorId = mevcut.yardimciAntrenorId;
      _seviye = mevcut.seviye.isEmpty ? null : mevcut.seviye;
      _baslangic = mevcut.baslangic ?? _varsayilanBaslangic();
      _bitis = mevcut.bitis ?? _baslangic.add(const Duration(hours: 1));
      _katsayiCtrl.text = mevcut.antrenorKatsayisi;
      _ucretCtrl.text = mevcut.ucret;
      _aciklamaCtrl.text = mevcut.aciklama;
    } else {
      _kortId = widget.onSecilenKortId ??
          (widget.veriler.kortlar.isNotEmpty
              ? widget.veriler.kortlar.first.id
              : null);
      _baslangic = _varsayilanBaslangic();
      _bitis = _baslangic.add(const Duration(hours: 1));
      _seviye = widget.veriler.seviyeler.isNotEmpty
          ? widget.veriler.seviyeler.first.kod
          : null;
    }

    _uyeIdler = [...widget.veriler.seciliUyeIdler];
    // Seçenek listesinde olmayan id kalmasın (kayıt sırasında sürpriz olmasın)
    final gecerli = widget.veriler.uyeler.map((u) => u.id).toSet();
    _uyeIdler.removeWhere((id) => !gecerli.contains(id));
  }

  DateTime _varsayilanBaslangic() {
    final s = widget.onSecilenBaslangic ?? DateTime.now();
    // 30 dakikanın katına yuvarla (backend kuralı)
    final dakika = s.minute < 30 ? 0 : 30;
    return DateTime(s.year, s.month, s.day, s.hour, dakika);
  }

  @override
  void dispose() {
    _katsayiCtrl.dispose();
    _ucretCtrl.dispose();
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  /* ------------------------------ seçiciler ------------------------------ */

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _baslangic,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (secilen == null) return;
    setState(() {
      final sure = _bitis.difference(_baslangic);
      _baslangic = DateTime(secilen.year, secilen.month, secilen.day,
          _baslangic.hour, _baslangic.minute);
      _bitis = _baslangic.add(sure);
    });
  }

  Future<void> _saatSec({required bool baslangicMi}) async {
    final mevcut = baslangicMi ? _baslangic : _bitis;
    final secilen = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: mevcut.hour, minute: mevcut.minute),
    );
    if (secilen == null) return;

    // 30 dakikanın katına yuvarla: backend 30'un katı olmayan saati reddediyor
    final dakika = secilen.minute < 15
        ? 0
        : secilen.minute < 45
            ? 30
            : 0;
    final saat = secilen.minute >= 45 ? secilen.hour + 1 : secilen.hour;

    setState(() {
      final yeni = DateTime(_baslangic.year, _baslangic.month, _baslangic.day,
          saat.clamp(0, 23), dakika);
      if (baslangicMi) {
        final sure = _bitis.difference(_baslangic);
        _baslangic = yeni;
        _bitis = _baslangic
            .add(sure.inMinutes <= 0 ? const Duration(hours: 1) : sure);
      } else {
        _bitis = yeni;
      }
    });
  }

  Future<void> _uyeSec() async {
    final sonuc = await UyeSecimSheet.ac(
      context,
      uyeler: widget.veriler.uyeler,
      seciliIdler: _uyeIdler,
    );
    if (sonuc != null) setState(() => _uyeIdler = sonuc);
  }

  /* ------------------------------- kaydet -------------------------------- */

  void _kaydet() {
    final hatalar = <String>[];
    if (_urunId == null) hatalar.add('ürün');
    if (_kortId == null) hatalar.add('kort');
    if (_antrenorId == null) hatalar.add('antrenör');
    if (_seviye == null) hatalar.add('top rengi');

    if (hatalar.isNotEmpty) {
      setState(() => _hata = '${hatalar.join(', ')} seçilmeli.');
      return;
    }
    if (_uyeIdler.isEmpty) {
      setState(() => _hata = 'Kayıt için en az bir üye seçmelisiniz.');
      return;
    }
    if (!_bitis.isAfter(_baslangic)) {
      setState(() => _hata = 'Bitiş saati başlangıçtan sonra olmalı.');
      return;
    }
    if (_baslangic.minute % 30 != 0 || _bitis.minute % 30 != 0) {
      setState(() => _hata = 'Saatler 30 dakikanın katları olmalı.');
      return;
    }

    Navigator.pop(
      context,
      EtkinlikKaydetIstegi(
        pk: widget.veriler.etkinlik?.id,
        urunId: _urunId!,
        kortId: _kortId!,
        antrenorId: _antrenorId!,
        yardimciAntrenorId: _yardimciAntrenorId,
        baslangic: _baslangic,
        bitis: _bitis,
        seviye: _seviye!,
        antrenorKatsayisi:
            _katsayiCtrl.text.trim().isEmpty ? '1.0' : _katsayiCtrl.text.trim(),
        ucret: _ucretCtrl.text.trim().isEmpty ? '0' : _ucretCtrl.text.trim(),
        aciklama: _aciklamaCtrl.text.trim(),
        uyeIdler: _uyeIdler,
      ),
    );
  }

  /* -------------------------------- build -------------------------------- */

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final urunKilitli = widget.veriler.etkinlik?.urunKilitliMi ?? false;
    final tarihBicim = DateFormat('d MMMM yyyy, EEEE', 'tr_TR');

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, kaydirmaKontrol) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: renk.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: kaydirmaKontrol,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  children: [
                    Text(
                      _duzenleme ? 'Dersi düzenle' : 'Yeni ders',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: renk.onSurface,
                      ),
                    ),
                    if (widget.veriler.etkinlik?.sabitPlanMi == true) ...[
                      const SizedBox(height: 8),
                      _bilgiKutusu(
                        renk,
                        'Bu ders sabit plandan üretilmiş. Kort/saat değişikliği '
                        'korunur; ürün değiştirilemez.',
                      ),
                    ],
                    const SizedBox(height: 16),
                    _etiket('Tarih', renk),
                    _secimSatiri(
                      metin: tarihBicim.format(_baslangic),
                      ikon: Icons.calendar_today,
                      onTap: _tarihSec,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _etiket('Başlangıç', renk),
                              _secimSatiri(
                                metin: ProgramSaat.bicim(_baslangic),
                                ikon: Icons.schedule,
                                onTap: () => _saatSec(baslangicMi: true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _etiket('Bitiş', renk),
                              _secimSatiri(
                                metin: ProgramSaat.bicim(_bitis),
                                ikon: Icons.schedule,
                                onTap: () => _saatSec(baslangicMi: false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _etiket('Kort', renk),
                    _acilirListe<int>(
                      deger: _kortId,
                      secenekler: widget.veriler.kortlar
                          .map((k) => DropdownMenuItem(
                                value: k.id,
                                child: Text(k.adi,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _kortId = v),
                    ),
                    const SizedBox(height: 12),
                    _etiket('Ürün', renk),
                    _acilirListe<int>(
                      deger: _urunId,
                      etkin: !urunKilitli,
                      secenekler: widget.veriler.urunler
                          .map((u) => DropdownMenuItem(
                                value: u.id,
                                child: Text(u.adi,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _urunId = v),
                    ),
                    const SizedBox(height: 12),
                    _etiket('Antrenör', renk),
                    _acilirListe<int>(
                      deger: _antrenorId,
                      secenekler: widget.veriler.antrenorler
                          .map((a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(
                                  a.pasif ? '${a.adSoyad} (Pasif)' : a.adSoyad,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _antrenorId = v),
                    ),
                    const SizedBox(height: 12),
                    _etiket('Yardımcı antrenör (opsiyonel)', renk),
                    _acilirListe<int?>(
                      deger: _yardimciAntrenorId,
                      secenekler: [
                        const DropdownMenuItem<int?>(
                            value: null, child: Text('Yok')),
                        ...widget.veriler.antrenorler.map(
                          (a) => DropdownMenuItem<int?>(
                            value: a.id,
                            child: Text(
                              a.pasif ? '${a.adSoyad} (Pasif)' : a.adSoyad,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _yardimciAntrenorId = v),
                    ),
                    const SizedBox(height: 12),
                    _etiket('Top rengi', renk),
                    _acilirListe<String>(
                      deger: _seviye,
                      secenekler: widget.veriler.seviyeler
                          .map((s) => DropdownMenuItem(
                                value: s.kod,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: s.renk,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(s.ad,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _seviye = v),
                    ),
                    const SizedBox(height: 16),
                    _etiket('Katılımcılar', renk),
                    _katilimciKutusu(renk),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _etiket('Antrenör katsayısı', renk),
                              TextField(
                                controller: _katsayiCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _etiket('Ekstra ücret', renk),
                              TextField(
                                controller: _ucretCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _etiket('Açıklama', renk),
                    TextField(
                      controller: _aciklamaCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_hata != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: renk.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                size: 18, color: renk.onErrorContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _hata!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: renk.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Vazgeç'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _kaydet,
                          child: Text(_duzenleme ? 'Güncelle' : 'Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /* ------------------------------ parçacıklar ----------------------------- */

  Widget _etiket(String metin, ColorScheme renk) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          metin,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: renk.onSurfaceVariant,
          ),
        ),
      );

  Widget _bilgiKutusu(ColorScheme renk, String metin) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: renk.secondaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                size: 18, color: renk.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                metin,
                style:
                    TextStyle(fontSize: 12.5, color: renk.onSecondaryContainer),
              ),
            ),
          ],
        ),
      );

  Widget _secimSatiri({
    required String metin,
    required IconData ikon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: InputDecorator(
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        child: Row(
          children: [
            Icon(ikon, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(metin, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _acilirListe<T>({
    required T? deger,
    required List<DropdownMenuItem<T>> secenekler,
    required ValueChanged<T?> onChanged,
    bool etkin = true,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: deger,
      isExpanded: true, // uzun adlarda taşma yerine kırpma
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        hintText: 'Seçiniz',
      ),
      items: secenekler,
      onChanged: etkin ? onChanged : null,
    );
  }

  Widget _katilimciKutusu(ColorScheme renk) {
    final secililer =
        widget.veriler.uyeler.where((u) => _uyeIdler.contains(u.id)).toList();

    return InkWell(
      onTap: _uyeSec,
      borderRadius: BorderRadius.circular(6),
      child: InputDecorator(
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Row(
          children: [
            Expanded(
              child: secililer.isEmpty
                  ? Text(
                      'Üye seçiniz',
                      style: TextStyle(color: renk.onSurfaceVariant),
                    )
                  : Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: secililer
                          .map((u) => Chip(
                                label: Text(
                                  u.pasif ? '${u.adSoyad} (Pasif)' : u.adSoyad,
                                  style: const TextStyle(fontSize: 11.5),
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit, size: 16, color: renk.primary),
          ],
        ),
      ),
    );
  }
}

/// Form içi saat gösterimi (ızgaradaki ProgramZaman ile aynı biçim).
class ProgramSaat {
  ProgramSaat._();
  static String bicim(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
