// lib/screens/1_common/neler_yeni_page.dart
//
// Ayarlar > "Neler yeni": kurulu sürüme kadarki tüm sürüm notları.
//
// Neden var: açılış popup'ı sürüm başına bir kez çıkıyor ve kapatmak "gördüm"
// sayılıyor. Kapatan ya da popup'ta 4 maddeden fazlasını görmeyen kullanıcının
// gidecek bir yeri olmalı. Dört rolde de Ayarlar var, bu yüzden giriş orada.
//
// Sunucu kurulu sürümden YENİ notları göndermez: kullanıcı henüz
// güncellememişken göremediği bir ekranı okumasın.

import 'package:fitcall/models/1_common/surum_notu_model.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/widgets/sss_gorunumu.dart';
import 'package:fitcall/services/core/surum_notu_service.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class NelerYeniPage extends StatefulWidget {
  /// Testler sürümü doğrudan verir; null ise `PackageInfo`'dan okunur.
  final String? surum;

  /// Testler ağa çıkmasın diye yükleyici enjekte edilebilir.
  final Future<List<SurumNotuBlogu>> Function(String surum)? yukleyici;

  const NelerYeniPage({super.key, this.surum, this.yukleyici});

  @override
  State<NelerYeniPage> createState() => _NelerYeniPageState();
}

class _NelerYeniPageState extends State<NelerYeniPage> {
  List<SurumNotuBlogu>? _bloklar;
  bool _hata = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final surum = widget.surum ?? (await PackageInfo.fromPlatform()).version;
    try {
      final liste = widget.yukleyici != null
          ? await widget.yukleyici!(surum)
          : (await SurumNotuService.arsiv(surum: surum)).data ?? const [];
      if (!mounted) return;
      setState(() => _bloklar = liste);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bloklar = const [];
        _hata = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloklar = _bloklar;
    return Scaffold(
      backgroundColor: context.gecis.sayfaRengi,
      appBar: AppBar(title: const Text('Neler yeni')),
      body: bloklar == null
          ? const Center(child: CircularProgressIndicator())
          : bloklar.isEmpty
              ? _BosDurum(hata: _hata)
              : ListView.builder(
                  padding: const EdgeInsets.all(Bosluk.l),
                  itemCount: bloklar.length,
                  itemBuilder: (_, i) => _SurumBolumu(blok: bloklar[i]),
                ),
    );
  }
}

class _SurumBolumu extends StatelessWidget {
  final SurumNotuBlogu blok;

  const _SurumBolumu({required this.blok});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Bosluk.s, top: Bosluk.s),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 18, color: context.cs.primary),
              const SizedBox(width: Bosluk.s),
              Expanded(
                child: Text(
                  'Sürüm ${blok.surum}',
                  style: context.metin.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.cs.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final madde in blok.maddeler)
          Padding(
            padding: const EdgeInsets.only(bottom: Bosluk.m),
            child: SssKarti(
              sss: SssSoru(
                ikon: madde.ikonVeri,
                soru: madde.baslik,
                cevap: madde.aciklama,
                yol: madde.yol,
              ),
            ),
          ),
        const SizedBox(height: Bosluk.s),
      ],
    );
  }
}

class _BosDurum extends StatelessWidget {
  final bool hata;

  const _BosDurum({required this.hata});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Bosluk.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hata ? Icons.cloud_off_rounded : Icons.auto_awesome_rounded,
              size: 48,
              color: context.cs.onSurfaceVariant,
            ),
            const SizedBox(height: Bosluk.l),
            Text(
              hata
                  ? 'Sürüm notları şu an yüklenemedi.'
                  : 'Bu sürüm için not yok.',
              textAlign: TextAlign.center,
              style: context.metin.bodyLarge
                  ?.copyWith(color: context.cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
