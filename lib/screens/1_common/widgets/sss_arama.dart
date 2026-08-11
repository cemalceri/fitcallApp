// lib/screens/1_common/widgets/sss_arama.dart

import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

/// Yardım sayfalarının arama kutusu (+ isteğe bağlı bölüm çipleri).
///
/// Antrenör SSS'inde 50, üye SSS'inde 14 soru var ve ikisinde de arama yoktu:
/// cevabı bulmanın tek yolu kaydırmaktı. Kutu `AppBar.bottom` içinde durur,
/// böylece liste kaysa da ekranda kalır.
class SssArama extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController denetleyici;
  final ValueChanged<String> onDegisti;

  /// Bölüm adları — boşsa çip satırı çizilmez.
  final List<String> bolumler;
  final String? seciliBolum;
  final ValueChanged<String?>? onBolum;

  /// Yazı ölçeği büyüdükçe kutu da büyür; sabit yükseklik taşma üretiyordu.
  final double yaziOlcegi;

  const SssArama({
    super.key,
    required this.denetleyici,
    required this.onDegisti,
    this.bolumler = const [],
    this.seciliBolum,
    this.onBolum,
    this.yaziOlcegi = 1.0,
  });

  bool get _cipVar => bolumler.isNotEmpty;

  @override
  Size get preferredSize =>
      Size.fromHeight((_cipVar ? 116 : 66) * yaziOlcegi.clamp(1.0, 1.3));

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l, Bosluk.s),
          child: TextField(
            controller: denetleyici,
            onChanged: onDegisti,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Soru ara…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: denetleyici.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Aramayı temizle',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        denetleyici.clear();
                        onDegisti('');
                      },
                    ),
            ),
          ),
        ),
        if (_cipVar)
          SizedBox(
            height: 42 * yaziOlcegi.clamp(1.0, 1.3),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Bosluk.l),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: Bosluk.s),
                  child: ChoiceChip(
                    label: const Text('Tümü'),
                    selected: seciliBolum == null,
                    onSelected: (_) => onBolum?.call(null),
                  ),
                ),
                for (final bolum in bolumler)
                  Padding(
                    padding: const EdgeInsets.only(right: Bosluk.s),
                    child: ChoiceChip(
                      label: Text(bolum),
                      selected: seciliBolum == bolum,
                      onSelected: (_) => onBolum?.call(bolum),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Arama sonucu boşken gösterilen bölüm.
class SssSonucYok extends StatelessWidget {
  final String sorgu;
  const SssSonucYok({super.key, required this.sorgu});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Bosluk.xxl),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 44, color: context.cs.outline),
          const SizedBox(height: Bosluk.m),
          Text(
            sorgu.isEmpty ? 'Sonuç yok' : '"$sorgu" için sonuç yok',
            textAlign: TextAlign.center,
            style: context.metin.titleSmall,
          ),
          const SizedBox(height: Bosluk.xs),
          Text(
            'Farklı bir kelime deneyin ya da aşağıdan kulüple iletişime geçin.',
            textAlign: TextAlign.center,
            style: context.metin.bodySmall,
          ),
        ],
      ),
    );
  }
}
