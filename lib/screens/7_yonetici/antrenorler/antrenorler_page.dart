// lib/screens/9_yonetici/antrenorler/antrenorler_page.dart

import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/7_yonetici/antrenorler/widgets/antrenor_istatistik_kartlar.dart';
import 'package:fitcall/screens/7_yonetici/antrenorler/widgets/antrenor_liste_item.dart';
import 'package:fitcall/screens/1_common/degerlendirmeler/degerlendirmeler_page.dart';
import 'package:fitcall/screens/1_common/hakedis/hakedis_ay_panosu_page.dart';
import 'package:fitcall/screens/1_common/hakedis/hakedis_veri_kaynagi.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/common/tema.dart';

class AntrenorlerPage extends StatefulWidget {
  const AntrenorlerPage({super.key});

  @override
  State<AntrenorlerPage> createState() => _AntrenorlerPageState();
}

class _AntrenorlerPageState extends State<AntrenorlerPage> {
  AntrenorlerData? _data;
  bool _loading = true;
  String? _errorMessage;
  String _filtre = 'aktif';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await YoneticiApiService.getAntrenorler(filtre: _filtre);
      if (mounted) {
        setState(() {
          _data = result.data;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Veriler yüklenirken bir hata oluştu.';
          _loading = false;
        });
      }
    }
  }

  void _onFiltreChanged(String filtre) {
    setState(() => _filtre = filtre);
    _loadData();
  }

  /// Satırın sol tarafı: drawer'daki "Hakediş Saatleri" ile aynı ekran,
  /// antrenör seçim adımı atlanmış hâli.
  void _hakedisAc(AntrenorListeItem antrenor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HakedisAyPanosuPage(
          kaynak: YoneticiHakedisKaynagi(antrenor.id),
          baslik: antrenor.adSoyad,
          baslikVeridenGuncellensin: true,
        ),
      ),
    );
  }

  /// Satırın sağındaki puan hücresi: yalnız bu antrenörün dersleri.
  /// Ortalama ve sayı, listedeki rozetle aynı tanımla (ana antrenör, üye
  /// puanları) sayılır.
  void _degerlendirmelerAc(AntrenorListeItem antrenor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DegerlendirmelerPage(
          antrenorId: antrenor.id,
          antrenorAdi: antrenor.adSoyad,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sayi = _loading || _errorMessage != null
        ? null
        : _data?.antrenorler.length;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SekmeBasligi(
              baslik: 'Antrenörler',
              // Seçili süzgece uyan antrenör sayısı (Üyeler'deki "kayıt").
              sag: sayi == null ? null : BaslikKapsulu('$sayi antrenör'),
              alt: BaslikSecici<String>(
                secenekler: const [
                  ('aktif', 'Aktif'),
                  ('pasif', 'Pasif'),
                  ('tumu', 'Tümü'),
                ],
                secili: _filtre,
                onSec: _onFiltreChanged,
              ),
            ),

            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const IskeletListe();
    }

    if (_errorMessage != null) {
      return BosDurum(
        ikon: Icons.error_outline_rounded,
        baslik: 'Liste alınamadı',
        aciklama: _errorMessage!,
        ikonRengi: context.renkler.hata,
        eylemEtiketi: 'Tekrar dene',
        eylemIkonu: Icons.refresh_rounded,
        onEylem: _loadData,
      );
    }

    if (_data == null || _data!.antrenorler.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.1),
            const BosDurum(
              ikon: Icons.sports_tennis_outlined,
              baslik: 'Antrenör yok',
              aciklama: 'Bu filtreye uyan antrenör bulunmuyor.',
            ),
          ],
        ),
      );
    }

    final antrenorler = _data!.antrenorler;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Bosluk.xxl),
        itemCount: antrenorler.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Üstte de boşluk: kartlar başlık bandının kenarına yapışıyordu.
            return Padding(
              padding: const EdgeInsets.all(Bosluk.l),
              child: AntrenorIstatistikKartlar(data: _data!.istatistikler),
            );
          }
          final antrenor = antrenorler[index - 1];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 1) const ListeAyraci(),
              AntrenorListeItemWidget(
                antrenor: antrenor,
                onHakedis: () => _hakedisAc(antrenor),
                onDegerlendirmeler: () => _degerlendirmelerAc(antrenor),
              ),
            ],
          );
        },
      ),
    );
  }
}
