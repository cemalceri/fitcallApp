// lib/screens/8_ofis/ders_kayit_talepleri/widgets/oneri_formu.dart
//
// Ofisin üye talebi pencereleri:
//   - OneriFormuSheet : "Değişiklik öner" — "Neyle?" dışında her şey değişir,
//                       not zorunlu. Gün/saat/süre değişince boş hoca ve kort
//                       listesi [bosListeGetir] ile yenilenir.
//   - KayitSecimSheet : "Kayıt oluştur" — yalnız "Fark etmez" kort, esneme
//                       saati ve tek derste ürün seçilir; başka değişiklik öneri ister.
// Sunucu her şeyi yeniden doğrular; burada yalnız form var.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/10_ofis/ofis_uye_talep_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OneriIstegi {
  final DateTime baslangic;
  final int sureDk;
  final int? antrenorId;
  final int kortId;
  final int? kisiSayisi;
  final int? urunId;
  final String? ekstraUcret;
  final String notu;
  final bool hocaOnayladi;
  final bool uyeTelefondaOnayladi;

  const OneriIstegi({
    required this.baslangic,
    required this.sureDk,
    required this.antrenorId,
    required this.kortId,
    this.kisiSayisi,
    this.urunId,
    this.ekstraUcret,
    required this.notu,
    this.hocaOnayladi = false,
    this.uyeTelefondaOnayladi = false,
  });
}

List<String> _saatler() => [
      for (var h = 7; h <= 22; h++)
        for (final m in const ['00', '30'])
          '${h.toString().padLeft(2, '0')}:$m',
    ];

String _hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class OneriFormuSheet extends StatefulWidget {
  final OfisTalepDetay detay;
  final Future<OfisTalepDetay> Function(DateTime baslangic, int sureDk)
      bosListeGetir;

  const OneriFormuSheet(
      {super.key, required this.detay, required this.bosListeGetir});

  @override
  State<OneriFormuSheet> createState() => _OneriFormuSheetState();
}

class _OneriFormuSheetState extends State<OneriFormuSheet> {
  late OfisTalepDetay _d = widget.detay;
  late DateTime _gun;
  late String _saat;
  late int _sure;
  int? _hoca;
  int? _kort;
  late int _kisi;
  int? _urun;
  final _ekstra = TextEditingController();
  final _not = TextEditingController();
  bool _hocaOnay = false;
  bool _uyeTel = false;
  bool _yukleniyor = false;
  String? _hata;

  OfisUyeTalep get _t => widget.detay.talep;

  @override
  void initState() {
    super.initState();
    _gun = DateTime(_t.baslangic.year, _t.baslangic.month, _t.baslangic.day);
    _saat = _hhmm(_t.baslangic);
    _sure = _t.sureDk;
    _hoca = _t.antrenorId ?? _t.hocaOnayAntrenorId;
    _kort = _t.kortId;
    _kisi = _t.kisiSayisi ?? 1;
  }

  @override
  void dispose() {
    _ekstra.dispose();
    _not.dispose();
    super.dispose();
  }

  DateTime get _baslangic {
    final p = _saat.split(':');
    return DateTime(
        _gun.year, _gun.month, _gun.day, int.parse(p[0]), int.parse(p[1]));
  }

