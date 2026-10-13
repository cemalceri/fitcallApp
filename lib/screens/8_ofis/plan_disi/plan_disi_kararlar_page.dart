// lib/screens/8_ofis/plan_disi/plan_disi_kararlar_page.dart
//
// Karar bekleyen plan dışı üyeler ve misafirler (web "Plan Dışı & Misafir"
// sayfasının "Karar bekleyenler" sekmesi). Ders bazında gruplu, en yeni üstte.
// Kişiye dokununca karar formu açılır; ödeme alma ve üyeye aktarma web'de.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/10_ofis/ofis_ders_yonetimi_models.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/8_ofis/plan_disi/widgets/plan_disi_karar_sheet.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/ofis/ofis_ders_yonetimi_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlanDisiKararlarPage extends StatefulWidget {
  const PlanDisiKararlarPage({super.key});

  @override
  State<PlanDisiKararlarPage> createState() => _PlanDisiKararlarPageState();
}

class _PlanDisiKararlarPageState extends State<PlanDisiKararlarPage> {
  List<PlanDisiDers> _dersler = const [];
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle({bool iskelet = true}) async {
    setState(() {
      if (iskelet) _yukleniyor = true;
      _hata = null;
    });
    try {
      final dersler = await OfisDersYonetimiService.planDisiBekleyenler();
      if (!mounted) return;
      setState(() {
        _dersler = dersler;
        _yukleniyor = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.message;
        _yukleniyor = false;
      });
    }
  }

  Future<void> _kisiSec(PlanDisiDers ders, PlanDisiKisi kisi) async {
    final kaydedildi =
        await planDisiKararSayfasiAc(context, ders: ders, kisi: kisi);
    if (kaydedildi && mounted) _yukle(iskelet: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan Dışı Kararlar')),
      body: PlanDisiKararlarGorunumu(
        dersler: _dersler,
        yukleniyor: _yukleniyor,
        hata: _hata,
        onKisiSec: _kisiSec,
        onYenile: () => _yukle(iskelet: false),
        onYenidenDene: _yukle,
      ),
    );
  }
}

/// Sunum gövdesi (taşma testinde doğrudan çizilir).
class PlanDisiKararlarGorunumu extends StatelessWidget {
  final List<PlanDisiDers> dersler;
  final bool yukleniyor;
  final String? hata;
  final void Function(PlanDisiDers, PlanDisiKisi) onKisiSec;
  final Future<void> Function() onYenile;
  final VoidCallback onYenidenDene;

  const PlanDisiKararlarGorunumu({
    super.key,
    required this.dersler,
    required this.yukleniyor,
    required this.hata,
    required this.onKisiSec,
    required this.onYenile,
    required this.onYenidenDene,
  });

  static final _tarih = DateFormat('d MMM EEE · HH:mm', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) return const IskeletListe();
    if (hata != null) {
      return BosDurum(
        ikon: Icons.error_outline_rounded,
        baslik: 'Liste alınamadı',
        aciklama: hata!,
        ikonRengi: context.renkler.hata,
        eylemEtiketi: 'Tekrar dene',
        eylemIkonu: Icons.refresh_rounded,
        onEylem: onYenidenDene,
      );
    }
    if (dersler.isEmpty) {
      return BosDurum(
        ikon: Icons.task_alt_rounded,
        baslik: 'Karar bekleyen kimse yok',
        aciklama: 'Antrenör derse plan dışı üye ya da misafir eklediğinde '
            'burada görünür.',
        ikonRengi: context.renkler.basari,
      );
    }
    return RefreshIndicator(
      onRefresh: onYenile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final d in dersler) ...[
            _DersBasligi(ders: d, tarih: _tarih.format(d.baslangic)),
            for (final (i, k) in d.kisiler.indexed) ...[
              if (i > 0) const ListeAyraci(),
              ListeSatiri(
                onGorsel: ListeAvatari(
                  basHarfler: ListeAvatari.harfler(k.adSoyad),
                  ton: k.misafirMi ? ListeTonu.uyari : ListeTonu.bilgi,
                ),
                baslik: k.adSoyad,
                altBaslik: [
                  k.misafirMi ? 'Misafir' : 'Plan dışı üye',
                  if (k.notMetni != null) k.notMetni!,
                ].join(' · '),
                okGoster: true,
                onTap: () => onKisiSec(d, k),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DersBasligi extends StatelessWidget {
  final PlanDisiDers ders;
  final String tarih;
  const _DersBasligi({required this.ders, required this.tarih});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$tarih · ${ders.kort}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                context.metin.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            '${ders.antrenor} · ${ders.urun}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.metin.bodySmall,
          ),
        ],
      ),
    );
  }
}
