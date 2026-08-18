// lib/screens/1_common/ayarlar/ayarlar_page.dart
//
// Üç rolün ortak Ayarlar sayfası.
//
// Neden ayrı sayfa: tema seçimi, bildirim izni, şifre değiştirme, KVKK gibi
// "hesap ve uygulama" ayarları profil sayfasının içine dağılmıştı; profil
// kişisel bilgi ekranı, ayar ekranı değil. Yeni ayarlar (bildirim tercihleri,
// dil, önbellek) buraya eklenir — profil sayfası büyümez.

import 'package:fitcall/common/constants.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/1_common/hesap/hesap_sil_page.dart';
import 'package:fitcall/screens/1_common/hesap/sifre_degistir_page.dart';
import 'package:fitcall/screens/1_common/widgets/kvkk.dart';
import 'package:fitcall/screens/4_auth/profil_sec.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/core/tema_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:convert';

class AyarlarPage extends StatefulWidget {
  const AyarlarPage({super.key});

  @override
  State<AyarlarPage> createState() => _AyarlarPageState();
}

class _AyarlarPageState extends State<AyarlarPage> {
  KullaniciProfilModel? _profil;
  String _surum = '';
  bool _bildirimIzni = false;
  int _profilSayisi = 0;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final profil = await StorageService.uyeProfilBilgileriniGetir();
    final paket = await PackageInfo.fromPlatform();
    final izin = await Permission.notification.status;
    final profillerJson =
        await SecureStorageService.getValue<String>('kullanici_profiller');
    final adet =
        profillerJson == null ? 0 : (jsonDecode(profillerJson) as List).length;

