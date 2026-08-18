// lib/screens/6_muhasebe/muhasebe_page.dart

import 'package:fitcall/models/6_muhasebe/muhasebe_ozet_model.dart';
import 'package:fitcall/models/6_muhasebe/para_hareket_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/muhasebe/muhasebe_service.dart';
import 'package:fitcall/services/muhasebe/para_hareket_service.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MuhasebePage extends StatefulWidget {
  const MuhasebePage({super.key});

  @override
  State<MuhasebePage> createState() => _MuhasebePageState();
}

class _MuhasebePageState extends State<MuhasebePage> {
  final _scrollController = ScrollController();
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  /// Hareketi olan aylar, yeniden eskiye. Sayfalama birimi olarak kullanılır.
  List<MuhasebeOzetModel> _donemler = [];

  /// Şu ana kadar yüklenmiş hareketler, yeniden eskiye.
  final List<ParaHareketModel> _hareketler = [];

  /// _donemler içinde bir sonraki yüklenecek ayın sırası
  int _sonrakiDonem = 0;

  double _kalanBakiye = 0;
  bool _ilkYukleme = true;

  /// Devam eden dönem isteği; aynı anda ikinci istek açılmasını engeller
  Future<void>? _aktifYukleme;

  /// Her yenilemede artar; uçuşta kalan eski isteklerin listeye yazmasını engeller
  int _nesil = 0;

  /// Bir dönem çekilemediğinde sayfalama durur, kullanıcıya tekrar dene sunulur
  bool _yuklemeHatasi = false;

