// lib/screens/1_common/ogrenme/ilk_giris_karti.dart
//
// Ana sayfanın tepesinde, rol başına bir kez görünen tanıtım kartı:
// "Ekranları birlikte tanıyalım mı?". «Başla» ana sayfanın tanıtım turunu
// açar, «Sonra» kartı kapatır; ikisi de kalıcıdır, tur "?" içinde kalır.
// Açılış popup'larının sırasına girmez: popup kapanınca altında durur ve
// başlıktaki "?"yi gösterir. Sunucuya bir şey yazılmaz.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/ogrenme/gorevler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_butonu.dart';
import 'package:fitcall/services/core/acilis_popup_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/material.dart';

class IlkGirisKarti extends StatefulWidget {
  /// Ana sayfanın tanıtım turu (gorevler.dart).
  final String gorevId;

  /// Sayfanın verisi geldi mi; gelmeden kart çıkmaz (tur yüklenen
  /// kartları gösterir).
  final bool hazir;

  final EdgeInsetsGeometry margin;

  const IlkGirisKarti({
    super.key,
    required this.gorevId,
    this.hazir = true,
    this.margin = IlkGirisKartiGorunumu.kenar,
  });

  @override
  State<IlkGirisKarti> createState() => _IlkGirisKartiState();
}

class _IlkGirisKartiState extends State<IlkGirisKarti> {
  bool _goster = false;
  String? _rol;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final profil = await StorageService.uyeProfilBilgileriniGetir();
    if (profil == null) return;
    if (await AcilisPopupKayitlari.ilkGirisGosterildiMi(
        profil.rol, profil.user.id)) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _rol = profil.rol;
      _userId = profil.user.id;
      _goster = true;
    });
  }

  void _kapat() {
    setState(() => _goster = false);
    final rol = _rol;
    final userId = _userId;
    if (rol != null && userId != null) {
      AcilisPopupKayitlari.ilkGirisGosterildi(rol, userId);
    }
  }

  void _basla() {
    _kapat();
    // Kart kapanıp yerleşim oturunca: hedefler son yerlerinden ölçülsün.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) rehberiAc(context, gorevBul(widget.gorevId));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_goster || !widget.hazir) return const SizedBox.shrink();
    return IlkGirisKartiGorunumu(
      onBasla: _basla,
      onSonra: _kapat,
      margin: widget.margin,
    );
  }
}

/// Kartın görünümü (veriden bağımsız; taşma testi bunu çizer).
class IlkGirisKartiGorunumu extends StatelessWidget {
  final VoidCallback onBasla;
  final VoidCallback onSonra;

  /// Kenarı olmayan listede (ana sayfa) sayfa kenar boşluğu.
  static const kenar = EdgeInsets.fromLTRB(Bosluk.l, Bosluk.m, Bosluk.l, 0);
  final EdgeInsetsGeometry margin;

  const IlkGirisKartiGorunumu({
    super.key,
    required this.onBasla,
    required this.onSonra,
    this.margin = kenar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final metin = context.metin;
    return Container(
      margin: margin,
      padding:
          const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.l, Bosluk.s, Bosluk.s),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Yaricap.l),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline_rounded, color: cs.primary),
              const SizedBox(width: Bosluk.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ekranları birlikte tanıyalım mı?',
                      style: metin.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: Bosluk.xs),
                    Text(
                      'İstediğinde başlıktaki ? işaretine dokun.',
                      style: metin.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Bosluk.s),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: Bosluk.s,
            children: [
              TextButton(onPressed: onSonra, child: const Text('Sonra')),
              FilledButton(onPressed: onBasla, child: const Text('Başla')),
            ],
          ),
        ],
      ),
    );
  }
}