  Future<void> _yenile() async {
    setState(() => _yukleniyor = true);
    try {
      final d = await widget.bosListeGetir(_baslangic, _sure);
      if (!mounted) return;
      setState(() {
        _d = d;
        if (_hoca != null && !d.hocalar.any((h) => h.id == _hoca && h.bos)) {
          _hoca = null;
        }
        if (_kort != null && !d.kortlar.any((k) => k.id == _kort && k.bos)) {
          _kort = null;
        }
      });
    } catch (_) {
      // Liste yenilenemezse eski liste kalır; sunucu kayıtta yine kontrol eder.
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _gunSec() async {
    final simdi = DateTime.now();
    final secilen = await showDatePicker(
      context: context,
      initialDate: _gun.isBefore(simdi) ? simdi : _gun,
      firstDate: DateTime(simdi.year, simdi.month, simdi.day),
      lastDate: simdi.add(const Duration(days: 60)),
      locale: const Locale('tr', 'TR'),
    );
    if (secilen == null) return;
    setState(() => _gun = secilen);
    _yenile();
  }

  void _gonder() {
    final notu = _not.text.trim();
    if (notu.isEmpty) {
      setState(() => _hata = 'Üyeye not yazmak zorunlu.');
      return;
    }
    if (_kort == null) {
      setState(() => _hata = 'Kort seç.');
      return;
    }
    if (_t.hocali && _hoca == null) {
      setState(() => _hata = 'Hoca seç.');
      return;
    }
    Navigator.pop(
      context,
      OneriIstegi(
        baslangic: _baslangic,
        sureDk: _sure,
        antrenorId: _t.hocali ? _hoca : null,
        kortId: _kort!,
        kisiSayisi: _t.tur == 'KORT' ? _kisi : null,
        urunId: _urun,
        ekstraUcret: _ekstra.text.trim().isEmpty ? null : _ekstra.text.trim(),
        notu: notu,
        hocaOnayladi: _hocaOnay,
        uyeTelefondaOnayladi: _uyeTel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final hocalar = _d.hocalar.where((h) => h.bos || h.id == _hoca).toList();
    final kortlar = _d.kortlar.where((k) => k.bos || k.id == _kort).toList();
    final saatler = _saatler();
    if (!saatler.contains(_saat)) saatler.insert(0, _saat);
    final telafi = _t.tur == 'TELAFI';
    final sureler = telafi ? [_t.sureDk] : _d.surelerDk;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l,
          Bosluk.l + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Değişiklik öner', style: context.metin.titleMedium),
          Text('${_t.uyeAdi} · ${_t.turAdi} · ${_t.dersTanimi}',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: Bosluk.m),
          OutlinedButton.icon(
            onPressed: _gunSec,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(DateFormat('d MMMM y EEEE', 'tr_TR').format(_gun)),
          ),
          const SizedBox(height: Bosluk.s),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('ac1-$_saat'),
                  initialValue: _saat,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Saat',
                      isDense: true,
                      border: OutlineInputBorder()),
                  items: [
                    for (final s in saatler)
                      DropdownMenuItem(value: s, child: Text(s))
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _saat = v);
                    _yenile();
                  },
                ),
              ),
              const SizedBox(width: Bosluk.s),
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey(
                      'ac2-${sureler.contains(_sure) ? _sure : sureler.first}'),
                  initialValue: sureler.contains(_sure) ? _sure : sureler.first,
                  isExpanded: true,
                  decoration: InputDecoration(
                      labelText: telafi ? 'Süre (telafi)' : 'Süre',
                      isDense: true,
                      border: const OutlineInputBorder()),
                  items: [
                    for (final s in sureler)
                      DropdownMenuItem(value: s, child: Text('$s dk'))
                  ],
                  onChanged: telafi
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() => _sure = v);
                          _yenile();
                        },
                ),
              ),
            ],
          ),
          if (_yukleniyor) const LinearProgressIndicator(minHeight: 2),
          if (!_d.uyeBos)
            Padding(
              padding: const EdgeInsets.only(top: Bosluk.xs),
              child: Text('Üyenin bu saatte başka dersi ya da talebi var.',
                  style: TextStyle(fontSize: 13, color: context.renkler.hata)),
            ),
          const SizedBox(height: Bosluk.s),
          if (_t.hocali) ...[
            DropdownButtonFormField<int>(
              key: ValueKey(
                  'ac3-${hocalar.any((h) => h.id == _hoca) ? _hoca : null}'),
              initialValue: hocalar.any((h) => h.id == _hoca) ? _hoca : null,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Hoca (o saatte boş)',
                  isDense: true,
                  border: OutlineInputBorder()),
              items: [
                for (final h in hocalar)
                  DropdownMenuItem(
                      value: h.id,
                      child: Text(h.bos ? h.ad : '${h.ad} (dolu)',
                          overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _hoca = v),
            ),
            const SizedBox(height: Bosluk.s),
          ],
          DropdownButtonFormField<int>(
            key: ValueKey(
                'ac4-${kortlar.any((k) => k.id == _kort) ? _kort : null}'),
            initialValue: kortlar.any((k) => k.id == _kort) ? _kort : null,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Kort (o saatte boş)',
                isDense: true,
                border: OutlineInputBorder()),
            items: [
              for (final k in kortlar)
                DropdownMenuItem(
                    value: k.id,
                    child: Text(k.bos ? k.ad : '${k.ad} (dolu)',
                        overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _kort = v),
          ),
          if (_t.tur == 'KORT') ...[
            const SizedBox(height: Bosluk.s),
            Row(
              children: [
                const Expanded(child: Text('Kişi sayısı')),
                IconButton(
                  onPressed: _kisi > 1 ? () => setState(() => _kisi--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_kisi'),
                IconButton(
                  onPressed:
                      _kisi < _d.maxKisi ? () => setState(() => _kisi++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
          if (_t.tur == 'TEK_DERS' && _d.urunler.isNotEmpty) ...[
            const SizedBox(height: Bosluk.s),
            DropdownButtonFormField<int?>(
              key: ValueKey('ac5-$_urun'),
              initialValue: _urun,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Ürün',
                  isDense: true,
                  border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<int?>(
                    value: null, child: Text('Talepteki ürün')),
                for (final u in _d.urunler)
                  DropdownMenuItem<int?>(
                      value: u.id,
                      child: Text(u.ad, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _urun = v),
            ),
          ],
          if (!telafi) ...[
            const SizedBox(height: Bosluk.s),
            TextField(
              controller: _ekstra,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Ekstra ücret (isteğe bağlı, kişi başı)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: Bosluk.s),
          TextField(
            controller: _not,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Üyeye not (zorunlu)',
              hintText: 'Örn. 17:00 dolu, 18:00 olur mu?',
              errorText: _hata,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_t.hocali)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _hocaOnay,
              onChanged: (v) => setState(() => _hocaOnay = v ?? false),
              title: const Text('Hocayla konuştum, bu saati onayladı'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _uyeTel,
            onChanged: (v) => setState(() => _uyeTel = v ?? false),
            title: const Text('Üye telefonda onayladı (ders hemen kaydedilir)'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: Bosluk.s),
          FilledButton(
            onPressed: _gonder,
            child: Text(_uyeTel ? 'Dersi kaydet' : 'Üyeye gönder'),
          ),
        ],
      ),
    );
  }
}

/// "Kayıt oluştur" seçimleri. Dönen değer: {kort_id, baslangic, urun_id}.
class KayitSecimi {
  final int? kortId;
  final DateTime? baslangic;
  final int? urunId;

  const KayitSecimi({this.kortId, this.baslangic, this.urunId});
}

class KayitSecimSheet extends StatefulWidget {
  final OfisTalepDetay detay;

  const KayitSecimSheet({super.key, required this.detay});

  /// Seçim gerekmiyorsa (kort belli, esneme yok, tek ders değil) false.
  static bool gerekli(OfisTalepDetay d) =>
      d.talep.kortFarkEtmez ||
      d.talep.esneme ||
      (d.talep.tur == 'TEK_DERS' && d.urunler.isNotEmpty);

  @override
  State<KayitSecimSheet> createState() => _KayitSecimSheetState();
}

class _KayitSecimSheetState extends State<KayitSecimSheet> {
  int? _kort;
  late DateTime _bas = widget.detay.talep.baslangic;
  int? _urun;
  String? _hata;

  @override
  Widget build(BuildContext context) {
    final t = widget.detay.talep;
    final kortlar = widget.detay.kortlar.where((k) => k.bos).toList();
    final secenekler = <DateTime>[
      if (t.esneme)
        for (var dk = -60 * t.esnemeSaat; dk <= 60 * t.esnemeSaat; dk += 30)
          t.baslangic.add(Duration(minutes: dk))
      else
        t.baslangic,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l, Bosluk.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Kayıt oluştur', style: context.metin.titleMedium),
          Text('${t.uyeAdi} · ${t.dersTanimi}',
              style:
                  TextStyle(fontSize: 13, color: context.cs.onSurfaceVariant)),
          const SizedBox(height: Bosluk.m),
          if (t.esneme) ...[
            Text(
                'Saati kaydırırsan hocanın yeni saate uygun olduğundan emin ol; '
                'hoca yeni saati bildirimle görür.',
                style: TextStyle(
                    fontSize: 12, color: context.cs.onSurfaceVariant)),
            const SizedBox(height: Bosluk.xs),
            DropdownButtonFormField<DateTime>(
              key: ValueKey('ac6-$_bas'),
              initialValue: _bas,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Başlangıç (üye esnetebilir)',
                  isDense: true,
                  border: OutlineInputBorder()),
              items: [
                for (final s in secenekler)
                  DropdownMenuItem(value: s, child: Text(_hhmm(s)))
              ],
              onChanged: (v) => setState(() => _bas = v ?? _bas),
            ),
            const SizedBox(height: Bosluk.s),
          ],
          if (t.kortFarkEtmez) ...[
            DropdownButtonFormField<int>(
              key: ValueKey('ac7-$_kort'),
              initialValue: _kort,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Kort (üye fark etmez dedi)',
                  isDense: true,
                  border: OutlineInputBorder()),
              items: [
                for (final k in kortlar)
                  DropdownMenuItem(value: k.id, child: Text(k.ad))
              ],
              onChanged: (v) => setState(() => _kort = v),
            ),
            if (t.esneme)
              Padding(
                padding: const EdgeInsets.only(top: Bosluk.xs),
                child: Text('Boş kortlar talebin saatine göre listelenir.',
                    style: TextStyle(
                        fontSize: 12, color: context.cs.onSurfaceVariant)),
              ),
            const SizedBox(height: Bosluk.s),
          ],
          if (t.tur == 'TEK_DERS' && widget.detay.urunler.isNotEmpty) ...[
            DropdownButtonFormField<int?>(
              key: ValueKey('ac8-$_urun'),
              initialValue: _urun,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Ürün',
                  isDense: true,
                  border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<int?>(
                    value: null, child: Text('Talepteki ürün')),
                for (final u in widget.detay.urunler)
                  DropdownMenuItem<int?>(
                      value: u.id,
                      child: Text(u.ad, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _urun = v),
            ),
            const SizedBox(height: Bosluk.s),
          ],
          if (_hata != null)
            Text(_hata!,
                style: TextStyle(fontSize: 13, color: context.renkler.hata)),
          const SizedBox(height: Bosluk.s),
          FilledButton(
            onPressed: () {
              if (t.kortFarkEtmez && _kort == null) {
                setState(() => _hata = 'Kort seç.');
                return;
              }
              Navigator.pop(
                context,
                KayitSecimi(
                  kortId: _kort,
                  baslangic: _bas == t.baslangic ? null : _bas,
                  urunId: _urun,
                ),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
