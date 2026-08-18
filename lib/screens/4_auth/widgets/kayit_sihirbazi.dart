// lib/screens/4_auth/widgets/kayit_sihirbazi.dart
//
// Üyelik başvuru formu — adım adım.
//
// Neden sihirbaz: kulübün istediği bilgi (kimlik, iletişim, veli, tercih) tek
// ekranda ~20 alan ediyor. Web'de kabul edilebilir; telefonda alt alta yirmi
// kutu insanı formu bırakmaya iter. Alanların hepsi duruyor, yalnız dört adıma
// bölündü ve her adımda ilerleme çubuğu ne kadar kaldığını söylüyor.
//
// Adımlar:
//   1. Kulüp & kimlik      — kulüp, ad, soyad, doğum tarihi, cinsiyet
//   2. İletişim            — telefon, e-posta, adres, acil durum
//   3. Veli / meslek       — doğum tarihine göre DEĞİŞİR (18 yaş altı → veli
//                            bilgisi zorunlu, üstü → meslek)
//   4. Tercihler & onay    — tenis geçmişi, program tercihi, KVKK
//
// Doğrulama iki katmanlı: burada anında geri bildirim, sunucuda `UyeMobilKayitForm`
// son söz. Buradaki kurallar backend'in kopyası değil özeti — çelişki olursa
// sunucunun mesajı gösterilir.
//
// Sayfa API çağırdığı için doğrudan pump edilemiyor; bu widget veriyle beslenen
// ayrı bir parça (taşma testi bunu ölçüyor — bkz. test/tasma_ekranlar_test.dart).

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/4_auth/kayit_secenekleri_model.dart';
import 'package:fitcall/screens/1_common/widgets/kvkk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// 18 yaş altı başvurularda veli bilgisi zorunlu (backend kuralı).
const int _yetiskinYasi = 18;

class KayitSihirbazi extends StatefulWidget {
  final KayitSecenekleri secenekler;

  /// Doldurulan alanları API gövdesi olarak verir; gönderimi sayfa yapar.
  final Future<void> Function(Map<String, dynamic> alanlar) onGonder;

  /// Gönderim sürüyor — butonlar kilitlenir.
  final bool gonderiliyor;

  const KayitSihirbazi({
    super.key,
    required this.secenekler,
    required this.onGonder,
    this.gonderiliyor = false,
  });

  @override
  State<KayitSihirbazi> createState() => _KayitSihirbaziState();
}

class _KayitSihirbaziState extends State<KayitSihirbazi> {
  final _adimAnahtarlari = List.generate(4, (_) => GlobalKey<FormState>());

  int _adim = 0;

  // 1. adım
  String? _isletme;
  final _adCtrl = TextEditingController();
  final _soyadCtrl = TextEditingController();
  DateTime? _dogumTarihi;
  String? _cinsiyet;

  // 2. adım
  final _telefonCtrl = TextEditingController();
  final _epostaCtrl = TextEditingController();
  final _adresCtrl = TextEditingController();
  final _acilKisiCtrl = TextEditingController();
  final _acilTelefonCtrl = TextEditingController();

  // 3. adım — yetişkin
  final _meslekCtrl = TextEditingController();

  // 3. adım — 18 yaş altı
  final _anneAdCtrl = TextEditingController();
  final _anneTelCtrl = TextEditingController();
  final _anneMailCtrl = TextEditingController();
  final _anneMeslekCtrl = TextEditingController();
  final _babaAdCtrl = TextEditingController();
  final _babaTelCtrl = TextEditingController();
  final _babaMailCtrl = TextEditingController();
  final _babaMeslekCtrl = TextEditingController();
  String? _okul;

  // 4. adım
  String? _tenisGecmisi;
  String? _programTercihi;
  bool _kvkkOnay = false;

