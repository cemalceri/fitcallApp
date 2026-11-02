// lib/screens/8_ofis/ders_kayit_talepleri/uye_talep_detay_page.dart
//
// Ofisin üye talebi detay sayfası. Açılınca sunucu talebi "X bakıyor" diye
// işaretler. İşlemler OfisUyeTalepService'e gider; kurallar sunucuda
// (uye_talep_service.py), hata mesajı olduğu gibi gösterilir.

import 'package:fitcall/models/10_ofis/ofis_uye_talep_models.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/yikici_buton.dart';
import 'package:fitcall/screens/8_ofis/ders_kayit_talepleri/widgets/oneri_formu.dart';
import 'package:fitcall/screens/8_ofis/ders_kayit_talepleri/widgets/uye_talep_detay_gorunumu.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_kayit_talebi_service.dart';
import 'package:fitcall/services/ofis/ofis_uye_talep_service.dart';
import 'package:flutter/material.dart';

class OfisUyeTalepDetayPage extends StatefulWidget {
  final int talepId;

  const OfisUyeTalepDetayPage({super.key, required this.talepId});

  @override
  State<OfisUyeTalepDetayPage> createState() => _OfisUyeTalepDetayPageState();
}

class _OfisUyeTalepDetayPageState extends State<OfisUyeTalepDetayPage> {
  OfisTalepDetay? _detay;
  String? _hata;
  bool _isleniyor = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _hata = null);
    try {
      final d = await OfisUyeTalepService.detay(widget.talepId);
      if (mounted) setState(() => _detay = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _hata = e.message);
    } catch (_) {
      if (mounted) setState(() => _hata = 'Talep yüklenemedi.');
    }
  }

  Future<void> _calistir(Future<String> Function() is_) async {
    setState(() => _isleniyor = true);
    try {
      final mesaj = await is_();
      if (mounted) ShowMessage.success(context, mesaj);
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } catch (_) {
      if (mounted) ShowMessage.error(context, 'İşlem yapılamadı.');
    } finally {
      if (mounted) setState(() => _isleniyor = false);
    }
    await _yukle();
  }

  /// "Fark etmez" talepte hoca seçtirir; hoca belliyse null döner.
  Future<int?> _hocaSec() async {
    final d = _detay!;
    if (!d.talep.hocaFarkEtmez) return d.talep.antrenorId;
    final bos = d.hocalar.where((h) => h.bos).toList();
    if (bos.isEmpty) {
      ShowMessage.error(context, 'Bu saatte boş hoca yok. Değişiklik öner.');
      return null;
    }
    return showDialog<int>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Hangi hoca?'),
        children: [
          for (final h in bos)
            SimpleDialogOption(
                onPressed: () => Navigator.pop(c, h.id), child: Text(h.ad)),
        ],
      ),
    );
  }

  Future<void> _hocayaSor() async {
    final hoca = await _hocaSec();
    if (hoca == null || !mounted) return;
    _calistir(
        () => OfisUyeTalepService.hocayaSor(widget.talepId, antrenorId: hoca));
  }

  Future<void> _telefonOnay() async {
    final hoca = await _hocaSec();
    if (hoca == null || !mounted) return;
    _calistir(() =>
        OfisUyeTalepService.telefonOnay(widget.talepId, antrenorId: hoca));
  }

  Future<void> _kaydet() async {
    final d = _detay!;
    KayitSecimi secim = const KayitSecimi();
    if (KayitSecimSheet.gerekli(d)) {
      final s = await showModalBottomSheet<KayitSecimi>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => KayitSecimSheet(detay: d),
      );
      if (s == null || !mounted) return;
      secim = s;
    } else {
      final evet = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Kayıt oluştur'),
          content: Text(
              '${d.talep.uyeAdi} · ${d.talep.dersTanimi}\nDers programa eklenecek, üyeye bildirim gidecek.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Vazgeç')),
            FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Kaydet')),
          ],
        ),
      );
      if (evet != true || !mounted) return;
    }
    _calistir(() => OfisUyeTalepService.kaydet(
          widget.talepId,
          kortId: secim.kortId,
          baslangic: secim.baslangic,
          urunId: secim.urunId,
        ));
  }

  Future<void> _oneri() async {
    final istek = await showModalBottomSheet<OneriIstegi>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => OneriFormuSheet(
        detay: _detay!,
        bosListeGetir: (bas, sure) => OfisUyeTalepService.detay(widget.talepId,
            baslangic: bas, sureDk: sure),
      ),
    );
    if (istek == null || !mounted) return;
    _calistir(() => OfisUyeTalepService.oneri(
          widget.talepId,
          baslangic: istek.baslangic,
          sureDk: istek.sureDk,
          antrenorId: istek.antrenorId,
          kortId: istek.kortId,
          kisiSayisi: istek.kisiSayisi,
          urunId: istek.urunId,
          ekstraUcret: istek.ekstraUcret,
          notu: istek.notu,
          hocaOnayladi: istek.hocaOnayladi,
          uyeTelefondaOnayladi: istek.uyeTelefondaOnayladi,
        ));
  }

  Future<void> _reddet() async {
    final neden = await showDialog<String>(
      context: context,
      builder: (_) => const _RedDialog(),
    );
    if (neden == null || !mounted) return;
    _calistir(() => DersKayitTalebiService.reddet(widget.talepId, neden));
  }

  Future<void> _oneriGeriCek() async {
    final evet = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: const Text(
            'Öneriyi geri çekersen talep Bende\'ye döner ve üyeye bildirim gider.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Vazgeç')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Geri çek')),
        ],
      ),
    );
    if (evet != true || !mounted) return;
    _calistir(() => OfisUyeTalepService.oneriGeriCek(widget.talepId));
  }

  @override
  Widget build(BuildContext context) {
    final d = _detay;
    return Scaffold(
      appBar: AppBar(title: const Text('Üye talebi')),
      body: SafeArea(
        top: false,
        child: d == null
            ? (_hata != null
                ? BosDurum(
                    ikon: Icons.error_outline_rounded,
                    baslik: 'Açılamadı',
                    aciklama: _hata!,
                    eylemEtiketi: 'Tekrar dene',
                    eylemIkonu: Icons.refresh_rounded,
                    onEylem: _yukle,
                  )
                : const IskeletListe())
            : RefreshIndicator(
                onRefresh: _yukle,
                child: OfisUyeTalepDetayGorunumu(
                  detay: d,
                  isleniyor: _isleniyor,
                  onHocayaSor: _hocayaSor,
                  onTelefonOnay: _telefonOnay,
                  onKaydet: _kaydet,
                  onOneri: _oneri,
                  onReddet: _reddet,
                  onOneriGeriCek: _oneriGeriCek,
                ),
              ),
      ),
    );
  }
}

class _RedDialog extends StatefulWidget {
  const _RedDialog();

  @override
  State<_RedDialog> createState() => _RedDialogState();
}

class _RedDialogState extends State<_RedDialog> {
  final _neden = TextEditingController();
  String? _hata;

  @override
  void dispose() {
    _neden.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Talebi reddet'),
      content: TextField(
        controller: _neden,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        maxLength: 500,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
            labelText: 'Neden',
            hintText: 'Üyeye bildirimle gider',
            errorText: _hata),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç')),
        YikiciButon(
          etiket: 'Reddet',
          onPressed: () {
            final n = _neden.text.trim();
            if (n.isEmpty) {
              setState(() => _hata = 'Neden yazmak zorunlu.');
              return;
            }
            Navigator.pop(context, n);
          },
        ),
      ],
    );
  }
}
