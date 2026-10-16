// lib/screens/8_ofis/ders_kayit_talepleri/talep_islemleri.dart
//
// Ofisin bir ders kayıt talebi üzerindeki iki işlemi. Talep listesi ve
// haftalık programdaki kesik çizgili blok aynı yolu kullanır.
//
// Kayıt: haftalık programın ders formu (EtkinlikFormSheet) talepten dolu açılır
// ve kayıt YoneticiEtkinlikService.kaydet'e `talepId` ile gider. Backend dersi
// ortak etkinlik_kaydet servisiyle yazar (kurallar haftalık programla aynı) ve
// talebi aynı işlemde kapatır; talep edene bildirim gider.

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/1_common/program/talep_notu_kutusu.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/yikici_buton.dart';
import 'package:fitcall/screens/8_ofis/program/widgets/etkinlik_form_sheet.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_kayit_talebi_service.dart';
import 'package:fitcall/services/yonetici/yonetici_etkinlik_service.dart';
import 'package:flutter/material.dart';

class DersKayitTalebiIslemleri {
  DersKayitTalebiIslemleri._();

  /// Formu açar, kaydeder. Kayıt oluştuysa true.
  static Future<bool> kayitOlustur(
      BuildContext context, DersKayitTalebi talep) async {
    EtkinlikFormVerileri? veriler;
    try {
      veriler = (await YoneticiEtkinlikService.formVerileri()).data;
    } on ApiException catch (e) {
      if (context.mounted) ShowMessage.error(context, e.message);
      return false;
    } catch (_) {
      if (context.mounted) {
        ShowMessage.error(context, 'Form verileri alınamadı.');
      }
      return false;
    }
    if (veriler == null || !context.mounted) return false;

    final istek = await EtkinlikFormSheet.talepIcinAc(
      context,
      veriler: veriler,
      talep: talep,
    );
    if (istek == null || !context.mounted) return false;

    try {
      final sonuc = await YoneticiEtkinlikService.kaydet(istek);
      if (context.mounted) ShowMessage.success(context, sonuc.mesaj);
      return true;
    } on ApiException catch (e) {
      if (context.mounted) ShowMessage.error(context, e.message);
    } catch (_) {
      if (context.mounted) ShowMessage.error(context, 'Ders kaydedilemedi.');
    }
    return false;
  }

  /// Gerekçe ister, reddeder. Reddedildiyse true.
  static Future<bool> reddet(
      BuildContext context, DersKayitTalebi talep) async {
    final reddedildi = await showDialog<bool>(
      context: context,
      builder: (_) => TalepReddetDialog(talep: talep),
    );
    return reddedildi ?? false;
  }
}

/// Red penceresi: gerekçe zorunlu, talep edene bildirimle gider.
class TalepReddetDialog extends StatefulWidget {
  final DersKayitTalebi talep;

  const TalepReddetDialog({super.key, required this.talep});

  @override
  State<TalepReddetDialog> createState() => _TalepReddetDialogState();
}

class _TalepReddetDialogState extends State<TalepReddetDialog> {
  final _neden = TextEditingController();
  bool _isleniyor = false;
  String? _hata;

  @override
  void dispose() {
    _neden.dispose();
    super.dispose();
  }

  Future<void> _reddet() async {
    final neden = _neden.text.trim();
    if (neden.isEmpty) {
      setState(() => _hata = 'Red nedeni yazmak zorunludur.');
      return;
    }
    setState(() {
      _isleniyor = true;
      _hata = null;
    });
    try {
      final mesaj = await DersKayitTalebiService.reddet(widget.talep.id, neden);
      if (!mounted) return;
      ShowMessage.success(context, mesaj);
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _hata = e.message);
    } catch (_) {
      if (mounted) setState(() => _hata = 'Talep reddedilemedi.');
    } finally {
      if (mounted) setState(() => _isleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.talep;
    return AlertDialog(
      title: const Text('Talebi reddet'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${t.talepEdenAdi} · ${t.saat}-${t.bitisSaat} · ${t.kortAdi}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _neden,
              autofocus: true,
              enabled: !_isleniyor,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Red nedeni',
                hintText: 'Talep edene bildirimle gider',
                errorText: _hata,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isleniyor ? null : () => Navigator.pop(context, false),
          child: const Text('Vazgeç'),
        ),
        YikiciButon(
          etiket: 'Reddet',
          yukleniyor: _isleniyor,
          onPressed: _isleniyor ? null : _reddet,
        ),
      ],
    );
  }
}

/// Ofis programındaki kesik çizgili bloğa dokununca açılan kısa sayfa.
/// Seçilen işlem döner; null ise vazgeçildi.
enum TalepEylemi { kayitOlustur, reddet }

class TalepEylemSheet extends StatelessWidget {
  final DersKayitTalebi talep;

  const TalepEylemSheet({super.key, required this.talep});

  static Future<TalepEylemi?> ac(BuildContext context, DersKayitTalebi talep) {
    return showModalBottomSheet<TalepEylemi>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TalepEylemSheet(talep: talep),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ders kayıt talebi · ${talep.saat}-${talep.bitisSaat} · ${talep.kortAdi}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TalepNotuKutusu(talep: talep),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: YikiciButon(
                  etiket: 'Reddet',
                  onPressed: () => Navigator.pop(context, TalepEylemi.reddet),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, TalepEylemi.kayitOlustur),
                  child: const Text('Kayıt oluştur'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
