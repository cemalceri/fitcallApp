// lib/screens/muhasebe/widgets/para_hareket_dialog.dart
import 'package:flutter/material.dart';
import 'package:fitcall/models/6_muhasebe/para_hareket_model.dart';
import 'package:fitcall/screens/muhasebe/widgets/para_hareket_table.dart';
import 'package:fitcall/services/muhasebe/para_hareket_service.dart';

Future<void> showParaHareketDialog(
  BuildContext context,
  int yil,
  int ay,
) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DialogBody(yil: yil, ay: ay),
  );
}

class _DialogBody extends StatefulWidget {
  final int yil;
  final int ay;
  const _DialogBody({required this.yil, required this.ay});

  @override
  State<_DialogBody> createState() => _DialogBodyState();
}

class _DialogBodyState extends State<_DialogBody> {
  late Future<List<ParaHareketModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ParaHareketService.fetchForPeriod(widget.yil, widget.ay);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // -- Başlık ----------------------------------------------------
              Row(
                children: [
                  Text(
                    '${widget.ay.toString().padLeft(2, "0")}/${widget.yil} Para Hareketleri',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    splashRadius: 20,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const Divider(height: 2),
              // -- İçerik ----------------------------------------------------
              FutureBuilder<List<ParaHareketModel>>(
                future: _future,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError || (snap.data?.isEmpty ?? true)) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          snap.hasError ? 'Veri alınamadı' : 'Kayıt bulunamadı',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    );
                  }

                  return Flexible(
                    child: SingleChildScrollView(
                      child: ParaHareketTable(rows: snap.data!),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
