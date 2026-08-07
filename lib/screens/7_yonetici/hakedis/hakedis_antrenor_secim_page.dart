// lib/screens/7_yonetici/hakedis/hakedis_antrenor_secim_page.dart
//
// Hakediş saatleri akışının 1. adımı: ay seç → o ayın antrenör listesi.
//
// Drawer'daki "Hakediş Saatleri" bu sayfayı açar. Üstteki 4×3 ızgaradan bir ay
// seçilir, altındaki liste o aya göre süzülür. Antrenöre dokunulduğunda ay
// panosu AYNI AYDA açılır (kullanıcı ay seçimini iki kez yapmasın); panonun
// içinde diğer aylara geçmek yine mümkün.
//
// Antrenörler sekmesinden bir antrenöre dokunulduğunda bu adım atlanır,
// doğrudan ay panosu açılır (o zaman içinde bulunulan aydan başlar).

import 'package:fitcall/models/1_common/hakedis_models.dart';
import 'package:fitcall/screens/1_common/hakedis/hakedis_ay_panosu_page.dart';
import 'package:fitcall/screens/1_common/hakedis/hakedis_veri_kaynagi.dart';
import 'package:fitcall/screens/1_common/hakedis/widgets/hakedis_antrenor_listesi.dart';
import 'package:fitcall/screens/1_common/hakedis/widgets/hakedis_stil.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/yonetici/yonetici_hakedis_service.dart';
import 'package:flutter/material.dart';

class HakedisAntrenorSecimPage extends StatefulWidget {
  const HakedisAntrenorSecimPage({super.key});

  @override
  State<HakedisAntrenorSecimPage> createState() =>
      _HakedisAntrenorSecimPageState();
}

class _HakedisAntrenorSecimPageState extends State<HakedisAntrenorSecimPage> {
  HakedisAntrenorListesi? _veri;
  bool _yukleniyor = true;
  String? _hata;
  String _filtre = 'aktif';
  String _arama = '';

  /// Seçili ayın listedeki sırası — 0 = içinde bulunulan ay.
  int _seciliAy = 0;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final sonuc = await YoneticiHakedisService.antrenorler(filtre: _filtre);
      if (!mounted) return;
      final gelen = sonuc.data;
      setState(() {
        _veri = gelen;
        // Backend penceresi değişirse seçili index taşmasın.
        if (gelen != null && _seciliAy >= gelen.aylar.length) _seciliAy = 0;
        _yukleniyor = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.message;
        _yukleniyor = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hata = 'Veriler yüklenirken bir hata oluştu.';
        _yukleniyor = false;
      });
    }
  }

  void _filtreDegis(String filtre) {
    if (_filtre == filtre) return;
    setState(() => _filtre = filtre);
    _yukle();
  }

  List<HakedisAntrenorOzeti> get _suzulmus {
    final tumu = _veri?.antrenorler ?? const <HakedisAntrenorOzeti>[];
    final anahtar = _arama.trim().toLowerCase();
    if (anahtar.isEmpty) return tumu;
    return tumu.where((a) => a.adSoyad.toLowerCase().contains(anahtar)).toList();
  }

  void _antrenorAc(HakedisAntrenorOzeti antrenor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HakedisAyPanosuPage(
          kaynak: YoneticiHakedisKaynagi(antrenor.antrenorId),
          baslik: antrenor.adSoyad,
          baslikVeridenGuncellensin: true,
          // Listede hangi aya bakılıyorsa pano da orada açılsın.
          baslangicAyIndex: _seciliAy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final veri = _veri;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hakediş Saatleri'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: renk.outlineVariant),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Antrenör ara',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (deger) => setState(() => _arama = deger),
                  ),
                  const SizedBox(height: 10),
                  _Filtreler(secili: _filtre, onSec: _filtreDegis),
                ],
              ),
            ),
            Expanded(
              child: HakedisDurumGovdesi(
                yukleniyor: _yukleniyor,
                hata: _hata,
                bosMu: veri == null || veri.aylar.isEmpty,
                bosMesaj: 'Kayıt bulunamadı',
                bosIkon: Icons.person_search_rounded,
                onTekrarDene: _yukle,
                icerik: (_) => HakedisAntrenorListesiGorunumu(
                  aylar: veri!.aylar,
                  seciliIndex: _seciliAy,
                  onAySec: (i) => setState(() => _seciliAy = i),
                  antrenorler: _suzulmus,
                  onAntrenorTap: _antrenorAc,
                  onYenile: _yukle,
                  bosMesaj: _arama.isEmpty
                      ? 'Antrenör bulunamadı'
                      : '"$_arama" ile eşleşen antrenör yok',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filtreler extends StatelessWidget {
  final String secili;
  final ValueChanged<String> onSec;

  const _Filtreler({required this.secili, required this.onSec});

  static const _secenekler = {
    'aktif': 'Aktif',
    'pasif': 'Pasif',
    'tumu': 'Tümü',
  };

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _secenekler.entries.map((girdi) {
          final aktif = girdi.key == secili;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSec(girdi.key),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: aktif
                        ? renk.primary
                        : renk.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: aktif
                          ? renk.primary
                          : renk.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    girdi.value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                      color:
                          aktif ? renk.onPrimary : renk.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
