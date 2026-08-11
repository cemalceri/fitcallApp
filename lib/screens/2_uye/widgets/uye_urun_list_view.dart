import 'package:fitcall/models/8_urun/uye_urun_model.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/common/routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Üyelik/Paket bilgilerinin gruplu, açılır-kapanır görünümü.
///
/// API çağrısı içermez; [urunler] dışarıdan verilir. Böylece taşma testinde
/// doğrudan pump edilebilir (bkz. CLAUDE.md "Layout / overflow discipline").
class UyeUrunListView extends StatefulWidget {
  final List<UyeUrunModel> urunler;

  const UyeUrunListView({super.key, required this.urunler});

  @override
  State<UyeUrunListView> createState() => _UyeUrunListViewState();
}

class _UyeUrunListViewState extends State<UyeUrunListView> {
  // Varsayılan: tüm gruplar kapalı (sayfa açıldığında liste kapalı gelir).
  final Set<String> _acikGruplar = <String>{};

  @override
  Widget build(BuildContext context) {
    if (widget.urunler.isEmpty) {
      return _buildBos(context);
    }

    final paketler = widget.urunler.where((u) => u.isPaket).toList();
    final aidatlar = widget.urunler.where((u) => u.isAidat).toList();
    final tekDersler = widget.urunler.where((u) => u.isTekDers).toList();
    final digerler = widget.urunler
        .where((u) => !u.isPaket && !u.isAidat && !u.isTekDers)
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        _buildGrup(
          context,
          key: 'PAKET',
          baslik: 'Paketler',
          icon: Icons.card_membership_rounded,
          renk: const Color(0xFF6366F1),
          items: paketler,
        ),
        _buildGrup(
          context,
          key: 'ABONELIK',
          baslik: 'Aidatlar',
          icon: Icons.event_repeat_rounded,
          renk: const Color(0xFF0EA5E9),
          items: aidatlar,
        ),
        _buildGrup(
          context,
          key: 'TEK_SEFERLIK',
          baslik: 'Tek Dersler',
          icon: Icons.sports_tennis_rounded,
          renk: const Color(0xFFF59E0B),
          items: tekDersler,
        ),
        if (digerler.isNotEmpty)
          _buildGrup(
            context,
            key: 'DIGER',
            baslik: 'Diğer',
            icon: Icons.inventory_2_outlined,
            renk: Theme.of(context).colorScheme.onSurfaceVariant,
            items: digerler,
          ),
      ],
    );
  }

  Widget _buildGrup(
    BuildContext context, {
    required String key,
    required String baslik,
    required IconData icon,
    required Color renk,
    required List<UyeUrunModel> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    final acik = _acikGruplar.contains(key);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: renk.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Grup başlığı (tıklanınca aç/kapa)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() {
                if (acik) {
                  _acikGruplar.remove(key);
                } else {
                  _acikGruplar.add(key);
                }
              }),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: renk.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, color: renk, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        baslik,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: renk.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${items.length}',
                        style: TextStyle(
                          color: renk,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: acik ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // İçerik
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  for (final u in items)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _UrunKart(urun: u, renk: renk),
                    ),
                ],
              ),
            ),
            crossFadeState:
                acik ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildBos(BuildContext context) {
    return BosDurum(
      ikon: Icons.inventory_2_outlined,
      baslik: 'Kayıtlı üyelik/paket yok',
      aciklama: 'Aldığın paketler ve üyelik dönemin burada listelenir. '
          'Paket almak için kulüple iletişime geçebilirsin.',
      eylemEtiketi: 'Yardım & iletişim',
      eylemIkonu: Icons.help_outline_rounded,
      onEylem: () => Navigator.pushNamed(context, routeEnums[SayfaAdi.yardim]!),
    );
  }
}

/// Tek bir üye-ürün kartı. Tipe göre farklı içerik gösterir.
class _UrunKart extends StatelessWidget {
  final UyeUrunModel urun;
  final Color renk;

  const _UrunKart({required this.urun, required this.renk});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  urun.urunAdi,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              // Tek derslerde Aktif/Pasif rozeti gösterme; kart zaten yapılan
              // ders bilgisini listeler.
              if (!urun.isTekDers) ...[
                const SizedBox(width: 8),
                _DurumRozet(aktif: urun.aktifMi),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (urun.isPaket)
            _paketDetay(context)
          else if (urun.isTekDers)
            _tekDersDetay(context)
          else
            _aidatDetay(context),
        ],
      ),
    );
  }

  Widget _paketDetay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final toplam = urun.toplamHak;
    final kalan = urun.kalanHak;
    final oran = (toplam != null && toplam > 0 && kalan != null)
        ? (kalan / toplam).clamp(0.0, 1.0).toDouble()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.confirmation_number_outlined, size: 16, color: renk),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                toplam != null
                    ? 'Kalan hak: ${_hakStr(kalan)} / $toplam'
                    : 'Kalan hak: ${_hakStr(kalan)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        if (oran != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: oran,
              minHeight: 6,
              backgroundColor:
                  colorScheme.outlineVariant.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(renk),
            ),
          ),
        ],
        const SizedBox(height: 8),
        _tarihSatiri(context),
      ],
    );
  }

  Widget _aidatDetay(BuildContext context) {
    return _tarihSatiri(context, etiket: 'Dönem');
  }

  Widget _tekDersDetay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final df = DateFormat('dd.MM.yyyy HH:mm');

    if (urun.dersler.isEmpty) {
      // Backend ders bilgisini henüz doldurmadıysa tarihe düş.
      return _tarihSatiri(context, etiket: 'Satın alma');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final d in urun.dersler)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sports_tennis_rounded, size: 15, color: renk),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [
                      if (d.tarih != null) df.format(d.tarih!),
                      if ((d.kortAdi ?? '').isNotEmpty) d.kortAdi,
                      if ((d.antrenorAdi ?? '').isNotEmpty) d.antrenorAdi,
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _tarihSatiri(BuildContext context, {String etiket = 'Başlangıç'}) {
    final colorScheme = Theme.of(context).colorScheme;
    final df = DateFormat('dd.MM.yyyy');
    final bas = df.format(urun.baslangic);
    final bit = urun.bitis != null ? df.format(urun.bitis!) : '—';

    return Row(
      children: [
        Icon(Icons.calendar_today_outlined,
            size: 15, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$etiket: $bas${urun.bitis != null ? ' → $bit' : ''}',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  String _hakStr(num? v) {
    if (v == null) return '—';
    if (v % 1 == 0) return v.toInt().toString();
    return v.toString();
  }
}

class _DurumRozet extends StatelessWidget {
  final bool aktif;
  const _DurumRozet({required this.aktif});

  @override
  Widget build(BuildContext context) {
    final renk =
        aktif ? const Color(0xFF10B981) : Theme.of(context).colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: renk, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            aktif ? 'Aktif' : 'Pasif',
            style: TextStyle(
              color: renk,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
