// lib/screens/3_antrenor/program/widgets/program_bilgi_sheet.dart
//
// Antrenörün tüm programında dokunulan ders ya da kendi bekleyen talebi.
// Ders için yalnız bilgi var — değişiklikler ofiste yapılır. Talep için tek
// eylem "Geri çek".

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/1_common/program/talep_notu_kutusu.dart';
import 'package:fitcall/screens/1_common/widgets/alt_sayfa.dart';
import 'package:fitcall/screens/1_common/widgets/yikici_buton.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_kayit_talebi_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String _gunMetni(DateTime t) => DateFormat('d MMMM EEEE', 'tr_TR').format(t);

class ProgramDersBilgiSheet extends StatelessWidget {
  final ProgramDersi ders;
  final bool benim;

  const ProgramDersBilgiSheet({
    super.key,
    required this.ders,
    this.benim = false,
  });

  static Future<void> ac(BuildContext context, ProgramDersi ders,
      {bool benim = false}) {
    return altSayfaGoster<void>(
      context,
      cocuk: ProgramDersBilgiSheet(ders: ders, benim: benim),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final katilimcilar = ders.katilimcilar.map((k) => k.adSoyad).join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: Bosluk.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AltSayfaBasligi(
            ikon: benim ? Icons.person_rounded : Icons.sports_tennis_rounded,
            baslik: '${ders.saat}-${ders.bitisSaat} · ${ders.kortAdi}',
            altBaslik: _gunMetni(ders.baslangic),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Bosluk.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _satir(context, 'Antrenör',
                    benim ? '${ders.antrenorAdi} (sen)' : ders.antrenorAdi),
                if (ders.urunAdi.isNotEmpty)
                  _satir(context, 'Ders', ders.urunAdi),
                _satir(context, 'Kişi', '${ders.katilimciSayisi}'),
                if (katilimcilar.isNotEmpty)
                  _satir(context, 'Katılımcılar', katilimcilar),
                if (ders.iptalMi)
                  _satir(context, 'Durum', 'İptal edildi', renk: cs.error),
                const SizedBox(height: Bosluk.m),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: Bosluk.s),
                    Expanded(
                      child: Text(
                        'Programdaki değişiklikler ofiste yapılır.',
                        style: TextStyle(
                            fontSize: 12.5, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _satir(BuildContext context, String etiket, String deger,
      {Color? renk}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Bosluk.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              etiket,
              style:
                  TextStyle(fontSize: 13, color: context.cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              deger,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: renk ?? context.cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Antrenörün kendi bekleyen talebi. Geri çekilirse true döner.
class ProgramTalepBilgiSheet extends StatefulWidget {
  final DersKayitTalebi talep;

  const ProgramTalepBilgiSheet({super.key, required this.talep});

  static Future<bool> ac(BuildContext context, DersKayitTalebi talep) async {
    final sonuc = await altSayfaGoster<bool>(
      context,
      cocuk: ProgramTalepBilgiSheet(talep: talep),
    );
    return sonuc ?? false;
  }

  @override
  State<ProgramTalepBilgiSheet> createState() => _ProgramTalepBilgiSheetState();
}

class _ProgramTalepBilgiSheetState extends State<ProgramTalepBilgiSheet> {
  bool _isleniyor = false;
  String? _hata;

  Future<void> _geriCek() async {
    setState(() {
      _isleniyor = true;
      _hata = null;
    });
    try {
      await DersKayitTalebiService.geriCek(widget.talep.id);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _hata = e.message);
    } catch (_) {
      if (mounted) setState(() => _hata = 'Talep geri çekilemedi.');
    } finally {
      if (mounted) setState(() => _isleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.talep;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: Bosluk.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AltSayfaBasligi(
            ikon: Icons.hourglass_top_rounded,
            renk: context.renkler.dersBekliyor,
            baslik: 'Talep · ${t.saat}-${t.bitisSaat} · ${t.kortAdi}',
            altBaslik: '${_gunMetni(t.baslangic)} · ofis onayı bekliyor',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Bosluk.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TalepNotuKutusu(talep: t),
                if (_hata != null) ...[
                  const SizedBox(height: Bosluk.s),
                  Text(_hata!,
                      style: TextStyle(color: context.cs.error, fontSize: 13)),
                ],
                const SizedBox(height: Bosluk.m),
                YikiciButon(
                  etiket: 'Talebi geri çek',
                  ikon: Icons.undo_rounded,
                  yukleniyor: _isleniyor,
                  onPressed: _isleniyor ? null : _geriCek,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
