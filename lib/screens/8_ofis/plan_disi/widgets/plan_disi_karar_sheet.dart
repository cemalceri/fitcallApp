// lib/screens/8_ofis/plan_disi/widgets/plan_disi_karar_sheet.dart
//
// Plan dışı üye / misafir için karar: borç yaz, paketten düş ya da ücretsiz.
// Seçenekler (ödeyici adaylar ve aktif paketleri) sunucudan gelir; kurallar
// plan_disi_karar_service'te (açıklama zorunlu, borçta tutar > 0, paket
// ödeyene ait olmalı). Borç tutarı ofisin gördüğü tek para alanı — kullanıcı
// kararıyla (2026-10-12).

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/10_ofis/ofis_ders_yonetimi_models.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/buton_yukleniyor.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/ofis/ofis_ders_yonetimi_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Karar sayfasını açar; karar kaydedildiyse true döner.
Future<bool> planDisiKararSayfasiAc(
  BuildContext context, {
  required PlanDisiDers ders,
  required PlanDisiKisi kisi,
}) async {
  final sonuc = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Klavye boşluğu sayfanın kendi context'inden: klavye açılınca form
    // yukarı kalkar.
    builder: (c) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
      child: _PlanDisiKararSheet(ders: ders, kisi: kisi),
    ),
  );
  return sonuc ?? false;
}

class _PlanDisiKararSheet extends StatefulWidget {
  final PlanDisiDers ders;
  final PlanDisiKisi kisi;
  const _PlanDisiKararSheet({required this.ders, required this.kisi});

  @override
  State<_PlanDisiKararSheet> createState() => _PlanDisiKararSheetState();
}

class _PlanDisiKararSheetState extends State<_PlanDisiKararSheet> {
  PlanDisiSecenekler? _secenekler;
  String? _hata;
  String? _kayitHatasi;
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _hata = null);
    try {
      final s = await OfisDersYonetimiService.planDisiSecenekler(widget.kisi);
      if (mounted) setState(() => _secenekler = s);
    } on ApiException catch (e) {
      if (mounted) setState(() => _hata = e.message);
    }
  }

  Future<void> _kaydet(PlanDisiKararGirdisi g) async {
    setState(() {
      _kaydediliyor = true;
      _kayitHatasi = null;
    });
    // Başarı mesajı sayfa kapanınca alttaki sayfada gösterilir.
    final messenger = ScaffoldMessenger.of(context);
    try {
      final mesaj = await OfisDersYonetimiService.planDisiKarar(
        kisiler: [widget.kisi],
        karar: g.karar,
        aciklama: g.aciklama,
        hedefUyeId: g.hedefUyeId,
        uyeUrunId: g.uyeUrunId,
        tutar: g.tutar,
      );
      messenger.showSnackBar(SnackBar(content: Text(mesaj)));
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      // Hata formun içinde: SnackBar bu sayfanın altında kalıyordu.
      if (mounted) setState(() => _kayitHatasi = e.message);
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hata != null) {
      return SizedBox(
        height: 360,
        child: BosDurum(
          ikon: Icons.error_outline_rounded,
          baslik: 'Seçenekler alınamadı',
          aciklama: _hata!,
          ikonRengi: context.renkler.hata,
          eylemEtiketi: 'Tekrar dene',
          eylemIkonu: Icons.refresh_rounded,
          onEylem: _yukle,
          ikinciEylemEtiketi: 'Kapat',
          onIkinciEylem: () => Navigator.pop(context, false),
        ),
      );
    }
    final s = _secenekler;
    if (s == null) {
      return const SizedBox(height: 320, child: IskeletKart());
    }
    return PlanDisiKararFormu(
      ders: widget.ders,
      kisi: widget.kisi,
      secenekler: s,
      kaydediliyor: _kaydediliyor,
      hata: _kayitHatasi,
      onKaydet: _kaydet,
    );
  }
}

/// Formun ürettiği karar.
class PlanDisiKararGirdisi {
  final String karar;
  final String aciklama;
  final int? hedefUyeId;
  final int? uyeUrunId;
  final String? tutar;

  const PlanDisiKararGirdisi({
    required this.karar,
    required this.aciklama,
    this.hedefUyeId,
    this.uyeUrunId,
    this.tutar,
  });
}

/// Karar formu — veriyle beslenir (taşma testi).
class PlanDisiKararFormu extends StatefulWidget {
  final PlanDisiDers ders;
  final PlanDisiKisi kisi;
  final PlanDisiSecenekler secenekler;
  final bool kaydediliyor;

  /// Sunucunun reddetme mesajı (kaydet düğmesinin üstünde gösterilir).
  final String? hata;
  final ValueChanged<PlanDisiKararGirdisi> onKaydet;

