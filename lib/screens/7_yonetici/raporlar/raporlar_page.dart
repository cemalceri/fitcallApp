// lib/screens/7_yonetici/raporlar/raporlar_page.dart

import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:fitcall/models/9_yonetici/doluluk_haritasi_model.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/7_yonetici/raporlar/widgets/rapor_gruplari.dart';

/// Raporlar: dönem seçimi panodaki gibi içerikte. Kullanıcı isteğiyle
/// (2026-10-16) iki grubun kendi seçicisi var, ısı haritası en altta:
///   1. Ciro ve tahsilat — seçici + özet kartlar + ciro + tahsilat
///   2. Kort ve antrenör — seçici + kort doluluğu + antrenörler
///   3. Bu hafta — ısı haritası (Pzt–Paz; ızgara hep bir hafta, seçiciye
///      bağlı değil)
/// Uzun listeler kendi kartlarında kayar. Aktif üye kartı (o anki sayı,
/// dönemden bağımsız) burada gösterilmez; panoda "Şu an" altında.
class RaporlarPage extends StatefulWidget {
  const RaporlarPage({super.key});

  @override
  State<RaporlarPage> createState() => _RaporlarPageState();
}

/// Kendi seçicisi olan bir grubun durumu. Sunucu yalnız [bolum]'ü hesaplar.
class _RaporGrubu {
  final String bolum;
  DonemFiltresi donem = DonemFiltresi.buHafta;
  RaporlarData? data;

  /// Dönem değişti, sayfa yerinde; yalnız grubun içi iskelette.
  bool yukleniyor = false;

  /// Hızlı art arda seçimde ya da yenileme sürerken geç gelen eski yanıt
  /// yenisini ezmesin.
  int istekNo = 0;

  _RaporGrubu(this.bolum);

  Future<RaporlarData?> getir(DonemFiltresi donem) async =>
      (await YoneticiApiService.getRaporlar(donem: donem, bolum: bolum)).data;
}

class _RaporlarPageState extends State<RaporlarPage> {
  final _ciro = _RaporGrubu('donem');
  final _kort = _RaporGrubu('kort_antrenor');
  DolulukHaritasi? _harita;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final ciroNo = ++_ciro.istekNo;
    final kortNo = ++_kort.istekNo;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Üç istek eşzamanlı; biri hata verirse diğerlerinin hatası yutulur.
      final sonuc = await Future.wait<Object?>([
        _ciro.getir(_ciro.donem),
        _kort.getir(_kort.donem),
        YoneticiApiService.getDolulukHaritasi().then((r) => r.data),
      ]);
      if (!mounted) return;
      setState(() {
        // Yenileme sürerken grubun dönemi değiştiyse o grubun yeni isteği
        // kazanır; bu yanıt yalnız değişmeyen gruba yazılır.
        if (ciroNo == _ciro.istekNo) {
          _ciro.data = sonuc[0] as RaporlarData? ?? _ciro.data;
          _ciro.yukleniyor = false;
        }
        if (kortNo == _kort.istekNo) {
          _kort.data = sonuc[1] as RaporlarData? ?? _kort.data;
          _kort.yukleniyor = false;
        }
        _harita = sonuc[2] as DolulukHaritasi? ?? _harita;
        _loading = false;
      });
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

  /// Panodaki gibi: dönem değişince sayfa iskelete dönmez, yalnız o grubun
  /// içi yenilenir. Hata olursa grup önceki seçimine döner.
  Future<void> _donemDegisti(_RaporGrubu grup, DonemFiltresi donem) async {
    if (grup.data == null) {
      setState(() => grup.donem = donem);
      _loadData();
      return;
    }
    final onceki = grup.donem;
    final no = ++grup.istekNo;
    setState(() {
      grup.donem = donem;
      grup.yukleniyor = true;
    });
    try {
      final data = await grup.getir(donem);
      if (!mounted || no != grup.istekNo) return;
      setState(() {
        grup.data = data ?? grup.data;
        grup.yukleniyor = false;
      });
    } catch (e) {
      if (!mounted || no != grup.istekNo) return;
      setState(() {
        grup.donem = onceki;
        grup.yukleniyor = false;
      });
      ShowMessage.error(
        context,
        e is ApiException ? e.message : 'Veriler yüklenirken bir hata oluştu.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dönem seçimleri ve seçili günler içerikteki kutularda.
            const SekmeBasligi(baslik: 'Raporlar'),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final ciro = _ciro.data;
    final kort = _kort.data;

    // Aşağı çekip yenilemede rapor yerinde durur; iskelet yalnız ilk açılışta.
    if (_loading && ciro == null) {
      return const IskeletKart(anaKartYuksekligi: 110);
    }

    if (_errorMessage != null && ciro == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (ciro == null) {
      return const Center(child: Text('Veri bulunamadı'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RaporDonemGrubu(
              donem: _ciro.donem,
              onDonemChanged: (d) => _donemDegisti(_ciro, d),
              yukleniyor: _ciro.yukleniyor,
              data: ciro,
            ),
            const SizedBox(height: 20),
            RaporKortAntrenorGrubu(
              donem: _kort.donem,
              onDonemChanged: (d) => _donemDegisti(_kort, d),
              yukleniyor: _kort.yukleniyor,
              // Yanıtta veri yoksa bölümler boş durumunu gösterir.
              data: kort ?? RaporlarData.fromJson(const {}),
            ),
            if (_harita != null) ...[
              const SizedBox(height: 20),
              RaporHaftalikYogunluk(data: _harita!, bugun: bugunKulup()),
            ],
          ],
        ),
      ),
    );
  }
}
