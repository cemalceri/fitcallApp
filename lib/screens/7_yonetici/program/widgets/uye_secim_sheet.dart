// lib/screens/7_yonetici/program/widgets/uye_secim_sheet.dart
//
// Derse katılımcı seçimi: arama + çoklu seçim.
// Pasif üyeler (düzenlemede hâlâ derste kayıtlı olanlar) "Pasif" etiketiyle
// listede kalır; aksi halde kaydederken sessizce dersten düşerler.

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:flutter/material.dart';

class UyeSecimSheet extends StatefulWidget {
  final List<SecenekUye> uyeler;
  final List<int> seciliIdler;

  const UyeSecimSheet({
    super.key,
    required this.uyeler,
    required this.seciliIdler,
  });

  /// Seçim onaylanırsa yeni id listesi, iptal edilirse null döner.
  static Future<List<int>?> ac(
    BuildContext context, {
    required List<SecenekUye> uyeler,
    required List<int> seciliIdler,
  }) {
    return showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => UyeSecimSheet(uyeler: uyeler, seciliIdler: seciliIdler),
    );
  }

  @override
  State<UyeSecimSheet> createState() => _UyeSecimSheetState();
}

class _UyeSecimSheetState extends State<UyeSecimSheet> {
  late Set<int> _secili;
  String _sorgu = '';

  @override
  void initState() {
    super.initState();
    _secili = widget.seciliIdler.toSet();
  }

  List<SecenekUye> get _filtreli {
    final liste = widget.uyeler.where((u) => u.eslesiyorMu(_sorgu)).toList();
    // Seçililer üste gelsin ki uzun listede kaybolmasın
    liste.sort((a, b) {
      final aSecili = _secili.contains(a.id) ? 0 : 1;
      final bSecili = _secili.contains(b.id) ? 0 : 1;
      if (aSecili != bSecili) return aSecili - bSecili;
      return a.adSoyad.compareTo(b.adSoyad);
    });
    return liste;
  }

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final filtreli = _filtreli;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, kaydirmaKontrol) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: renk.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Katılımcılar',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: renk.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${_secili.length} seçili',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: renk.primary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Ad, üye no veya telefon ara',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (v) => setState(() => _sorgu = v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtreli.isEmpty
                  ? Center(
                      child: Text(
                        'Eşleşen üye yok',
                        style: TextStyle(color: renk.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      controller: kaydirmaKontrol,
                      itemCount: filtreli.length,
                      itemBuilder: (context, i) {
                        final u = filtreli[i];
                        final secili = _secili.contains(u.id);
                        return CheckboxListTile(
                          value: secili,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (_) => setState(() {
                            if (secili) {
                              _secili.remove(u.id);
                            } else {
                              _secili.add(u.id);
                            }
                          }),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  u.adSoyad,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (u.pasif)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: renk.errorContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Pasif',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: renk.onErrorContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: (u.uyeNo == null || u.uyeNo!.isEmpty) &&
                                  u.telefon.isEmpty
                              ? null
                              : Text(
                                  [
                                    if (u.uyeNo != null && u.uyeNo!.isNotEmpty)
                                      'No: ${u.uyeNo}',
                                    if (u.telefon.isNotEmpty) u.telefon,
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Vazgeç'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, _secili.toList()),
                        child: Text('Onayla (${_secili.length})'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
