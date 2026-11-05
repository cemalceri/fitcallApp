// lib/screens/2_uye/talep/taleplerim_page.dart
//
// Üyenin "Taleplerim" sayfası (yan menüde "Ders Talebi ve Kort Kiralama"):
// Açık talepler (önce cevabını bekleyen öneriler) ve Geçmiş talepler; yeni
// talep sağ alttaki düğmeden. Satıra dokununca detay açılır: Kabul et /
// Reddet, Geri çek, Düzenle, Benzerini aç. Bildirimden ('uye_taleplerim') da
// açılır.

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/2_uye/uye_talep_models.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_butonu.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/2_uye/talep/widgets/taleplerim_gorunumu.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/uye/uye_talep_service.dart';
import 'package:flutter/material.dart';

class TaleplerimPage extends StatefulWidget {
  const TaleplerimPage({super.key});

  @override
  State<TaleplerimPage> createState() => _TaleplerimPageState();
}

class _TaleplerimPageState extends State<TaleplerimPage> {
  List<UyeTalep>? _talepler;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _hata = null);
    try {
      final liste = await UyeTalepService.taleplerim();
      if (mounted) setState(() => _talepler = liste);
    } on ApiException catch (e) {
      if (mounted) setState(() => _hata = e.message);
    } catch (_) {
      if (mounted) setState(() => _hata = 'Talepler yüklenemedi.');
    }
  }

  Future<void> _sihirbaz([TalepTaslagi? taslak]) async {
    await Navigator.of(context)
        .pushNamed(routeEnums[SayfaAdi.uyeTalepOlustur]!, arguments: taslak);
    if (mounted) _yukle();
  }

  Future<void> _ac(UyeTalep talep) async {
    final sonuc = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TalepDetaySheet(talep: talep),
    );
    if (!mounted || sonuc == null) return;
    if (sonuc == 'duzenle') {
      await _sihirbaz(TalepTaslagi.talepten(talep, duzenle: true));
    } else if (sonuc == 'benzeri') {
      await _sihirbaz(TalepTaslagi.talepten(talep, duzenle: false));
    } else {
      _yukle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taleplerim'),
        actions: [
          OgrenmeButonu(
            sayfa: OgrenmeSayfasi.uyeTaleplerim,
            sssRotasi: routeEnums[SayfaAdi.yardim]!,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _sihirbaz(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni talep'),
      ),
      body: SafeArea(
        top: false,
        child: TaleplerimGorunumu(
          talepler: _talepler,
          hata: _hata,
          onYenile: _yukle,
          onYenidenDene: _yukle,
          onAc: _ac,
          onYeni: () => _sihirbaz(),
        ),
      ),
    );
  }
}

/// Detay alt sayfası; işlem yapılınca 'yenile', düzenle/benzeri için o
/// eylemin adıyla kapanır.
class _TalepDetaySheet extends StatefulWidget {
  final UyeTalep talep;

  const _TalepDetaySheet({required this.talep});

  @override
  State<_TalepDetaySheet> createState() => _TalepDetaySheetState();
}

class _TalepDetaySheetState extends State<_TalepDetaySheet> {
  bool _isleniyor = false;

  Future<void> _calistir(Future<String> Function() is_, {String? onay}) async {
    if (onay != null) {
      final evet = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(onay),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Vazgeç')),
            FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Evet')),
          ],
        ),
      );
      if (evet != true || !mounted) return;
    }
    setState(() => _isleniyor = true);
    try {
      final mesaj = await is_();
      if (!mounted) return;
      ShowMessage.success(context, mesaj);
      Navigator.pop(context, 'yenile');
    } on ApiException catch (e) {
      if (mounted) {
        ShowMessage.error(context, e.message);
        Navigator.pop(context, 'yenile');
      }
    } catch (_) {
      if (mounted) ShowMessage.error(context, 'İşlem yapılamadı.');
    } finally {
      if (mounted) setState(() => _isleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.talep;
    return TalepDetayGorunumu(
      talep: t,
      isleniyor: _isleniyor,
      onKabul: () =>
          _calistir(() => UyeTalepService.oneriyeCevap(t.id, kabul: true)),
      onReddet: () => _calistir(
        () => UyeTalepService.oneriyeCevap(t.id, kabul: false),
        onay: 'Öneriyi reddedersen talep kapanır. Emin misin?',
      ),
      onGeriCek: () => _calistir(
        () => UyeTalepService.geriCek(t.id),
        onay: 'Talebi geri çekmek istiyor musun?',
      ),
      onDuzenle: () => Navigator.pop(context, 'duzenle'),
      onBenzeri: () => Navigator.pop(context, 'benzeri'),
    );
  }
}