  const PlanDisiKararFormu({
    super.key,
    required this.ders,
    required this.kisi,
    required this.secenekler,
    required this.kaydediliyor,
    this.hata,
    required this.onKaydet,
  });

  @override
  State<PlanDisiKararFormu> createState() => _PlanDisiKararFormuState();
}

class _PlanDisiKararFormuState extends State<PlanDisiKararFormu> {
  final _form = GlobalKey<FormState>();
  final _aciklama = TextEditingController();
  final _tutar = TextEditingController();
  String _karar = 'BORC';
  int? _hedefUyeId;
  int? _paketId;

  @override
  void initState() {
    super.initState();
    final adaylar = widget.secenekler.adaylar;
    final varsayilan =
        adaylar.where((a) => a.varsayilan).firstOrNull ?? adaylar.firstOrNull;
    _hedefUyeId = varsayilan?.uyeId;
  }

  @override
  void dispose() {
    _aciklama.dispose();
    _tutar.dispose();
    super.dispose();
  }

  PlanDisiAday? get _hedef => widget.secenekler.adaylar
      .where((a) => a.uyeId == _hedefUyeId)
      .firstOrNull;

  void _kaydet() {
    if (!(_form.currentState?.validate() ?? false)) return;
    HapticFeedback.lightImpact();
    widget.onKaydet(PlanDisiKararGirdisi(
      karar: _karar,
      aciklama: _aciklama.text.trim(),
      hedefUyeId: _hedefUyeId,
      uyeUrunId: _karar == 'PAKET' ? _paketId : null,
      tutar: _karar == 'BORC' ? _tutar.text.trim().replaceAll(',', '.') : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final paketler = _hedef?.paketler ?? const <PlanDisiPaket>[];
    return Form(
      key: _form,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text('Plan dışı karar', style: context.metin.titleLarge),
          const SizedBox(height: 2),
          Text(
            '${widget.kisi.adSoyad} · '
            '${widget.kisi.misafirMi ? 'misafir' : 'plan dışı üye'} · '
            '${widget.ders.kort}',
            style: context.metin.bodySmall,
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'BORC', label: Text('Borç yaz')),
              ButtonSegment(value: 'PAKET', label: Text('Paketten')),
              ButtonSegment(value: 'UCRETSIZ', label: Text('Ücretsiz')),
            ],
            selected: {_karar},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _karar = s.first),
          ),
          const SizedBox(height: 16),
          if (_karar != 'UCRETSIZ')
            DropdownButtonFormField<int>(
              initialValue: _hedefUyeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Ücreti üstlenen'),
              items: [
                for (final a in widget.secenekler.adaylar)
                  DropdownMenuItem(
                    value: a.uyeId,
                    child: Text(a.adSoyad,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() {
                _hedefUyeId = v;
                _paketId = null;
              }),
              validator: (v) =>
                  v == null ? 'Ücreti üstlenen kişiyi seçin.' : null,
            ),
          if (_karar == 'PAKET') ...[
            const SizedBox(height: 12),
            if (paketler.isEmpty)
              Text(
                'Bu kişinin aktif paketi yok. Başka bir kişi seçin ya da borç yazın.',
                style: context.metin.bodySmall
                    ?.copyWith(color: context.renkler.hata),
              )
            else
              DropdownButtonFormField<int>(
                initialValue: _paketId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Paket'),
                items: [
                  for (final p in paketler)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(p.etiket,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _paketId = v),
                validator: (v) => v == null ? 'Paket seçin.' : null,
              ),
          ],
          if (_karar == 'BORC') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _tutar,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Tutar',
                suffixText: '₺',
              ),
              validator: (v) {
                final t = double.tryParse((v ?? '').replaceAll(',', '.'));
                return (t == null || t <= 0)
                    ? 'Geçerli bir tutar girin.'
                    : null;
              },
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _aciklama,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Açıklama',
              hintText: 'Ör. Ayşe\'nin misafiri, deneme dersi',
            ),
            validator: (v) => (v ?? '').trim().isEmpty
                ? 'Açıklama zorunlu: borcun hangi dersten geldiği buradan anlaşılır.'
                : null,
          ),
          if (widget.hata != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 18, color: context.renkler.hata),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(widget.hata!,
                      style: context.metin.bodySmall
                          ?.copyWith(color: context.renkler.hata)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: widget.kaydediliyor ? null : _kaydet,
            child: widget.kaydediliyor
                ? const SizedBox(
                    width: 20, height: 20, child: ButonYukleniyorGostergesi())
                : const Text('Kararı kaydet'),
          ),
        ],
      ),
    );
  }
}
