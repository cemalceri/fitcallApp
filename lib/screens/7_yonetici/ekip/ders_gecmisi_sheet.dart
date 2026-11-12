// lib/screens/7_yonetici/ekip/ders_gecmisi_sheet.dart
//
// Yönetici Dersler listesinde bir derse dokununca açılır: dersi kim kaydetti,
// kim onayladı, kim değiştirdi ya da iptal etti. Yalnız okuma.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/models/9_yonetici/ekip_models.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/7_yonetici/ekip/widgets/ekip_gorunumu.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:flutter/material.dart';

Future<void> dersGecmisiGoster(BuildContext context, DersListeItem ders) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DersGecmisiSheet(ders: ders),
  );
}

class DersGecmisiSheet extends StatefulWidget {
  final DersListeItem ders;
  const DersGecmisiSheet({super.key, required this.ders});

  @override
  State<DersGecmisiSheet> createState() => _DersGecmisiSheetState();
}

class _DersGecmisiSheetState extends State<DersGecmisiSheet> {
  late Future<List<IslemGecmisiSatiri>> _gecmis = _getir();

  Future<List<IslemGecmisiSatiri>> _getir() async =>
      (await YoneticiApiService.getDersGecmisi(widget.ders.id)).data ??
      const [];

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final ders = widget.ders;
    final ust = [
      '${ders.tarih} ${ders.saat}'.trim(),
      if ((ders.kortAdi ?? '').isNotEmpty) ders.kortAdi!,
    ].join(' · ');

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l, Bosluk.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'İşlem geçmişi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [ust, if ((ders.antrenorAdi ?? '').isNotEmpty) ders.antrenorAdi!]
                    .join(' · '),
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: Bosluk.m),
              FutureBuilder<List<IslemGecmisiSatiri>>(
                future: _gecmis,
                builder: (context, anlik) {
                  if (anlik.connectionState != ConnectionState.done) {
                    return const IskeletListe(
                        satirSayisi: 3, kaydirilabilir: false);
                  }
                  if (anlik.hasError) {
                    final hata = anlik.error;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hata is ApiException
                              ? hata.message
                              : 'İşlem geçmişi alınamadı.',
                          style: TextStyle(fontSize: 13, color: cs.error),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => _gecmis = _getir()),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tekrar dene'),
                        ),
                      ],
                    );
                  }
                  return IslemGecmisiListesi(satirlar: anlik.data ?? const []);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
