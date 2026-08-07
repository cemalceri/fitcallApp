// lib/screens/1_common/hakedis/hakedis_ders_listesi_page.dart
//
// Bir grubun (ay + rol + durum) dersleri — yönetici ve antrenörde ORTAK ekran.
//
// Hangi antrenörün verisi geleceğini [kaynak] belirler. Özet uçlarından ayrı
// bir uç kullanır; katılımcı sorgusu ancak bu ekrana girildiğinde çalışsın
// diye (bkz. api/yonetici/hakedis_metots.py).

import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:fitcall/screens/1_common/hakedis/hakedis_veri_kaynagi.dart';
import 'package:fitcall/screens/1_common/hakedis/widgets/hakedis_ders_karti.dart';
import 'package:fitcall/screens/1_common/hakedis/widgets/hakedis_stil.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:flutter/material.dart';

class HakedisDersListesiPage extends StatefulWidget {
  final HakedisVeriKaynagi kaynak;

  /// Başlığın altında duran satır (yöneticide antrenörün adı).
  final String altBaslik;

  final int yil;
  final int ay;
  final String ayEtiketi;
  final String rol;
  final String durum;

  const HakedisDersListesiPage({
    super.key,
    required this.kaynak,
    required this.altBaslik,
    required this.yil,
    required this.ay,
    required this.ayEtiketi,
    required this.rol,
    required this.durum,
  });

  @override
  State<HakedisDersListesiPage> createState() => _HakedisDersListesiPageState();
}

class _HakedisDersListesiPageState extends State<HakedisDersListesiPage> {
  HakedisDersListesi? _veri;
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final sonuc = await widget.kaynak.dersler(
        yil: widget.yil,
        ay: widget.ay,
        rol: widget.rol,
        durum: widget.durum,
      );
      if (!mounted) return;
      setState(() {
        _veri = sonuc.data;
        _yukleniyor = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.message;
        _yukleniyor = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hata = 'Dersler yüklenirken bir hata oluştu.';
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final veri = _veri;
    final vurgu = hakedisRengi(context, widget.durum);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.ayEtiketi} · ${HakedisRolu.etiket(widget.rol).toLowerCase()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.altBaslik,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: renk.onSurfaceVariant),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: renk.outlineVariant),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Grup başlığı — hangi kırılıma bakıldığı ekranda kalsın
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: vurgu.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(hakedisIkonu(widget.durum), size: 17, color: vurgu),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      HakedisDurumu.etiket(widget.durum),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: vurgu,
                      ),
                    ),
                  ),
                  if (veri != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${veri.dersSayisi} ders · ${saatMetni(veri.dakika)}',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: vurgu,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: HakedisDurumGovdesi(
                yukleniyor: _yukleniyor,
                hata: _hata,
                bosMu: veri == null || veri.dersler.isEmpty,
                bosMesaj: 'Bu grupta ders yok',
                bosIkon: Icons.event_note_rounded,
                onTekrarDene: _yukle,
                icerik: (_) => RefreshIndicator(
                  onRefresh: _yukle,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: veri!.dersler.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) =>
                        HakedisDersKarti(ders: veri.dersler[i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
