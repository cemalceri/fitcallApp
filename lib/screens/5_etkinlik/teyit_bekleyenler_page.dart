// lib/screens/5_etkinlik/teyit_bekleyenler_page.dart
//
// Üyenin katılım bildirimi bekleyen (cevaplanmamış) gelecek derslerini listeler.
// Ana sayfadaki "Katılım geri bildirimi bekleniyor" kartı buraya gelir; her satıra
// dokununca mevcut Ders Teyidi ekranı (DersTeyitPage) uye_id + etkinlik_id ile açılır.

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_teyit_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TeyitBekleyenlerPage extends StatefulWidget {
  const TeyitBekleyenlerPage({super.key});

  @override
  State<TeyitBekleyenlerPage> createState() => _TeyitBekleyenlerPageState();
}

class _TeyitBekleyenlerPageState extends State<TeyitBekleyenlerPage> {
  late Future<List<TeyitBekleyenDers>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<TeyitBekleyenDers>> _fetch() async {
    try {
      final res = await DersTeyitService.getTeyitBekleyenler();
      return res.data ?? [];
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
      return [];
    }
  }

  Future<void> _refresh() async {
    final f = _fetch();
    setState(() => _future = f);
    await f;
  }

  void _acDersTeyit(TeyitBekleyenDers d) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      routeEnums[SayfaAdi.dersTeyit]!,
      arguments: {'uye_id': d.uyeId, 'etkinlik_id': d.etkinlikId},
    ).then((_) => _refresh()); // teyit verilince liste tazelensin
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Teyit Bekleyen Dersler',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<TeyitBekleyenDers>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snap.data ?? const <TeyitBekleyenDers>[];
            return TeyitBekleyenListesi(dersler: list, onTap: _acDersTeyit);
          },
        ),
      ),
    );
  }
}

/// Teyit bekleyen dersleri kartlarla listeler. API çağrısı içermez; veri
/// dışarıdan verilir (bkz. CLAUDE.md "Layout / overflow discipline").
class TeyitBekleyenListesi extends StatelessWidget {
  final List<TeyitBekleyenDers> dersler;
  final void Function(TeyitBekleyenDers) onTap;

  const TeyitBekleyenListesi({
    super.key,
    required this.dersler,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (dersler.isEmpty) return _buildBos(context);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: dersler.length,
      itemBuilder: (context, i) =>
          _TeyitKart(ders: dersler[i], onTap: () => onTap(dersler[i])),
    );
  }

  Widget _buildBos(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 90),
        Icon(Icons.event_available_rounded,
            size: 64, color: colorScheme.outlineVariant),
        const SizedBox(height: 16),
        Text(
          'Bekleyen katılım bildirimi yok',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Yaklaşan derslerin için durumun güncel',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _TeyitKart extends StatelessWidget {
  final TeyitBekleyenDers ders;
  final VoidCallback onTap;

  const _TeyitKart({required this.ders, required this.onTap});

  static const Color _renk = Color(0xFFF59E0B); // teyit bekleyen: amber

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final saatFmt = DateFormat('HH:mm');
    final gunFmt = DateFormat('EEE', 'tr');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _renk.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarih rozeti
                Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _renk.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${ders.baslangic.day}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _renk,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          gunFmt.format(ders.baslangic),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _renk.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // İçerik
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${saatFmt.format(ders.baslangic)}'
                              ' - ${saatFmt.format(ders.bitis)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (ders.kortAdi.isNotEmpty) ders.kortAdi,
                          if (ders.antrenorAdi.isNotEmpty) ders.antrenorAdi,
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Aksiyon ipucu
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _renk.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.how_to_reg_rounded,
                                size: 15, color: _renk),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Katılım durumunu bildir',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _renk,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
