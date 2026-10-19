// lib/screens/6_muhasebe/muhasebe_page.dart

import 'package:fitcall/models/6_muhasebe/muhasebe_ozet_model.dart';
import 'package:fitcall/models/6_muhasebe/para_hareket_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/muhasebe/muhasebe_service.dart';
import 'package:fitcall/services/muhasebe/para_hareket_service.dart';
import 'package:fitcall/services/muhasebe/dekont_service.dart';
import 'package:fitcall/screens/6_muhasebe/havale/widgets/havale_bilgi_satiri.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/kimlik_yuzeyi.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/6_muhasebe/widgets/odeme_butonlari.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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

  /// Kontrol bekleyen havale dekontu sayısı (bakiye yalnız onayla değişir;
  /// üye bakiyenin neden değişmediğini görsün, ikinci kez havale yapmasın).
  int _bekleyenDekont = 0;

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
    _dekontSayisiniYukle();

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

  /// Bekleyen dekont sayısı. Hata ekranı bozmasın: sayı yalnız bilgi satırı.
  Future<void> _dekontSayisiniYukle() async {
    try {
      final sonuc = await DekontService.dekontlarim();
      if (mounted) setState(() => _bekleyenDekont = sonuc.bekleyenSayisi);
    } catch (_) {}
  }

  /// Havale / EFT sayfası: hesaplar + dekontlar. Borçtan bağımsız açılır
  /// (avans ödeyen, borcu yeni sıfırlanmış üye de dekontlarına ulaşsın).
  Future<void> _odemeSayfasiniAc({bool dekontlar = false}) async {
    HapticFeedback.mediumImpact();
    await Navigator.pushNamed(
      context,
      routeEnums[SayfaAdi.havaleEft]!,
      arguments: {
        'kalanBakiye': _kalanBakiye,
        if (dekontlar) 'sekme': 'dekontlar',
      },
    );
    if (mounted) _dekontSayisiniYukle();
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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildAppBar(colorScheme),
            if (!_ilkYukleme) _buildBakiyeKarti(colorScheme),
            if (!_ilkYukleme && _bekleyenDekont > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: HavaleBilgiSatiri(
                  bekleyenSayisi: _bekleyenDekont,
                  onTap: () => _odemeSayfasiniAc(dekontlar: true),
                ),
              ),
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
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    // Kabuk sekmesi olarak açıldığında (UyeKabuk "Hareketler") geri okunun
    // gideceği yer yok: pop kabuğun kendi rotasını kapatıp siyah ekran
    // bırakıyordu. Profil sayfasıyla aynı kalıp — ok yalnız gerçekten
    // dönülecek bir sayfa varken çıkar.
    final geriVar = Navigator.of(context).canPop();

    // Takım renginde başlık bandı; bakiye kartı (kimlik yüzeyi) altında
    // sayfa zemininde.
    return BaslikBandi(
      padding: EdgeInsets.fromLTRB(geriVar ? 4 : 16, 6, 8, 12),
      child: Row(
        children: [
          if (geriVar) ...[
            IconButton(
              tooltip: 'Geri',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
            const SizedBox(width: 4),
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
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Borç ve ödeme hareketleri',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          BaslikIkonButonu(
            ikon: Icons.refresh_rounded,
            ipucu: 'Yenile',
            onTap: _verileriYukle,
          ),
        ],
      ),
    );
  }

  /// Tek özet kart: kalan borç / fazla ödeme / borç yok. Ekranın kimlik
  /// yüzeyi: tutar beyaz, borç durumu zemin renkli kapsülde kelime + ikonla
  /// (durum rengi kendi zemininde okunur; takım kırmızısının üstüne yazılmaz).
  Widget _buildBakiyeKarti(ColorScheme colorScheme) {
    final borcVar = _kalanBakiye < 0;
    final fazlaVar = _kalanBakiye > 0;
    final durumRengi = borcVar
        ? context.renkler.hata
        : fazlaVar
            ? context.renkler.basari
            : colorScheme.onSurfaceVariant;
    final yazi = context.gecis.onKimlik;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: KimlikYuzeyi(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 21),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    borcVar
                        ? 'Kalan borç'
                        : fazlaVar
                            ? 'Fazla ödeme'
                            : 'Borç yok',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: yazi,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        borcVar
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 14,
                        color: durumRengi,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        borcVar
                            ? 'Ödeme bekliyor'
                            : fazlaVar
                                ? 'Alacaklısınız'
                                : 'Hesap kapalı',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: durumRengi,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _currencyFormat.format(_kalanBakiye.abs()),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: yazi,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Borç yokken de görünür: avans ödeme ve dekontlara erişim.
            OdemeButonlari(
              onHavale: _odemeSayfasiniAc,
              onKrediKarti: () => krediKartiYakindaGoster(context,
                  onHavale: _odemeSayfasiniAc),
            ),
          ],
        ),
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
    final renk = odemeMi ? context.renkler.basari : context.renkler.hata;

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