  @override
  void dispose() {
    for (final c in [
      _adCtrl, _soyadCtrl, _telefonCtrl, _epostaCtrl, _adresCtrl,
      _acilKisiCtrl, _acilTelefonCtrl, _meslekCtrl,
      _anneAdCtrl, _anneTelCtrl, _anneMailCtrl, _anneMeslekCtrl,
      _babaAdCtrl, _babaTelCtrl, _babaMailCtrl, _babaMeslekCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /* ----------------------------- Yardımcılar ----------------------------- */

  int? get _yas {
    final d = _dogumTarihi;
    if (d == null) return null;
    final bugun = DateTime.now();
    var yas = bugun.year - d.year;
    if (bugun.month < d.month || (bugun.month == d.month && bugun.day < d.day)) {
      yas--;
    }
    return yas;
  }

  bool get _cocukMu => (_yas ?? _yetiskinYasi) < _yetiskinYasi;

  String get _adimBasligi => switch (_adim) {
        0 => 'Kulüp ve kimlik',
        1 => 'İletişim',
        2 => _cocukMu ? 'Veli bilgileri' : 'Ek bilgiler',
        _ => 'Tercihler ve onay',
      };

  String get _adimAciklamasi => switch (_adim) {
        0 => 'Hangi kulübe başvurduğunuzu ve kimlik bilgilerinizi girin.',
        1 => 'Kulübün size ulaşacağı bilgiler.',
        2 => _cocukMu
            ? '18 yaş altı başvurularda en az bir veli bilgisi zorunludur.'
            : 'İsteğe bağlı — boş bırakabilirsiniz.',
        _ => 'Son adım: nasıl bir program aradığınızı belirtin.',
      };

  /// Boşlukları temizler; boş metin yerine null döner (API'ye boş alan gitmesin).
  String? _metin(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Map<String, dynamic> _alanlar() => {
        'isletme': _isletme,
        'adi': _adCtrl.text.trim(),
        'soyadi': _soyadCtrl.text.trim(),
        'cinsiyet': _cinsiyet,
        'dogum_tarihi': DateFormat('yyyy-MM-dd').format(_dogumTarihi!),
        'telefon': _telefonCtrl.text.trim(),
        'email': _epostaCtrl.text.trim(),
        'adres': _metin(_adresCtrl),
        'acil_durum_kisi': _metin(_acilKisiCtrl),
        'acil_durum_telefon': _metin(_acilTelefonCtrl),
        'meslek': _cocukMu ? null : _metin(_meslekCtrl),
        'anne_adi_soyadi': _cocukMu ? _metin(_anneAdCtrl) : null,
        'anne_telefon': _cocukMu ? _metin(_anneTelCtrl) : null,
        'anne_mail': _cocukMu ? _metin(_anneMailCtrl) : null,
        'anne_meslek': _cocukMu ? _metin(_anneMeslekCtrl) : null,
        'baba_adi_soyadi': _cocukMu ? _metin(_babaAdCtrl) : null,
        'baba_telefon': _cocukMu ? _metin(_babaTelCtrl) : null,
        'baba_mail': _cocukMu ? _metin(_babaMailCtrl) : null,
        'baba_meslek': _cocukMu ? _metin(_babaMeslekCtrl) : null,
        'okul': _cocukMu ? _okul : null,
        'tenis_gecmisi_var_mi': _tenisGecmisi,
        'program_tercihi': _programTercihi,
        'kvkk_onay': _kvkkOnay,
      };

  /* ------------------------------- Akış ---------------------------------- */

  void _ileri() {
    if (!(_adimAnahtarlari[_adim].currentState?.validate() ?? false)) return;

    // Alan doğrulaması dışında kalan iki kural: doğum tarihi seçilmiş olmalı,
    // 18 yaş altında en az bir veli adı + telefonu bulunmalı.
    if (_adim == 0 && _dogumTarihi == null) {
      _uyar('Doğum tarihi seçin.');
      return;
    }
    if (_adim == 2 && _cocukMu && !_veliBilgisiTam()) {
      _uyar('En az bir veli için ad-soyad ve telefon girin.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _adim++);
    _basaKaydir();
  }

  /// Adım değişince sayfayı başa al: yeni adımın ilk alanı ekranın altında
  /// kalıyordu (kullanıcı bir önceki adımın sonundaydı).
  void _basaKaydir() {
    final kaydirma = PrimaryScrollController.maybeOf(context);
    if (kaydirma == null || !kaydirma.hasClients) return;
    kaydirma.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  bool _veliBilgisiTam() {
    final adVar = _metin(_anneAdCtrl) != null || _metin(_babaAdCtrl) != null;
    final telVar = _metin(_anneTelCtrl) != null || _metin(_babaTelCtrl) != null;
    return adVar && telVar;
  }

  void _geri() {
    FocusScope.of(context).unfocus();
    setState(() => _adim--);
    _basaKaydir();
  }

  void _uyar(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mesaj)));
  }

  Future<void> _gonder() async {
    if (!(_adimAnahtarlari[_adim].currentState?.validate() ?? false)) return;
    if (!_kvkkOnay) {
      _uyar('Devam etmek için KVKK aydınlatma metnini onaylayın.');
      return;
    }
    FocusScope.of(context).unfocus();
    await widget.onGonder(_alanlar());
  }

  Future<void> _tarihSec() async {
    final bugun = DateTime.now();
    final secilen = await showDatePicker(
      context: context,
      initialDate: _dogumTarihi ?? DateTime(bugun.year - 20, bugun.month, bugun.day),
      firstDate: DateTime(bugun.year - 100),
      lastDate: bugun,
      helpText: 'Doğum tarihi',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
    );
    if (secilen != null) setState(() => _dogumTarihi = secilen);
  }

  /* -------------------------------- UI ----------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AdimBasligi(
          adim: _adim,
          toplam: _adimAnahtarlari.length,
          baslik: _adimBasligi,
          aciklama: _adimAciklamasi,
        ),
        const SizedBox(height: Bosluk.l),
        Form(
          key: _adimAnahtarlari[_adim],
          child: switch (_adim) {
            0 => _kimlikAdimi(),
            1 => _iletisimAdimi(),
            2 => _cocukMu ? _veliAdimi() : _yetiskinAdimi(),
            _ => _tercihAdimi(),
          },
        ),
        const SizedBox(height: Bosluk.xl),
        _butonlar(),
      ],
    );
  }

  Widget _butonlar() {
    final sonAdim = _adim == _adimAnahtarlari.length - 1;

    return Row(
      children: [
        if (_adim > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: widget.gonderiliyor ? null : _geri,
              child: const Text('Geri'),
            ),
          ),
          const SizedBox(width: Bosluk.m),
        ],
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: widget.gonderiliyor ? null : (sonAdim ? _gonder : _ileri),
            child: widget.gonderiliyor
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(sonAdim ? 'Başvuruyu gönder' : 'Devam'),
          ),
        ),
      ],
    );
  }

  /* ------------------------------ Adımlar -------------------------------- */

  Widget _kimlikAdimi() {
    return Column(
      children: [
        _SecimAlani(
          etiket: 'Kulüp',
          ikon: Icons.apartment_rounded,
          secenekler: widget.secenekler.isletmeler,
          deger: _isletme,
          zorunlu: true,
          onDegisti: (v) => setState(() => _isletme = v),
        ),
        const SizedBox(height: Bosluk.m),
        TextFormField(
          controller: _adCtrl,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Ad',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Ad gerekli' : null,
        ),
        const SizedBox(height: Bosluk.m),
        TextFormField(
          controller: _soyadCtrl,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Soyad',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Soyad gerekli' : null,
        ),
        const SizedBox(height: Bosluk.m),
        _TarihAlani(
          tarih: _dogumTarihi,
          yas: _yas,
          onSec: _tarihSec,
        ),
        const SizedBox(height: Bosluk.m),
        _SecimAlani(
          etiket: 'Cinsiyet',
          ikon: Icons.wc_rounded,
          secenekler: widget.secenekler.cinsiyetler,
          deger: _cinsiyet,
          onDegisti: (v) => setState(() => _cinsiyet = v),
        ),
      ],
    );
  }

  Widget _iletisimAdimi() {
    return Column(
      children: [
        _TelefonAlani(
          controller: _telefonCtrl,
          etiket: 'Cep telefonu',
          zorunlu: true,
        ),
        const SizedBox(height: Bosluk.m),
        _EpostaAlani(controller: _epostaCtrl, etiket: 'E-posta', zorunlu: true),
        const SizedBox(height: Bosluk.m),
        TextFormField(
          controller: _adresCtrl,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Adres (isteğe bağlı)',
            prefixIcon: Icon(Icons.home_outlined),
          ),
        ),
        const SizedBox(height: Bosluk.l),
        const _AyracBaslik('Acil durumda aranacak kişi (isteğe bağlı)'),
        const SizedBox(height: Bosluk.m),
        TextFormField(
          controller: _acilKisiCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Ad soyad',
            prefixIcon: Icon(Icons.contact_emergency_outlined),
          ),
        ),
        const SizedBox(height: Bosluk.m),
        _TelefonAlani(controller: _acilTelefonCtrl, etiket: 'Telefon'),
      ],
    );
  }

  Widget _yetiskinAdimi() {
    return Column(
      children: [
        TextFormField(
          controller: _meslekCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Meslek (isteğe bağlı)',
            prefixIcon: Icon(Icons.work_outline_rounded),
          ),
        ),
      ],
    );
  }

  Widget _veliAdimi() {
    return Column(
      children: [
        const _AyracBaslik('Anne'),
        const SizedBox(height: Bosluk.m),
        TextFormField(
          controller: _anneAdCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Ad soyad',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: Bosluk.m),
        _TelefonAlani(controller: _anneTelCtrl, etiket: 'Telefon'),
        const SizedBox(height: Bosluk.m),
        _EpostaAlani(controller: _anneMailCtrl, etiket: 'E-posta'),
        const SizedBox(height: Bosluk.m),
        TextFormField(
          controller: _anneMeslekCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Meslek',
            prefixIcon: Icon(Icons.work_outline_rounded),
          ),
        ),
        const SizedBox(height: Bosluk.l),
        const _AyracBaslik('Baba'),
        const SizedBox(height: Bosluk.m),
        TextFormField(
          controller: _babaAdCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Ad soyad',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: Bosluk.m),
        _TelefonAlani(controller: _babaTelCtrl, etiket: 'Telefon'),
        const SizedBox(height: Bosluk.m),
        _EpostaAlani(controller: _babaMailCtrl, etiket: 'E-posta'),
        const SizedBox(height: Bosluk.m),
        TextFormField(
          controller: _babaMeslekCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Meslek',
            prefixIcon: Icon(Icons.work_outline_rounded),
          ),
        ),
        const SizedBox(height: Bosluk.l),
        _SecimAlani(
          etiket: 'Okul (isteğe bağlı)',
          ikon: Icons.school_outlined,
          secenekler: widget.secenekler.okullar,
          deger: _okul,
          onDegisti: (v) => setState(() => _okul = v),
        ),
      ],
    );
  }

  Widget _tercihAdimi() {
    return Column(
      children: [
        _SecimAlani(
          etiket: 'Tenis geçmişiniz',
          ikon: Icons.sports_tennis_rounded,
          secenekler: widget.secenekler.tenisGecmisi,
          deger: _tenisGecmisi,
          onDegisti: (v) => setState(() => _tenisGecmisi = v),
        ),
        const SizedBox(height: Bosluk.m),
        _SecimAlani(
          etiket: 'Program tercihi',
          ikon: Icons.flag_outlined,
          secenekler: widget.secenekler.programTercihleri,
          deger: _programTercihi,
          onDegisti: (v) => setState(() => _programTercihi = v),
        ),
        const SizedBox(height: Bosluk.l),
        _KvkkSatiri(
          onay: _kvkkOnay,
          onDegisti: (v) => setState(() => _kvkkOnay = v),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              ORTAK PARÇALAR                                */
/* -------------------------------------------------------------------------- */

/// "2 / 4" + ilerleme çubuğu + adım başlığı.
class _AdimBasligi extends StatelessWidget {
  final int adim;
  final int toplam;
  final String baslik;
  final String aciklama;

  const _AdimBasligi({
    required this.adim,
    required this.toplam,
    required this.baslik,
    required this.aciklama,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(baslik,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.titleMedium),
            ),
            const SizedBox(width: Bosluk.s),
            Text('${adim + 1} / $toplam',
                style: context.metin.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: Bosluk.s),
        ClipRRect(
          borderRadius: BorderRadius.circular(Yaricap.s),
          child: LinearProgressIndicator(
            value: (adim + 1) / toplam,
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: Bosluk.s),
        Text(aciklama,
            style:
                context.metin.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _AyracBaslik extends StatelessWidget {
  final String metin;

  const _AyracBaslik(this.metin);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        metin.toUpperCase(),
        style: context.metin.labelMedium?.copyWith(
          letterSpacing: 0.8,
          color: context.cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Açılır seçim — kulüp, okul ve enum alanlarının tamamı bunu kullanır.
class _SecimAlani extends StatelessWidget {
  final String etiket;
  final IconData ikon;
  final List<Secenek> secenekler;
  final String? deger;
  final bool zorunlu;
  final ValueChanged<String?> onDegisti;

  const _SecimAlani({
    required this.etiket,
    required this.ikon,
    required this.secenekler,
    required this.deger,
    required this.onDegisti,
    this.zorunlu = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: deger,
      isExpanded: true, // uzun kulüp/okul adları taşmasın
      decoration: InputDecoration(
        labelText: etiket,
        prefixIcon: Icon(ikon),
      ),
      items: [
        for (final s in secenekler)
          DropdownMenuItem(
            value: s.deger,
            child: Text(s.etiket, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onDegisti,
      validator: zorunlu
          ? (v) => (v == null || v.isEmpty) ? '$etiket seçin' : null
          : null,
    );
  }
}

/// Doğum tarihi: metin kutusu değil, takvim. Seçilince yaş da yazılır — 18 yaş
/// altı başvurularda veli adımının neden çıktığı anlaşılsın.
class _TarihAlani extends StatelessWidget {
  final DateTime? tarih;
  final int? yas;
  final VoidCallback onSec;

  const _TarihAlani({required this.tarih, required this.yas, required this.onSec});

  @override
  Widget build(BuildContext context) {
    final secili = tarih != null;

    return InkWell(
      onTap: onSec,
      borderRadius: BorderRadius.circular(Yaricap.m),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Doğum tarihi',
          prefixIcon: const Icon(Icons.cake_outlined),
          suffixIcon: const Icon(Icons.calendar_month_outlined),
          helperText: secili && yas != null ? '$yas yaşında' : null,
        ),
        child: Text(
          secili
              ? DateFormat('d MMMM y', 'tr_TR').format(tarih!)
              : 'Takvimden seçin',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: secili
              ? null
              : TextStyle(color: context.cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Telefon: 10 hane, başında sıfır yok (backend kuralı). Kullanıcı 0 ile
/// başlarsa yazarken temizlenir, uyarı verilmez.
class _TelefonAlani extends StatelessWidget {
  final TextEditingController controller;
  final String etiket;
  final bool zorunlu;

  const _TelefonAlani({
    required this.controller,
    required this.etiket,
    this.zorunlu = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
      decoration: InputDecoration(
        labelText: zorunlu ? etiket : '$etiket (isteğe bağlı)',
        prefixIcon: const Icon(Icons.phone_outlined),
        hintText: '5551112233',
      ),
      validator: (v) {
        final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
        final temiz = digits.startsWith('0') ? digits.substring(1) : digits;
        if (temiz.isEmpty) return zorunlu ? '$etiket gerekli' : null;
        return temiz.length == 10 ? null : '10 hane olmalı (5551112233)';
      },
    );
  }
}

class _EpostaAlani extends StatelessWidget {
  final TextEditingController controller;
  final String etiket;
  final bool zorunlu;

  const _EpostaAlani({
    required this.controller,
    required this.etiket,
    this.zorunlu = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: zorunlu ? etiket : '$etiket (isteğe bağlı)',
        prefixIcon: const Icon(Icons.mail_outline_rounded),
      ),
      validator: (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return zorunlu ? '$etiket gerekli' : null;
        final gecerli = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
        return gecerli ? null : 'Geçerli bir e-posta girin';
      },
    );
  }
}

class _KvkkSatiri extends StatelessWidget {
  final bool onay;
  final ValueChanged<bool> onDegisti;

  const _KvkkSatiri({required this.onay, required this.onDegisti});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(value: onay, onChanged: (v) => onDegisti(v ?? false)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('KVKK aydınlatma metnini ',
                    style: context.metin.bodyMedium),
                InkWell(
                  onTap: () => showKvkkAydinlatmaModal(context),
                  child: Text(
                    'okudum, onaylıyorum',
                    style: context.metin.bodyMedium?.copyWith(
                      color: context.cs.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: context.cs.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
