// lib/screens/8_ofis/ders_kayit_talepleri/widgets/uye_talep_detay_gorunumu.dart
//
// Ofisin üye talebi detayı — API çağırmaz, testte render edilir. Düğmeler
// sunucunun `eylemler` bayraklarına göre görünür: Hocaya sor, Telefonla onay
// aldım, Kayıt oluştur (hoca onayı varsa), Değişiklik öner, Reddet, Öneriyi
// geri çek.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/10_ofis/ofis_uye_talep_models.dart';
import 'package:fitcall/screens/1_common/widgets/buton_yukleniyor.dart';
import 'package:fitcall/screens/1_common/widgets/yikici_buton.dart';
import 'package:fitcall/screens/8_ofis/ders_kayit_talepleri/widgets/ofis_talepler_gorunumu.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:material_ui/material_ui.dart';

class OfisUyeTalepDetayGorunumu extends StatelessWidget {
  final OfisTalepDetay detay;
  final bool isleniyor;
  final VoidCallback onHocayaSor;
  final VoidCallback onTelefonOnay;
  final VoidCallback onKaydet;
  final VoidCallback onOneri;
  final VoidCallback onReddet;
  final VoidCallback onOneriGeriCek;

  const OfisUyeTalepDetayGorunumu({
    super.key,
    required this.detay,
    required this.isleniyor,
    required this.onHocayaSor,
    required this.onTelefonOnay,
    required this.onKaydet,
    required this.onOneri,
    required this.onReddet,
    required this.onOneriGeriCek,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final t = detay.talep;
    final e = t.eylemler;
    Widget satir(String etiket, String deger, {Color? renk}) => Padding(
          padding: const EdgeInsets.only(bottom: Bosluk.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                child: Text(etiket,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ),
              Expanded(
                  child: Text(deger,
                      style: TextStyle(
                          fontSize: 14, color: renk ?? cs.onSurface))),
            ],
          ),
        );

    final ciplar = <Widget>[
      if (t.etiketMetni.isNotEmpty)
        TalepCipi(t.etiketMetni, ton: ListeTonu.bilgi),
      if (t.kapanisMetni.isNotEmpty) TalepCipi(t.kapanisMetni),
      if (t.acil)
        const TalepCipi('Acil', ton: ListeTonu.hata, ikon: Icons.bolt_rounded),
      if (t.ayniSaate > 1)
        TalepCipi('Aynı saate ${t.ayniSaate} talep', ton: ListeTonu.uyari),
      if (t.inceleyenAdi.isNotEmpty)
        TalepCipi('${t.inceleyenAdi} bakıyor',
            ton: ListeTonu.vurgu, ikon: Icons.visibility_outlined),
    ];

    return ListView(
      padding:
          const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.l, Bosluk.l, Bosluk.xl),
      children: [
        Text('${t.uyeAdi} · ${t.turAdi}', style: context.metin.titleMedium),
        if (ciplar.isNotEmpty) ...[
          const SizedBox(height: Bosluk.xs),
          Wrap(spacing: Bosluk.xs, runSpacing: Bosluk.xs, children: ciplar),
        ],
        const SizedBox(height: Bosluk.m),
        satir('Gün / saat', '${t.dersTanimi} · ${t.sureDk} dk'),
        satir('Hoca', t.antrenorAdi),
        satir('Kort', t.kortAdi),
        if (t.esneme)
          satir('Esneme',
              '±${t.esnemeSaat} saat kaydırabilirsin (üyeye sormadan)'),
        satir('Hak', t.hakDurumu,
            renk: t.hakUygun ? context.renkler.basari : context.renkler.hata),
        if (t.aciklama.isNotEmpty) satir('Üyenin notu', t.aciklama),
        if (t.hocaOnayMetni.isNotEmpty)
          satir('Hoca onayı',
              '${t.hocaOnayAntrenorAdi}: ${t.hocaOnayMetni}${t.hocaNotu.isNotEmpty ? ' · “${t.hocaNotu}”' : ''}'),
        if (t.oneri != null)
          satir('Öneri',
              '${t.oneri!.dersTanimi}${t.oneri!.sonCevapMetni.isNotEmpty ? ' · son cevap ${t.oneri!.sonCevapMetni}' : ''}'),
        if (t.oneri != null && t.oneri!.notu.isNotEmpty)
          satir('Notun', t.oneri!.notu),
        if (t.redNedeni.isNotEmpty) satir('Neden', t.redNedeni),
        if (t.olusanDersTanimi.isNotEmpty)
          satir('Kaydedilen', t.olusanDersTanimi, renk: context.renkler.basari),
        if (t.hocaOnayli &&
            t.antrenorId != null &&
            t.hocaOnayAntrenorId != t.antrenorId &&
            t.sekme == 'bende')
          satir('Not',
              'Onay ${t.hocaOnayAntrenorAdi} için alındı; bu hocayla dersi "Değişiklik öner" ile üyeye sor.'),
        if (t.islemYapanAdi.isNotEmpty && t.sekme == 'kapanan')
          satir('İşlem yapan', t.islemYapanAdi),
        if (t.cakisma.isNotEmpty) ...[
          const SizedBox(height: Bosluk.s),
          _Uyari(t.cakisma),
        ],
        if (!t.hocaOnayli && t.hocali && e.kaydet == false && e.oneri) ...[
          const SizedBox(height: Bosluk.s),
          Text('Kayıt için önce hocanın onayını al.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ],
        const SizedBox(height: Bosluk.l),
        if (e.hocayaSor || e.telefonOnay)
          Row(
            children: [
              if (e.hocayaSor)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isleniyor ? null : onHocayaSor,
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: const Text('Hocaya sor',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              if (e.hocayaSor && e.telefonOnay) const SizedBox(width: Bosluk.s),
              if (e.telefonOnay)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isleniyor ? null : onTelefonOnay,
                    icon: const Icon(Icons.phone_in_talk_outlined, size: 18),
                    label: const Text('Telefonla onay aldım',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
            ],
          ),
        if (e.kaydet) ...[
          const SizedBox(height: Bosluk.s),
          OgrenmeHedefi(
            id: Hedef.ofisUyeTalepKayitDugmesi,
            child: FilledButton(
              onPressed: isleniyor ? null : onKaydet,
              child: isleniyor
                  ? const ButonYukleniyorGostergesi()
                  : const Text('Kayıt oluştur'),
            ),
          ),
        ],
        if (e.oneri) ...[
          const SizedBox(height: Bosluk.s),
          OutlinedButton(
            onPressed: isleniyor ? null : onOneri,
            child: const Text('Değişiklik öner'),
          ),
        ],
        if (e.oneriGeriCek) ...[
          const SizedBox(height: Bosluk.s),
          OutlinedButton(
            onPressed: isleniyor ? null : onOneriGeriCek,
            child: const Text('Öneriyi geri çek'),
          ),
        ],
        if (e.reddet) ...[
          const SizedBox(height: Bosluk.s),
          YikiciButon(etiket: 'Reddet', onPressed: isleniyor ? null : onReddet),
        ],
      ],
    );
  }
}

class _Uyari extends StatelessWidget {
  final String metin;

  const _Uyari(this.metin);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Bosluk.m),
      decoration: BoxDecoration(
          color: ListeTonu.hata.zemin(context),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: ListeTonu.hata.on(context)),
          const SizedBox(width: Bosluk.s),
          Expanded(
              child: Text(metin,
                  style: TextStyle(fontSize: 13, color: context.cs.onSurface))),
        ],
      ),
    );
  }
}
