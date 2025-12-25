// lib/screens/2_uye/ders_talep_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/dtos/paket_secim_item.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_talep_api_service.dart';
import 'package:flutter/material.dart';

const Color uiPrimaryBlue = Color(0xFF2563EB);
const Color uiPrimaryLight = Color(0xFFDBEAFE);
const Color uiAccentGreen = Color(0xFF10B981);
const Color uiAccentOrange = Color(0xFFF59E0B);

class DersTalepPage extends StatefulWidget {
  /// secimJson beklenen örnek: {
  ///  'kort_id': 1, 'kort_adi': 'Kort 1',
  ///  'antrenor_id': 10, 'antrenor_adi': 'Ahmet Hoca',
  ///  'uye_id': 99 (opsiyonel)
  /// }
  final Map secimJson;
  final DateTime baslangic;

  const DersTalepPage({
    super.key,
    required this.secimJson,
    required this.baslangic,
  });

  @override
  State<DersTalepPage> createState() => _DersTalepPageState();
}

class _DersTalepPageState extends State<DersTalepPage> {
  final TextEditingController _aciklamaCtrl = TextEditingController();
  bool _sending = false;
  bool _loadingPaket = false;

  List<PaketSecimItem> _paketler = [];
  PaketSecimItem? _seciliPaket;

  bool get _satinal => _seciliPaket != null && !_seciliPaket!.sahipMi;
  DateTime get _bitis => widget.baslangic.add(const Duration(hours: 1));

  @override
  void initState() {
    super.initState();
    _yuklePaketler();
  }

  @override
  void dispose() {
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  Future<void> _yuklePaketler() async {
    setState(() => _loadingPaket = true);
    try {
      final res = await DersTalepApiService.getirtUrunListesiVeUyePaketleri(
        antrenorId: widget.secimJson['antrenor_id'],
      );

      final data = res.data; // PaketVeriResponse
      if (data == null) {
        ShowMessage.error(context, res.mesaj);
        return;
      }

      setState(() {
        _paketler = data.secenekler;
      });
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } catch (e) {
      ShowMessage.error(context, 'Paketler alınamadı: $e');
    } finally {
      if (mounted) setState(() => _loadingPaket = false);
    }
  }

  Future<void> _gonder() async {
    if (_seciliPaket == null) {
      ShowMessage.warning(context, "Lütfen bir paket seçin.");
      return;
    }
    setState(() => _sending = true);

    try {
      final res = await DersTalepApiService.gonderDersTalep(
        kortId: widget.secimJson['kort_id'],
        antrenorId: widget.secimJson['antrenor_id'],
        baslangic: widget.baslangic,
        bitis: _bitis,
        aciklama: _aciklamaCtrl.text,
        urunId: _seciliPaket?.urunId,
        satinal: _satinal,
        uyeId: widget.secimJson['uye_id'],
      );

      if (!mounted) return;
      final msg = res.mesaj;
      ShowMessage.success(context, msg);
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, e.message);
      setState(() => _sending = false);
    } catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, 'Hata: $e');
      setState(() => _sending = false);
    }
  }

  String _formatSaat(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Ders Talebim',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seçim Özeti Kartı
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        uiPrimaryBlue.withValues(alpha: 0.08),
                        uiPrimaryBlue.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: uiPrimaryBlue.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: uiPrimaryBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.event_note_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Talep Özeti',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DetailRow(
                        icon: Icons.sports_tennis_rounded,
                        label: 'Kort',
                        value: widget.secimJson['kort_adi'] ?? 'Bilinmiyor',
                        accentColor: uiAccentGreen,
                      ),
                      const SizedBox(height: 14),
                      _DetailRow(
                        icon: Icons.person_rounded,
                        label: 'Antrenör',
                        value: widget.secimJson['antrenor_adi'] ?? 'Bilinmiyor',
                        accentColor: uiAccentOrange,
                      ),
                      const SizedBox(height: 14),
                      _DetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'Saat',
                        value:
                            '${_formatSaat(widget.baslangic)} - ${_formatSaat(_bitis)}',
                        accentColor: uiPrimaryBlue,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Paket Seçimi
                Text(
                  'Paket Seçimi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                _loadingPaket
                    ? Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      )
                    : _paketler.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.amber.shade200,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_rounded,
                                  color: Colors.amber.shade700,
                                  size: 32,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Paket Bulunamadı',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _paketler.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final paket = _paketler[i];
                              final isSelected =
                                  _seciliPaket?.urunId == paket.urunId;

                              return _PaketCard(
                                paket: paket,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() => _seciliPaket = paket);
                                },
                              );
                            },
                          ),

                const SizedBox(height: 28),

                // Ücret Uyarısı
                if (_satinal)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paket Satın Alınacak',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_seciliPaket?.ucretCarpanli ?? 0} TL hesabınızdan düşülecektir.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_satinal) const SizedBox(height: 24),

                // Açıklama
                Text(
                  'Ek Açıklama',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _aciklamaCtrl,
                  maxLines: 4,
                  maxLength: 200,
                  decoration: InputDecoration(
                    hintText: 'İsteğiniz veya notunuz varsa yazınız...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                        : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: uiPrimaryBlue,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  textInputAction: TextInputAction.newline,
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
          // Sabit Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _sending ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'İptal',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed:
                          _sending || _seciliPaket == null ? null : _gonder,
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _sending ? 'Gönderiliyor...' : 'Talep Gönder',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: uiPrimaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          Detay Satırı Widget                                */
/* -------------------------------------------------------------------------- */
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          Paket Kartı                                        */
/* -------------------------------------------------------------------------- */
class _PaketCard extends StatelessWidget {
  const _PaketCard({
    required this.paket,
    required this.isSelected,
    required this.onTap,
  });

  final PaketSecimItem paket;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? uiPrimaryBlue.withValues(alpha: 0.08)
                : (isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? uiPrimaryBlue.withValues(alpha: 0.3)
                  : (isDark
                      ? theme.colorScheme.outline.withValues(alpha: 0.2)
                      : Colors.grey.shade200),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: uiPrimaryBlue.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Checkbox Animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? uiPrimaryBlue : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? uiPrimaryBlue : Colors.grey.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              // Paket Bilgisi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paket.urunAdi,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? uiPrimaryBlue
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (paket.sahipMi)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: uiAccentGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 12,
                              color: uiAccentGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Mevcut',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: uiAccentGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.amber.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_bag_rounded,
                              size: 12,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Satın Al',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Fiyat
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${paket.ucretCarpanli} TL',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? uiPrimaryBlue : uiPrimaryBlue,
                    ),
                  ),
                  if (!paket.sahipMi)
                    Text(
                      'Tek Ders',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