  bool get _tumHareketlerYuklendi => _sonrakiDonem >= _donemler.length;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _verileriYukle();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final esik = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= esik) {
      _sonrakiDonemiYukle();
    }
  }

  Future<void> _verileriYukle() async {
    final nesil = ++_nesil;
    setState(() {
      _ilkYukleme = true;
      _hareketler.clear();
      _donemler = [];
      _sonrakiDonem = 0;
      _kalanBakiye = 0;
      _yuklemeHatasi = false;
    });

    try {
      final res = await MuhasebeService.fetch();
      final ozetler = res.data ?? [];
      if (!mounted || nesil != _nesil) return;

      // En güncel ayın kapanış bakiyesi = güncel kalan bakiye
      _kalanBakiye = ozetler.isEmpty ? 0 : ozetler.first.kapanisBakiyesi;
      // Hiç hareketi olmayan aylar için istek atmaya gerek yok
      _donemler = ozetler.where((o) => o.borc != 0 || o.odeme != 0).toList();
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } catch (e) {
      if (mounted) ShowMessage.error(context, 'Beklenmeyen bir hata: $e');
    }

    if (!mounted || nesil != _nesil) return;
    setState(() => _ilkYukleme = false);

    // İlk ekranı doldurmaya yetecek kadar hareket çek
    while (mounted &&
        nesil == _nesil &&
        !_tumHareketlerYuklendi &&
        !_yuklemeHatasi &&
        _hareketler.length < 12) {
      await _sonrakiDonemiYukle();
    }
  }

  /// Sıradaki ayın hareketlerini çeker. Zaten bir istek uçuyorsa onu bekler,
  /// böylece scroll tetiklemesi ile ilk doldurma döngüsü çakışmaz.
  Future<void> _sonrakiDonemiYukle() {
    if (_aktifYukleme != null) return _aktifYukleme!;
    if (_tumHareketlerYuklendi || _yuklemeHatasi) return Future.value();

    final future = _donemYukle(_nesil);
    _aktifYukleme = future;
    return future;
  }

  Future<void> _donemYukle(int nesil) async {
    final donem = _donemler[_sonrakiDonem];
    try {
      final res = await ParaHareketService.fetchForPeriod(donem.yil, donem.ay);
      if (!mounted || nesil != _nesil) return;

      final gelenler = (res.data ?? []).where((h) => h.tutar != 0).toList()
        ..sort((a, b) => b.tarih.compareTo(a.tarih));
      setState(() {
        _hareketler.addAll(gelenler);
        _sonrakiDonem++;
      });
    } on ApiException catch (e) {
      if (mounted && nesil == _nesil) {
        ShowMessage.error(context, e.message);
        setState(() => _yuklemeHatasi = true);
      }
    } catch (e) {
      if (mounted && nesil == _nesil) {
        ShowMessage.error(context, 'Beklenmeyen bir hata: $e');
        setState(() => _yuklemeHatasi = true);
      }
    } finally {
      _aktifYukleme = null;
    }
  }

  void _odemeSayfasiniAc() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OdemeBilgiSheet(
        tutar: _kalanBakiye.abs(),
        currencyFormat: _currencyFormat,
      ),
    );
  }

  void _hareketDetayiniAc(ParaHareketModel hareket) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HareketDetaySheet(
        hareket: hareket,
        currencyFormat: _currencyFormat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.05),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(colorScheme),
              if (!_ilkYukleme) _buildBakiyeKarti(colorScheme),
              Expanded(
                child: _ilkYukleme
                    ? _buildLoadingState()
                    : _hareketler.isEmpty && _tumHareketlerYuklendi
                        ? _buildEmptyState(colorScheme)
                        : _buildHareketListesi(colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    // Kabuk sekmesi olarak açıldığında (UyeKabuk "Hareketler") geri okunun
    // gideceği yer yok: pop kabuğun kendi rotasını kapatıp siyah ekran
    // bırakıyordu. Profil sayfasıyla aynı kalıp — ok yalnız gerçekten
    // dönülecek bir sayfa varken çıkar.
    final geriVar = Navigator.of(context).canPop();

    return Padding(
      padding: EdgeInsets.fromLTRB(geriVar ? 8 : 16, 8, 16, 0),
      child: Row(
        children: [
          if (geriVar) ...[
            IconButton(
              tooltip: 'Geri',
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hesap Özeti',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Borç ve ödeme hareketleri',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _verileriYukle,
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tek özet kart: kalan borç / fazla ödeme / borç yok
  Widget _buildBakiyeKarti(ColorScheme colorScheme) {
    final borcVar = _kalanBakiye < 0;
    final fazlaVar = _kalanBakiye > 0;
    final renk = borcVar
        ? context.renkler.hata
        : fazlaVar
            ? context.renkler.basari
            : colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            renk.withValues(alpha: 0.15),
            renk.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: renk.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              borcVar
                  ? Icons.warning_amber_rounded
                  : fazlaVar
                      ? Icons.account_balance_wallet_outlined
                      : Icons.check_circle_outline_rounded,
              color: renk,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  borcVar
                      ? 'Kalan Borç'
                      : fazlaVar
                          ? 'Fazla Ödeme'
                          : 'Borç Yok',
                  style: TextStyle(
                    fontSize: 14,
                    color: renk.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _currencyFormat.format(_kalanBakiye.abs()),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: renk,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (borcVar)
            FilledButton.icon(
              onPressed: _odemeSayfasiniAc,
              icon: const Icon(Icons.payment_rounded, size: 18),
              label: const Text('Öde'),
              style: FilledButton.styleFrom(
                backgroundColor: renk,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() => const IskeletListe();

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: BosDurum(
        ikon: Icons.receipt_long_outlined,
        baslik: 'Hesap hareketi yok',
        aciklama: 'Borç, ödeme ve paket kayıtların burada görünür. '
            'Bir eksiklik olduğunu düşünüyorsan kulüple iletişime geç.',
        eylemEtiketi: 'Üyelik & paketlerim',
        eylemIkonu: Icons.card_membership_rounded,
        onEylem: () =>
            Navigator.pushNamed(context, routeEnums[SayfaAdi.uyelikPaket]!),
      ),
    );
  }

  Widget _buildHareketListesi(ColorScheme colorScheme) {
    // Liste sonundaki "yükleniyor" satırı için bir ekstra eleman
    final ekSatir = _tumHareketlerYuklendi ? 0 : 1;

    return RefreshIndicator(
      onRefresh: _verileriYukle,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _hareketler.length + ekSatir,
        itemBuilder: (context, index) {
          if (index >= _hareketler.length) {
            if (_yuklemeHatasi) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() => _yuklemeHatasi = false);
                      _sonrakiDonemiYukle();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Önceki hareketleri yükle'),
                  ),
                ),
              );
            }
            // Sayfalama sırasında da iskelet: dönen halka listenin biçimini
            // taşımıyor, gelen satırların yerini önden göstermek daha okunur.
            return const IskeletListe(
              satirSayisi: 2,
              kaydirilabilir: false,
            );
          }

          final hareket = _hareketler[index];
          return _HareketSatiri(
            hareket: hareket,
            currencyFormat: _currencyFormat,
            ilkMi: index == 0,
            // Yükleme satırı varken çizgi devam etmeli
            sonMu: index == _hareketler.length - 1 && ekSatir == 0,
            sonSatirMi: index == _hareketler.length - 1,
            onTap: () => _hareketDetayiniAc(hareket),
          );
        },
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          Zaman Çizelgesi Satırı                            */
/* -------------------------------------------------------------------------- */

class _HareketSatiri extends StatelessWidget {
  final ParaHareketModel hareket;
  final NumberFormat currencyFormat;
  final bool ilkMi;
  final bool sonMu;
  final bool sonSatirMi;
  final VoidCallback onTap;

  const _HareketSatiri({
    required this.hareket,
    required this.currencyFormat,
    required this.ilkMi,
    required this.sonMu,
    required this.sonSatirMi,
    required this.onTap,
  });

  static const double _sutunGenisligi = 26;
  static const double _noktaCapi = 10;
  static const double _noktaUstBosluk = 20;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final odemeMi = hareket.odemeYonlu;
    // Sabit `Colors.green/red` koyu temada zeminle yeterince ayrışmıyordu.
    final renk = odemeMi ? context.renkler.basari : context.renkler.hata;
    final cizgiRengi = colorScheme.outlineVariant.withValues(alpha: 0.6);

    final baslik = (hareket.aciklama ?? '').trim().isNotEmpty
        ? hareket.aciklama!.trim()
        : hareket.hareketTuruLabel;
    final altBilgi =
        '${DateFormat('d MMMM yyyy', 'tr').format(hareket.tarih)} · ${hareket.hareketTuruLabel}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kesintisiz dikey çizgi + hareket noktası
          SizedBox(
            width: _sutunGenisligi,
            child: Stack(
              children: [
                if (!ilkMi)
                  Positioned(
                    top: 0,
                    height: _noktaUstBosluk,
                    left: (_sutunGenisligi - 2) / 2,
                    width: 2,
                    child: ColoredBox(color: cizgiRengi),
                  ),
                if (!sonMu)
                  Positioned(
                    top: _noktaUstBosluk + _noktaCapi,
                    bottom: 0,
                    left: (_sutunGenisligi - 2) / 2,
                    width: 2,
                    child: ColoredBox(color: cizgiRengi),
                  ),
                Positioned(
                  top: _noktaUstBosluk,
                  left: (_sutunGenisligi - _noktaCapi) / 2,
                  width: _noktaCapi,
                  height: _noktaCapi,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: renk,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 14, 4, 14),
                  decoration: BoxDecoration(
                    border: sonSatirMi
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              baslik,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              altBilgi,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${odemeMi ? '+' : '-'}${currencyFormat.format(hareket.tutar.abs())}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: renk,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            Hareket Detay Sheet                             */
/* -------------------------------------------------------------------------- */

class _HareketDetaySheet extends StatelessWidget {
  final ParaHareketModel hareket;
  final NumberFormat currencyFormat;

  const _HareketDetaySheet({
    required this.hareket,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final odemeMi = hareket.odemeYonlu;
    final renk = odemeMi ? Colors.green.shade600 : Colors.red.shade600;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '${odemeMi ? '+' : '-'}${currencyFormat.format(hareket.tutar.abs())}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: renk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: renk.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hareket.hareketTuruLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: renk,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        _DetaySatiri(
                          label: 'Tarih',
                          value: DateFormat('d MMMM yyyy', 'tr')
                              .format(hareket.tarih),
                        ),
                        if (hareket.borcTarihi != null)
                          _DetaySatiri(
                            label: 'Borç Tarihi',
                            value: DateFormat('d MMMM yyyy', 'tr')
                                .format(hareket.borcTarihi!),
                          ),
                        if ((hareket.odemeSekli ?? '').isNotEmpty)
                          _DetaySatiri(
                            label: 'Ödeme Şekli',
                            value: hareket.odemeSekli!,
                          ),
                        if ((hareket.referansKodu ?? '').isNotEmpty)
                          _DetaySatiri(
                            label: 'Referans',
                            value: hareket.referansKodu!,
                          ),
                      ],
                    ),
                  ),
                  if ((hareket.aciklama ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Açıklama',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hareket.aciklama!.trim(),
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Kapat'),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

class _DetaySatiri extends StatelessWidget {
  final String label;
  final String value;

  const _DetaySatiri({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            Ödeme Bilgi Sheet                               */
/* -------------------------------------------------------------------------- */

class _OdemeBilgiSheet extends StatelessWidget {
  final double tutar;
  final NumberFormat currencyFormat;

  const _OdemeBilgiSheet({
    required this.tutar,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 48,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Online Ödeme Yakında!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kalan Borç',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        currencyFormat.format(tutar),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Colors.amber.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Şimdilik kulübe başvurun',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Online ödeme özelliği üzerinde çalışıyoruz. Şu an için ödeme yapmak istiyorsanız lütfen kulüp yönetimiyle iletişime geçin.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Kapat'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          const phoneNumber = '905422462982';
                          const whatsappUrl = 'https://wa.me/$phoneNumber';
                          launchUrl(Uri.parse(whatsappUrl),
                              mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.phone_outlined, size: 18),
                        label: const Text('İletişim'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
