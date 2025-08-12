// lib/screens/2_uye/ders_talep_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/dtos/paket_secim_item.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_talep_api_service.dart';
import 'package:flutter/material.dart';

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

  Future<void> _yuklePaketler() async {
    setState(() => _loadingPaket = true);
    try {
      final res = await DersTalepApiService.getirtUrunListesiVeUyePaketleri(
        antrenorId: widget.secimJson['antrenor_id'],
      );

      final data = res.data; // PaketVeriResponse?
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Rezervasyon Talebi')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoCard(
                icon: Icons.sports_tennis,
                label: 'Kort',
                value: widget.secimJson['kort_adi'] ?? '',
              ),
              const SizedBox(height: 12),
              _infoCard(
                icon: Icons.person,
                label: 'Antrenör',
                value: widget.secimJson['antrenor_adi'] ?? '',
              ),
              const SizedBox(height: 12),
              _infoCard(
                icon: Icons.schedule,
                label: 'Saat',
                value:
                    '${widget.baslangic.hour.toString().padLeft(2, "0")}:00 – ${_bitis.hour.toString().padLeft(2, "0")}:00',
              ),
              const SizedBox(height: 16),

              // Paket seçimi
              _paketSecimCard(),

              if (_satinal) ...[
                const SizedBox(height: 8),
                Text(
                  '${_seciliPaket?.ucretCarpanli ?? 0} TL paket ücreti hesabınızdan düşülecektir.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 16),
              TextField(
                controller: _aciklamaCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (opsiyonel)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Text('Talep Gönder',
                          style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _sending ? null : _gonder,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _paketSecimCard() {
    final secimMetni = _seciliPaket == null
        ? 'Paket seçiniz'
        : _seciliPaket!.sahipMi
            ? '${_seciliPaket!.urunAdi} • Mevcut'
            : '${_seciliPaket!.urunAdi} • ${_seciliPaket!.ucretCarpanli} TL • Satın al';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _loadingPaket ? null : _paketSecimBottomSheet,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.shopping_bag_outlined,
                  size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paket Seçimi',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _loadingPaket
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            secimMetni,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _paketSecimBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text('Paket Seçimi',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _paketler.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = _paketler[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: p.sahipMi
                                    ? () {
                                        setState(() => _seciliPaket = p);
                                        Navigator.pop(context);
                                      }
                                    : null,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(p.urunAdi,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                            // Ortada ücret
                            SizedBox(
                              width: 100,
                              child: Center(
                                child: Text('${p.ucretCarpanli} TL',
                                    style: const TextStyle(fontSize: 15)),
                              ),
                            ),
                            // Sağda durum/aksiyon
                            p.sahipMi
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green
                                          .withAlpha((0.1 * 255).toInt()),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('Mevcut',
                                        style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w700)),
                                  )
                                : TextButton(
                                    onPressed: () {
                                      setState(() => _seciliPaket = p);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Satın al'),
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon,
                  size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

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
        uyeId: widget.secimJson['uye_id'], // endpoint için opsiyonel
      );

      if (!mounted) return;
      // Projenizde ApiResult'ta mesaj alanı 'message' ya da 'mesaj' olabilir:
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
}
