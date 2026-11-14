// lib/screens/3_antrenor/talep_sorulari/antrenor_talep_sorulari_page.dart
//
// Antrenörün "Ofis soruyor" sayfası: üye talebi için ofis "bu derse girebilir
// misin?" diye sorar, hoca Evet / Hayır der (isterse not yazar). Süresinde
// cevap gelmezse talep ofise döner. Bildirimden ('antrenor_talep_sorulari')
// ve menüden açılır.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/10_ofis/ofis_uye_talep_models.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/yikici_buton.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/uye/uye_talep_service.dart';
import 'package:material_ui/material_ui.dart';

class AntrenorTalepSorulariPage extends StatefulWidget {
  const AntrenorTalepSorulariPage({super.key});

  @override
  State<AntrenorTalepSorulariPage> createState() =>
      _AntrenorTalepSorulariPageState();
}

class _AntrenorTalepSorulariPageState extends State<AntrenorTalepSorulariPage> {
  List<HocaTalepSorusu>? _sorular;
  String? _hata;
  int? _islenen;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _hata = null);
    try {
      final liste = await UyeTalepService.hocaSorulari();
      if (mounted) setState(() => _sorular = liste);
    } on ApiException catch (e) {
      if (mounted) setState(() => _hata = e.message);
    } catch (_) {
      if (mounted) setState(() => _hata = 'Sorular yüklenemedi.');
    }
  }

  Future<void> _cevapla(HocaTalepSorusu s, bool evet) async {
    final not = await showDialog<String>(
      context: context,
      builder: (_) => _NotDialog(evet: evet),
    );
    if (not == null || !mounted) return;
    setState(() => _islenen = s.id);
    try {
      final mesaj =
          await UyeTalepService.hocaCevapla(s.id, evet: evet, not: not);
      if (mounted) ShowMessage.success(context, mesaj);
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } catch (_) {
      if (mounted) ShowMessage.error(context, 'Cevap gönderilemedi.');
    } finally {
      if (mounted) setState(() => _islenen = null);
    }
    _yukle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ofis soruyor')),
      body: SafeArea(
        top: false,
        child: HocaSorulariGorunumu(
          sorular: _sorular,
          hata: _hata,
          islenenId: _islenen,
          onYenile: _yukle,
          onEvet: (s) => _cevapla(s, true),
          onHayir: (s) => _cevapla(s, false),
        ),
      ),
    );
  }
}

/// Görsel gövde — API çağırmaz, testte render edilir.
class HocaSorulariGorunumu extends StatelessWidget {
  final List<HocaTalepSorusu>? sorular;
  final String? hata;
  final int? islenenId;
  final Future<void> Function() onYenile;
  final ValueChanged<HocaTalepSorusu> onEvet;
  final ValueChanged<HocaTalepSorusu> onHayir;

  const HocaSorulariGorunumu({
    super.key,
    required this.sorular,
    required this.onYenile,
    required this.onEvet,
    required this.onHayir,
    this.hata,
    this.islenenId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final liste = sorular;
    if (liste == null) {
      if (hata != null) {
        return BosDurum(
          ikon: Icons.error_outline_rounded,
          baslik: 'Yüklenemedi',
          aciklama: hata!,
          eylemEtiketi: 'Tekrar dene',
          eylemIkonu: Icons.refresh_rounded,
          onEylem: onYenile,
        );
      }
      return const IskeletListe();
    }
    return RefreshIndicator(
      onRefresh: onYenile,
      child: liste.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 48),
                BosDurum(
                  ikon: Icons.mark_chat_read_outlined,
                  baslik: 'Soru yok',
                  aciklama:
                      'Ofis bir üye talebi için sana sorduğunda burada görünür.',
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: liste.length,
              separatorBuilder: (_, __) => const ListeAyraci(),
              itemBuilder: (context, i) {
                final s = liste[i];
                final kilitli = islenenId != null;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Bosluk.l, Bosluk.m, Bosluk.l, Bosluk.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.dersTanimi, style: context.metin.titleSmall),
                      Text('${s.uyeAdi} · ${s.turAdi}',
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant)),
                      if (!s.dersTanimi.contains(s.kortAdi))
                        Text(s.kortAdi,
                            style: TextStyle(
                                fontSize: 13, color: cs.onSurfaceVariant)),
                      if (s.esnemeMetni.isNotEmpty)
                        Text(s.esnemeMetni,
                            style: TextStyle(
                                fontSize: 13, color: cs.onSurfaceVariant)),
                      if (s.aciklama.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: Bosluk.xs),
                          child: Text('“${s.aciklama}”',
                              style: const TextStyle(fontSize: 13)),
                        ),
                      const SizedBox(height: Bosluk.s),
                      if (s.bekliyor) ...[
                        if (s.sonCevapMetni.isNotEmpty)
                          Text('Son cevap: ${s.sonCevapMetni}',
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant)),
                        Text(
                            'Evet dersen ofis dersi kaydeder ya da üyeye bu saati önerir. '
                            'Hayır dersen ofis başka bir hocaya bakar.',
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                        const SizedBox(height: Bosluk.xs),
                        Row(
                          children: [
                            Expanded(
                                child: YikiciButon(
                                    etiket: 'Hayır',
                                    onPressed:
                                        kilitli ? null : () => onHayir(s))),
                            const SizedBox(width: Bosluk.m),
                            Expanded(
                              child: FilledButton(
                                onPressed: kilitli ? null : () => onEvet(s),
                                child: const Text('Evet, girerim'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'Cevabın: ${s.cevap == 'EVET' ? 'Evet' : 'Hayır'}${s.hocaNotu.isNotEmpty ? ' · “${s.hocaNotu}”' : ''}',
                          style: TextStyle(
                              fontSize: 13,
                              color: s.cevap == 'EVET'
                                  ? context.renkler.basari
                                  : context.renkler.hata),
                        ),
                        if (s.sonuc.isNotEmpty)
                          Text(s.sonuc,
                              style: TextStyle(
                                  fontSize: 13, color: cs.onSurfaceVariant)),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _NotDialog extends StatefulWidget {
  final bool evet;

  const _NotDialog({required this.evet});

  @override
  State<_NotDialog> createState() => _NotDialogState();
}

class _NotDialogState extends State<_NotDialog> {
  final _not = TextEditingController();

  @override
  void dispose() {
    _not.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.evet ? 'Evet, girerim' : 'Hayır, giremem'),
      content: TextField(
        controller: _not,
        minLines: 1,
        maxLines: 3,
        maxLength: 500,
        decoration:
            const InputDecoration(labelText: 'Ofise not (isteğe bağlı)'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _not.text.trim()),
            child: const Text('Gönder')),
      ],
    );
  }
}
