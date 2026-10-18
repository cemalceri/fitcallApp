// lib/screens/6_muhasebe/havale/widgets/dekont_yukle_govdesi.dart
//
// Dekont yükleme formunun görsel gövdesi (veriyle beslenir, taşma testinde
// doğrudan çizilir). Yalnız dosya zorunlu; tutar ve açıklama isteğe bağlı,
// havale tarihi ve hesap sorulmaz (kullanıcı kararı).

import 'dart:typed_data';

import 'package:fitcall/common/dekont_dosya_util.dart';
import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';

enum DekontKaynagi { kamera, galeri, pdf }

/// "Dekontu nereden ekleyeceksin?" alt sayfasının gövdesi.
class DosyaKaynagiSecenekleri extends StatelessWidget {
  final ValueChanged<DekontKaynagi> onSec;

  const DosyaKaynagiSecenekleri({super.key, required this.onSec});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l, Bosluk.s),
          child: Text('Dekontu nereden ekleyeceksin?',
              style: context.metin.titleMedium),
        ),
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: const Text('Fotoğraf çek'),
          subtitle: const Text('Kâğıt dekont ya da başka bir ekran'),
          onTap: () => onSec(DekontKaynagi.kamera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Galeriden seç'),
          subtitle: const Text('Banka uygulamasının ekran görüntüsü'),
          onTap: () => onSec(DekontKaynagi.galeri),
        ),
        ListTile(
          leading: const Icon(Icons.picture_as_pdf_outlined),
          title: const Text('PDF seç'),
          subtitle: const Text('Bankanın indirdiği dekont'),
          onTap: () => onSec(DekontKaynagi.pdf),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.xs, Bosluk.l, Bosluk.m),
          child: Text(
            'En fazla $dekontEnBuyukMb MB · fotoğraflar otomatik küçültülür',
            style: context.metin.bodySmall
                ?.copyWith(color: context.cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class DekontYukleGovdesi extends StatelessWidget {
  final String? dosyaAdi;
  final int? dosyaBoyutu;
  final bool pdfMi;

  /// Fotoğraf seçildiyse küçük önizleme için baytlar.
  final Uint8List? onizleme;
  final String? hata;
  final String? tutarHatasi;
  final TextEditingController tutarController;
  final TextEditingController aciklamaController;
  final VoidCallback onDosyaSec;
  final bool etkin;

  const DekontYukleGovdesi({
    super.key,
    required this.tutarController,
    required this.aciklamaController,
    required this.onDosyaSec,
    this.dosyaAdi,
    this.dosyaBoyutu,
    this.pdfMi = false,
    this.onizleme,
    this.hata,
    this.tutarHatasi,
    this.etkin = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final metin = context.metin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dosyaAdi == null) _secimAlani(context) else _dosyaKarti(context),
        if (hata != null)
          Padding(
            padding: const EdgeInsets.only(top: Bosluk.s),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 18, color: context.renkler.hata),
                  const SizedBox(width: Bosluk.s),
                  Expanded(
                    child: Text(hata!,
                        style: metin.bodySmall
                            ?.copyWith(color: context.renkler.hata)),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: Bosluk.s, left: Bosluk.xs),
            child: Text(
              'Fotoğraf, ekran görüntüsü ya da PDF · en fazla $dekontEnBuyukMb MB',
              style: metin.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: Bosluk.xl),
        TextField(
          controller: tutarController,
          enabled: etkin,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Tutar (isteğe bağlı)',
            hintText: 'Gönderdiğin tutar',
            suffixText: '₺',
            errorText: tutarHatasi,
          ),
        ),
        const SizedBox(height: Bosluk.l),
        TextField(
          controller: aciklamaController,
          enabled: etkin,
          maxLines: 3,
          minLines: 2,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Açıklama (isteğe bağlı)',
            hintText: "Örn. Ali ve Ayşe'nin Ekim aidatı",
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: Bosluk.s),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: Bosluk.s),
            Expanded(
              child: Text(
                "Dekontun kulüpte kontrol edilir. Bakiyen işlendiği zaman "
                "güncellenir; durumu Dekontlarım'da görürsün.",
                style: metin.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _secimAlani(BuildContext context) {
    final cs = context.cs;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(Yaricap.l),
      child: InkWell(
        onTap: etkin ? onDosyaSec : null,
        borderRadius: BorderRadius.circular(Yaricap.l),
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: Bosluk.xl, horizontal: Bosluk.l),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Yaricap.l),
            border: Border.all(color: cs.outlineVariant, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(Icons.upload_file_rounded, size: 36, color: cs.primary),
              const SizedBox(height: Bosluk.s),
              Text('Dekont seç',
                  style: context.metin.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                'Fotoğraf çek, galeriden ya da PDF olarak ekle',
                textAlign: TextAlign.center,
                style: context.metin.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dosyaKarti(BuildContext context) {
    final cs = context.cs;
    final hataVar = hata != null;
    final boyut = dosyaBoyutu == null ? '' : '${mbMetni(dosyaBoyutu!)} MB · ';
    return Container(
      padding: const EdgeInsets.all(Bosluk.m),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Yaricap.l),
        border: Border.all(
          color: hataVar ? context.renkler.hata : cs.outlineVariant,
          width: hataVar ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Yaricap.s),
            child: SizedBox(
              width: 52,
              height: 64,
              child: onizleme != null && !pdfMi
                  ? Image.memory(onizleme!, fit: BoxFit.cover)
                  : ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        pdfMi
                            ? Icons.picture_as_pdf_outlined
                            : Icons.image_outlined,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: Bosluk.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dosyaAdi!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$boyut${pdfMi ? 'PDF' : 'fotoğraf'}',
                  style: context.metin.bodySmall?.copyWith(
                    color: hataVar ? context.renkler.hata : cs.onSurfaceVariant,
                    fontWeight: hataVar ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: etkin ? onDosyaSec : null,
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }
}
