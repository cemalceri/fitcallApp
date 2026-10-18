// lib/screens/7_yonetici/uyeler/widgets/uye_filtre_sheet.dart

import 'dart:async';

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/uye_filtreleri.dart';
import 'package:fitcall/screens/1_common/widgets/alt_sayfa.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Tarih bölümlerinin hali: hiçbiri / tarih aralığı / "hiç".
enum _TarihModu { tumu, aralik, hic }

/// Yönetici Üyeler — tam boy filtre sayfası.
///
/// Bölümler birlikte uygulanır (VE). Alttaki düğme canlı sayıyı gösterir:
/// her değişiklikten sonra beklemeli (400 ms) bir sayım isteği gider
/// ([sayac]); sunucu yalnız sayar. Uygula seçilen filtreleri döndürür,
/// kapatmak hiçbir şeyi değiştirmez.
class UyeFiltreSheet extends StatefulWidget {
  final UyeFiltreleri baslangic;

  /// Filtreye uyan üye sayısı; testte sabit değer döndürülür.
  final Future<int> Function(UyeFiltreleri) sayac;

  /// Hızlı çiplerin referans günü (kulüp günü).
  final DateTime bugun;

  const UyeFiltreSheet({
    super.key,
    required this.baslangic,
    required this.sayac,
    required this.bugun,
  });

  static Future<UyeFiltreleri?> ac(
    BuildContext context, {
    required UyeFiltreleri baslangic,
    required Future<int> Function(UyeFiltreleri) sayac,
  }) {
    return altSayfaGoster<UyeFiltreleri>(
      context,
      cocuk: UyeFiltreSheet(
        baslangic: baslangic,
        sayac: sayac,
        bugun: bugunKulup(),
      ),
    );
  }

  @override
  State<UyeFiltreSheet> createState() => _UyeFiltreSheetState();
}

class _UyeFiltreSheetState extends State<UyeFiltreSheet> {
  late UyeFiltreleri _f = widget.baslangic;

  late final _borcMin =
      TextEditingController(text: widget.baslangic.borcMin?.toString() ?? '');
  late final _borcMax =
      TextEditingController(text: widget.baslangic.borcMax?.toString() ?? '');

  late _TarihModu _kontrolModu = _mod(
    yok: _f.kontrolYok,
    sonra: _f.kontrolSonra,
    once: _f.kontrolOnce,
  );
  late _TarihModu _odemeModu = _mod(
    yok: _f.odemeYok,
    sonra: _f.odemeSonra,
    once: _f.odemeOnce,
  );

  int? _sayi;
  bool _sayiliyor = true;
  int _nesil = 0;
  Timer? _zamanlayici;

  static _TarihModu _mod({
    required bool yok,
    DateTime? sonra,
    DateTime? once,
  }) {
    if (yok) return _TarihModu.hic;
    if (sonra != null || once != null) return _TarihModu.aralik;
    return _TarihModu.tumu;
  }

  DateTime get _bugun => widget.bugun;

  DateTime _gunOnce(int gun) => _bugun.subtract(Duration(days: gun));

  DateTime _ayOnce(int ay) => DateTime(_bugun.year, _bugun.month - ay, _bugun.day);

  @override
  void initState() {
    super.initState();
    _sayimiAl(++_nesil);
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    _borcMin.dispose();
    _borcMax.dispose();
    super.dispose();
  }

  void _degistir(UyeFiltreleri yeni) {
    setState(() => _f = yeni);
    _say();
  }

  /// Beklemeli sayım: yazarken her harfte istek gitmez.
  void _say() {
    _zamanlayici?.cancel();
    final nesil = ++_nesil;
    setState(() => _sayiliyor = true);
    _zamanlayici = Timer(
      const Duration(milliseconds: 400),
      () => _sayimiAl(nesil),
    );
  }

  /// Eski isteğin cevabı yenisinin üstüne yazılmaz ([_nesil]).
  Future<void> _sayimiAl(int nesil) async {
    int? sayi;
    try {
      sayi = await widget.sayac(_f);
    } catch (_) {
      sayi = null; // düğme "Uygula" der; filtre yine uygulanabilir
    }
    if (!mounted || nesil != _nesil) return;
    setState(() {
      _sayi = sayi;
      _sayiliyor = false;
    });
  }