    if (!mounted) return;
    setState(() {
      _profil = profil;
      _surum = '${paket.version} (${paket.buildNumber})';
      _bildirimIzni = izin.isGranted;
      _profilSayisi = adet;
    });
  }

  bool get _antrenorMu => _profil?.rol == Roller.antrenor.name;
  bool get _yoneticiMi => _profil?.rol == Roller.yonetici.name;

  Future<void> _profilDegistir() async {
    final jsonStr =
        await SecureStorageService.getValue<String>('kullanici_profiller');
    if (jsonStr == null || !mounted) return;
    final profiller = (jsonDecode(jsonStr) as List)
        .map((e) => KullaniciProfilModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ProfilSecPage(profiller)),
    );
  }

  Future<void> _cikisOnayi() async {
    final onay = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => _OnaySayfasi(
        ikon: Icons.logout_rounded,
        baslik: 'Çıkış yapılsın mı?',
        aciklama: 'Oturumun kapatılacak, bildirimler durdurulacak. '
            'Tekrar giriş yaparak kaldığın yerden devam edebilirsin.',
        onayEtiketi: 'Çıkış Yap',
        yikici: false,
      ),
    );
    if (onay == true && mounted) {
      await AuthService.logout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.s, Bosluk.l, Bosluk.xxl),
        children: [
          const _BolumBasligi('Görünüm'),
          const _Kart(children: [_TemaSecici()]),
          const _BolumBasligi('Bildirimler'),
          _Kart(
            children: [
              _AyarSatiri(
                ikon: _bildirimIzni
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                baslik: 'Bildirim izni',
                altBaslik: _bildirimIzni
                    ? 'Açık — ders ve duyuru bildirimleri geliyor'
                    : 'Kapalı — ders hatırlatmaları ulaşmıyor',
                renk: _bildirimIzni ? context.renkler.basari : cs.error,
                onTap: () async {
                  await openAppSettings();
                  await _yukle();
                },
              ),
              _AyarSatiri(
                ikon: Icons.inbox_rounded,
                baslik: 'Bildirimlerim',
                altBaslik: 'Gelen bildirimlerin listesi',
                onTap: () => Navigator.pushNamed(
                    context, routeEnums[SayfaAdi.bildirimler]!),
              ),
            ],
          ),
          const _BolumBasligi('Hesap'),
          _Kart(
            children: [
              _AyarSatiri(
                ikon: Icons.lock_reset_rounded,
                baslik: 'Şifreyi değiştir',
                altBaslik: 'Hesap güvenliği',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SifreDegistirPage()),
                ),
              ),
              if (_profilSayisi > 1)
                _AyarSatiri(
                  ikon: Icons.swap_horiz_rounded,
                  baslik: 'Profil değiştir',
                  altBaslik: '$_profilSayisi profil bağlı',
                  onTap: _profilDegistir,
                ),
              _AyarSatiri(
                ikon: Icons.privacy_tip_outlined,
                baslik: 'KVKK aydınlatma metni',
                altBaslik: 'Veri işleme ve saklama bilgileri',
                onTap: () => showKvkkAydinlatmaModal(context),
              ),
              _AyarSatiri(
                ikon: Icons.help_outline_rounded,
                baslik: 'Yardım & SSS',
                altBaslik: 'Sık sorulan sorular ve rehber',
                onTap: () => Navigator.pushNamed(
                  context,
                  _antrenorMu
                      ? routeEnums[SayfaAdi.antrenorYardim]!
                      : routeEnums[SayfaAdi.yardim]!,
                ),
              ),
            ],
          ),
          const _BolumBasligi('Uygulama'),
          _Kart(
            children: [
              _AyarSatiri(
                ikon: Icons.info_outline_rounded,
                baslik: 'Sürüm',
                altBaslik: _surum.isEmpty ? 'Okunuyor…' : _surum,
                okGoster: false,
              ),
              _AyarSatiri(
                ikon: Icons.logout_rounded,
                baslik: 'Çıkış yap',
                altBaslik: 'Oturumu kapat',
                onTap: _cikisOnayi,
              ),
            ],
          ),
          if (!_yoneticiMi) ...[
            const _BolumBasligi('Tehlikeli bölge'),
            _Kart(
              kenarRengi: cs.error.withValues(alpha: 0.35),
              children: [
                _AyarSatiri(
                  ikon: Icons.delete_forever_rounded,
                  baslik: 'Hesabı kalıcı sil',
                  altBaslik: 'Tüm verilerin kaldırılır, geri alınamaz',
                  renk: cs.error,
                  yikici: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HesapSilPage()),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/* ============================ Tema seçici ============================ */

class _TemaSecici extends StatelessWidget {
  const _TemaSecici();

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(Bosluk.l, Bosluk.l, Bosluk.l, Bosluk.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 20, color: cs.primary),
              const SizedBox(width: Bosluk.m),
              Expanded(
                child: Text('Tema', style: context.metin.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: Bosluk.xs),
          Text(
            'Sistem seçilirse telefonun karanlık mod ayarına uyar.',
            style:
                context.metin.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: Bosluk.m),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: TemaKontrol.modu,
            builder: (context, aktif, _) {
              return SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: ThemeMode.values
                    .map(
                      (m) => ButtonSegment<ThemeMode>(
                        value: m,
                        icon: Icon(TemaKontrol.ikon(m), size: 18),
                        label: Text(TemaKontrol.etiket(m)),
                        tooltip: '${TemaKontrol.etiket(m)} tema',
                      ),
                    )
                    .toList(),
                selected: {aktif},
                onSelectionChanged: (secim) {
                  HapticFeedback.selectionClick();
                  TemaKontrol.ayarla(secim.first);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/* ============================ Yardımcılar ============================ */

class _BolumBasligi extends StatelessWidget {
  final String baslik;
  const _BolumBasligi(this.baslik);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(Bosluk.xs, Bosluk.xl, Bosluk.xs, Bosluk.s),
      child: Text(
        baslik.toUpperCase(),
        style: context.metin.labelMedium?.copyWith(
          letterSpacing: 0.8,
          color: context.cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Kart extends StatelessWidget {
  final List<Widget> children;
  final Color? kenarRengi;
  const _Kart({required this.children, this.kenarRengi});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Yaricap.l),
        border: Border.all(color: kenarRengi ?? cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 56, color: cs.outlineVariant),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _AyarSatiri extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String altBaslik;
  final VoidCallback? onTap;
  final Color? renk;
  final bool yikici;
  final bool okGoster;

  const _AyarSatiri({
    required this.ikon,
    required this.baslik,
    required this.altBaslik,
    this.onTap,
    this.renk,
    this.yikici = false,
    this.okGoster = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final ikonRengi = renk ?? cs.primary;

    return Semantics(
      button: onTap != null,
      label: baslik,
      hint: altBaslik,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Bosluk.l, vertical: Bosluk.m + 2),
          child: Row(
            children: [
              Icon(ikon, size: 20, color: ikonRengi),
              const SizedBox(width: Bosluk.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslik,
                      style: context.metin.titleSmall?.copyWith(
                        color: yikici ? cs.error : cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      altBaslik,
                      style: context.metin.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (okGoster && onTap != null)
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Onay alt sayfası — ortadaki diyalog yerine başparmakla ulaşılabilir kalıp.
class _OnaySayfasi extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String aciklama;
  final String onayEtiketi;
  final bool yikici;

  const _OnaySayfasi({
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    required this.onayEtiketi,
    required this.yikici,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final renk = yikici ? cs.error : cs.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Bosluk.xl, Bosluk.s, Bosluk.xl, Bosluk.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(ikon, color: renk, size: 26),
            ),
            const SizedBox(height: Bosluk.l),
            Text(baslik, style: context.metin.titleLarge),
            const SizedBox(height: Bosluk.s),
            Text(
              aciklama,
              textAlign: TextAlign.center,
              style: context.metin.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: Bosluk.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: Bosluk.m),
                Expanded(
                  child: FilledButton(
                    style: yikici
                        ? FilledButton.styleFrom(
                            backgroundColor: cs.error,
                            foregroundColor: cs.onError,
                          )
                        : null,
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(onayEtiketi),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
