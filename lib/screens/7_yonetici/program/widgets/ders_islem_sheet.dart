// lib/screens/7_yonetici/program/widgets/ders_islem_sheet.dart
//
// Izgarada bir derse dokunulduğunda açılan özet + işlem menüsü.
// İşlemi bu sheet yapmaz; seçilen eylemi çağırana döndürür.

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:flutter/material.dart';

import 'program_constants.dart';

enum DersIslemi { duzenle, iptalEt, iptalGeriAl, sil }

class DersIslemSheet extends StatelessWidget {
  final ProgramDersi ders;

  const DersIslemSheet({super.key, required this.ders});

  static Future<DersIslemi?> ac(BuildContext context, ProgramDersi ders) {
    return showModalBottomSheet<DersIslemi>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DersIslemSheet(ders: ders),
    );
  }

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final durumRenk = ProgramRenkleri.durumRengi(ders.durum);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${ders.saat} - ${ders.bitisSaat}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: renk.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: durumRenk.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ProgramRenkleri.durumMetni(ders.durum),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: durumRenk,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _satir(Icons.place_outlined, ders.kortAdi, renk),
                  _satir(Icons.person_outline,
                      ders.antrenorAdi.isEmpty ? '—' : ders.antrenorAdi, renk),
                  _satir(Icons.inventory_2_outlined,
                      ders.urunAdi.isEmpty ? '—' : ders.urunAdi, renk),
                  if (ders.sabitPlanMi)
                    _satir(Icons.repeat, 'Sabit plandan üretildi', renk),
                  if (ders.aciklama != null && ders.aciklama!.isNotEmpty)
                    _satir(Icons.notes, ders.aciklama!, renk),
                  const SizedBox(height: 10),
                  Text(
                    'Katılımcılar (${ders.katilimciSayisi})',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: renk.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (ders.katilimcilar.isEmpty)
                    Text('Katılımcı yok',
                        style: TextStyle(color: renk.onSurfaceVariant))
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: ders.katilimcilar
                          .map((k) => Chip(
                                label: Text(k.adSoyad,
                                    style: const TextStyle(fontSize: 11.5)),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (!ders.iptalMi) ...[
              _islem(context, Icons.edit_outlined, 'Dersi düzenle',
                  DersIslemi.duzenle),
              _islem(context, Icons.event_busy_outlined, 'Dersi iptal et',
                  DersIslemi.iptalEt,
                  renk: renk.error),
            ] else
              _islem(context, Icons.restore, 'İptali geri al',
                  DersIslemi.iptalGeriAl),
            _islem(context, Icons.delete_forever_outlined,
                'Kalıcı olarak sil', DersIslemi.sil,
                renk: renk.error),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _satir(IconData ikon, String metin, ColorScheme renk) {
    if (metin.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 15, color: renk.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              metin,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: renk.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _islem(
    BuildContext context,
    IconData ikon,
    String baslik,
    DersIslemi islem, {
    Color? renk,
  }) {
    return ListTile(
      leading: Icon(ikon, color: renk),
      title: Text(baslik, style: TextStyle(color: renk)),
      onTap: () => Navigator.pop(context, islem),
    );
  }
}