  /// Uygulanamaz bir aralık varsa açıklaması.
  String? get _hata {
    final f = _f;
    if (f.borcMin != null && f.borcMax != null && f.borcMin! > f.borcMax!) {
      return 'Borç: "en az" tutarı "en çok"tan büyük olamaz.';
    }
    bool ters(DateTime? sonra, DateTime? once) =>
        sonra != null && once != null && sonra.isAfter(once);
    if (ters(f.kontrolSonra, f.kontrolOnce)) {
      return 'Son kontrol: başlangıç bitişten sonra olamaz.';
    }
    if (ters(f.odemeSonra, f.odemeOnce)) {
      return 'Son ödeme: başlangıç bitişten sonra olamaz.';
    }
    return null;
  }

  void _temizle() {
    _borcMin.clear();
    _borcMax.clear();
    _kontrolModu = _TarihModu.tumu;
    _odemeModu = _TarihModu.tumu;
    _degistir(UyeFiltreleri.bos);
  }

  int? _tutar(String metin) => int.tryParse(metin.trim());

  Future<DateTime?> _tarihSec(DateTime? mevcut) {
    final ilk = DateTime(2015);
    var baslangic = mevcut ?? _bugun;
    if (baslangic.isAfter(_bugun)) baslangic = _bugun;
    if (baslangic.isBefore(ilk)) baslangic = ilk;
    return showDatePicker(
      context: context,
      initialDate: baslangic,
      firstDate: ilk,
      lastDate: _bugun,
    );
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final hata = _hata;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AltSayfaBasligi(
          ikon: Icons.tune_rounded,
          baslik: 'Filtrele',
          altBaslik: 'Seçilen filtrelerin hepsi birlikte uygulanır',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Bosluk.l, 0, Bosluk.l, Bosluk.l),
            children: [
              _durumBolumu(),
              _borcBolumu(),
              _kesinlesmeBolumu(),
              _kontrolBolumu(),
              _odemeBolumu(),
              _dersBolumu(),
              _kayitBolumu(),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Bosluk.l, Bosluk.m, Bosluk.l, Bosluk.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hata != null) ...[
                Text(
                  hata,
                  style: context.metin.bodySmall
                      ?.copyWith(color: context.renkler.hata),
                ),
                const SizedBox(height: Bosluk.s),
              ],
              Row(
                children: [
                  TextButton(
                    onPressed: _f.bosMu ? null : _temizle,
                    child: const Text('Temizle'),
                  ),
                  const SizedBox(width: Bosluk.s),
                  Expanded(
                    child: FilledButton(
                      onPressed: hata != null
                          ? null
                          : () => Navigator.pop(context, _f),
                      child: Text(
                        _dugmeEtiketi(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _dugmeEtiketi() {
    final sayi = _sayi;
    if (_sayiliyor || sayi == null) return 'Uygula';
    if (sayi == 0) return 'Eşleşen üye yok';
    return '${NumberFormat.decimalPattern('tr_TR').format(sayi)} üyeyi göster';
  }

  // ---------------------------------------------------------------------------

  Widget _durumBolumu() => _Bolum(
        baslik: 'Durum',
        child: _Secenekler<UyeDurumFiltresi?>(
          secili: _f.durum,
          secenekler: const [
            (null, 'Tümü'),
            (UyeDurumFiltresi.aktif, 'Aktif'),
            (UyeDurumFiltresi.pasif, 'Pasif'),
          ],
          onSec: (v) => _degistir(_f.copyWith(durum: v)),
        ),
      );

  Widget _borcBolumu() => _Bolum(
        baslik: 'Borç',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Secenekler<BorcDurumFiltresi?>(
              secili: _f.borc,
              secenekler: [
                (null, 'Tümü'),
                for (final b in BorcDurumFiltresi.values) (b, b.etiket),
              ],
              onSec: (v) => _degistir(_f.copyWith(borc: v)),
            ),
            const SizedBox(height: Bosluk.m),
            Row(
              children: [
                Expanded(child: _tutarAlani(_borcMin, 'En az borç (₺)', true)),
                const SizedBox(width: Bosluk.m),
                Expanded(child: _tutarAlani(_borcMax, 'En çok borç (₺)', false)),
              ],
            ),
          ],
        ),
      );

  Widget _tutarAlani(TextEditingController c, String etiket, bool alt) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
      decoration: InputDecoration(labelText: etiket, isDense: true),
      onChanged: (metin) => _degistir(
        alt
            ? _f.copyWith(borcMin: _tutar(metin))
            : _f.copyWith(borcMax: _tutar(metin)),
      ),
    );
  }

  Widget _kesinlesmeBolumu() => _Bolum(
        baslik: 'Borç kesinleşmesi',
        aciklama: 'Ön muhasebe web\'de işaretler',
        child: _Secenekler<bool?>(
          secili: _f.kesinlesti,
          secenekler: const [
            (null, 'Tümü'),
            (true, 'Kesinleşti'),
            (false, 'Kesinleşmedi'),
          ],
          onSec: (v) => _degistir(_f.copyWith(kesinlesti: v)),
        ),
      );

  Widget _kontrolBolumu() => _Bolum(
        baslik: 'Son kontrol tarihi',
        child: _tarihAraligi(
          mod: _kontrolModu,
          hicEtiketi: 'Hiç kontrol edilmedi',
          sonra: _f.kontrolSonra,
          once: _f.kontrolOnce,
          onMod: (m) {
            _kontrolModu = m;
            _degistir(_f.copyWith(
              kontrolYok: m == _TarihModu.hic,
              kontrolSonra: null,
              kontrolOnce: null,
            ));
          },
          onAralik: (sonra, once) => _degistir(
              _f.copyWith(kontrolSonra: sonra, kontrolOnce: once)),
        ),
      );

  Widget _odemeBolumu() => _Bolum(
        baslik: 'Son ödeme tarihi',
        child: _tarihAraligi(
          mod: _odemeModu,
          hicEtiketi: 'Hiç ödeme yok',
          sonra: _f.odemeSonra,
          once: _f.odemeOnce,
          onMod: (m) {
            _odemeModu = m;
            _degistir(_f.copyWith(
              odemeYok: m == _TarihModu.hic,
              odemeSonra: null,
              odemeOnce: null,
            ));
          },
          onAralik: (sonra, once) =>
              _degistir(_f.copyWith(odemeSonra: sonra, odemeOnce: once)),
        ),
      );

  /// Son kontrol / son ödeme: Tümü · Tarihe göre · Hiç. Tarihe göre seçiliyse
  /// hızlı çipler ve iki uçlu aralık (uçlar dahil).
  Widget _tarihAraligi({
    required _TarihModu mod,
    required String hicEtiketi,
    required DateTime? sonra,
    required DateTime? once,
    required ValueChanged<_TarihModu> onMod,
    required void Function(DateTime? sonra, DateTime? once) onAralik,
  }) {
    final List<(String, DateTime?, DateTime?)> hizli = [
      ('Son 30 gün', _gunOnce(30), null),
      ('Son 3 ay', _ayOnce(3), null),
      ('30 günden eski', null, _gunOnce(30)),
      ('3 aydan eski', null, _ayOnce(3)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Secenekler<_TarihModu>(
          secili: mod,
          secenekler: [
            (_TarihModu.tumu, 'Tümü'),
            (_TarihModu.aralik, 'Tarihe göre'),
            (_TarihModu.hic, hicEtiketi),
          ],
          onSec: onMod,
        ),
        if (mod == _TarihModu.aralik) ...[
          const SizedBox(height: Bosluk.s),
          Wrap(
            spacing: Bosluk.s,
            runSpacing: Bosluk.xs,
            children: [
              for (final (etiket, s, o) in hizli)
                ChoiceChip(
                  label: Text(etiket),
                  selected: sonra == s && once == o,
                  onSelected: (secildi) =>
                      secildi ? onAralik(s, o) : onAralik(null, null),
                ),
            ],
          ),
          const SizedBox(height: Bosluk.m),
          Row(
            children: [
              Expanded(
                child: _TarihAlani(
                  etiket: 'Başlangıç',
                  tarih: sonra,
                  onSec: () async {
                    final t = await _tarihSec(sonra);
                    if (t != null) onAralik(t, once);
                  },
                  onTemizle: () => onAralik(null, once),
                ),
              ),
              const SizedBox(width: Bosluk.m),
              Expanded(
                child: _TarihAlani(
                  etiket: 'Bitiş',
                  tarih: once,
                  onSec: () async {
                    final t = await _tarihSec(once);
                    if (t != null) onAralik(sonra, t);
                  },
                  onTemizle: () => onAralik(sonra, null),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _dersBolumu() => _Bolum(
        baslik: 'Derse gelmeyenler',
        aciklama: 'Seçilen günden beri dersi olmayan (hiç dersi olmayan da)',
        child: _tekTarih(
          tarih: _f.dersOnce,
          hizli: [
            ('30 gündür', _gunOnce(30)),
            ('60 gündür', _gunOnce(60)),
            ('90 gündür', _gunOnce(90)),
          ],
          etiket: 'Şu günden beri',
          onDegis: (t) => _degistir(_f.copyWith(dersOnce: t)),
        ),
      );

  Widget _kayitBolumu() => _Bolum(
        baslik: 'Kayıt tarihi',
        aciklama: 'Seçilen gün ve sonrasında kaydolan',
        child: _tekTarih(
          tarih: _f.kayitSonra,
          hizli: [
            ('Bu ay', DateTime(_bugun.year, _bugun.month)),
            ('Son 3 ay', _ayOnce(3)),
            ('Bu yıl', DateTime(_bugun.year)),
          ],
          etiket: 'Şu günden sonra',
          onDegis: (t) => _degistir(_f.copyWith(kayitSonra: t)),
        ),
      );

  Widget _tekTarih({
    required DateTime? tarih,
    required List<(String, DateTime)> hizli,
    required String etiket,
    required ValueChanged<DateTime?> onDegis,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Bosluk.s,
          runSpacing: Bosluk.xs,
          children: [
            for (final (e, t) in hizli)
              ChoiceChip(
                label: Text(e),
                selected: tarih == t,
                onSelected: (secildi) => onDegis(secildi ? t : null),
              ),
          ],
        ),
        const SizedBox(height: Bosluk.m),
        _TarihAlani(
          etiket: etiket,
          tarih: tarih,
          onSec: () async {
            final t = await _tarihSec(tarih);
            if (t != null) onDegis(t);
          },
          onTemizle: () => onDegis(null),
        ),
      ],
    );
  }
}

class _Bolum extends StatelessWidget {
  final String baslik;
  final String? aciklama;
  final Widget child;

  const _Bolum({required this.baslik, this.aciklama, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Bosluk.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(baslik, style: context.metin.titleSmall),
          if (aciklama != null)
            Text(aciklama!, style: context.metin.bodySmall),
          const SizedBox(height: Bosluk.s),
          child,
        ],
      ),
    );
  }
}

/// Tek seçimlik çip satırı; seçili olana yeniden dokunmak bir şey yapmaz.
class _Secenekler<T> extends StatelessWidget {
  final T secili;
  final List<(T, String)> secenekler;
  final ValueChanged<T> onSec;

  const _Secenekler({
    super.key,
    required this.secili,
    required this.secenekler,
    required this.onSec,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Bosluk.s,
      runSpacing: Bosluk.xs,
      children: [
        for (final (deger, etiket) in secenekler)
          ChoiceChip(
            label: Text(etiket),
            selected: deger == secili,
            onSelected: (_) {
              if (deger != secili) onSec(deger);
            },
          ),
      ],
    );
  }
}

class _TarihAlani extends StatelessWidget {
  final String etiket;
  final DateTime? tarih;
  final VoidCallback onSec;
  final VoidCallback onTemizle;

  const _TarihAlani({
    required this.etiket,
    required this.tarih,
    required this.onSec,
    required this.onTemizle,
  });

  static final _bicim = DateFormat('dd.MM.yyyy', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    final t = tarih;
    return InkWell(
      onTap: onSec,
      borderRadius: BorderRadius.circular(Yaricap.m),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiket,
          isDense: true,
          suffixIcon: t == null
              ? const Icon(Icons.calendar_today_rounded, size: 18)
              : IconButton(
                  tooltip: 'Temizle',
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: onTemizle,
                ),
        ),
        child: Text(
          t == null ? 'Seçin' : _bicim.format(t),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t == null
              ? TextStyle(color: context.cs.onSurfaceVariant)
              : null,
        ),
      ),
    );
  }
}
