// ignore_for_file: use_build_context_synchronously
//
// Profil seçimi: bir hesabın üye / antrenör / yönetici profilleri arasından
// biri seçilir.
//
// Her rol bir grup: başlıkta rol ikonu + ad + profil sayısı, profiller altında
// tek bir yüzey kutusunun içinde. Düz listede gruplar birbirine karışıyor,
// tek liste gibi görünüyordu. Kutu düz ton (surfaceContainerLow) — eski
// tasarımın gradyanlı profil kartları koyu modda yarı beyaz kalıp isimleri
// okutmuyordu, o yüzden kart profil başına değil grup başına ve gradyansız.

import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/auth_service.dart';

class ProfilSecPage extends StatefulWidget {
  final List<KullaniciProfilModel> kullaniciProfilList;
  const ProfilSecPage(this.kullaniciProfilList, {super.key});

  @override
  State<ProfilSecPage> createState() => _ProfilSecPageState();
}

class _ProfilSecPageState extends State<ProfilSecPage> {
  bool _routing = false;

  /// Şu an açık olan profil (profil değiştirirken halkayla gösterilir).
  int? _aktifProfilId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFlow());
    _aktifProfiliOku();
  }

  Future<void> _aktifProfiliOku() async {
    try {
      final aktif = await StorageService.uyeProfilBilgileriniGetir();
      if (mounted && aktif != null) setState(() => _aktifProfilId = aktif.id);
    } catch (_) {
      // Okunamazsa halka gösterilmez; seçim yine çalışır.
    }
  }

  Future<void> _runFlow() async {
    if (!mounted || _routing) return;
    _routing = true;

    // Tek profil varsa otomatik login
    if (mounted && widget.kullaniciProfilList.length == 1) {
      await _profilSecildi(widget.kullaniciProfilList.first);
      _routing = false;
      return;
    }

    _routing = false;
  }

  Future<void> _profilSecildi(KullaniciProfilModel p) async {
    LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
    try {
      final rol = await AuthService.loginUser(p);
      if (!mounted) return;
      // Spinner diyaloğunu `redirectAfterLogin` içindeki popUntil zaten
      // kaldırıyor; push bir sonraki kareye erteleniyor. Burada ayrıca
      // hide() çağrılırsa diyalog değil SAYFANIN KENDİSİ pop ediliyor (altta
      // rota yoksa bir kare boş navigator). Bu yüzden hide yalnız hata
      // dalında — başarı yolunda gezinme temizliyor.
      await NavigationHelper.redirectAfterLogin(context, rol);
    } on ApiException catch (e) {
      if (!mounted) return;
      LoadingSpinner.hide(context);
      ShowMessage.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      LoadingSpinner.hide(context);
      ShowMessage.error(context, 'Giriş yapılamadı. Lütfen tekrar deneyin.');
    }
  }

  static (String, IconData) _rolBilgisi(String rol) => switch (rol) {
        'yonetici' => ('Yönetici', Icons.shield_outlined),
        'antrenor' => ('Antrenör', Icons.sports_tennis_rounded),
        'ofis' => ('Ofis', Icons.support_agent_rounded),
        'cafe' => ('Kafe', Icons.local_cafe_outlined),
        _ => ('Üye', Icons.person_outline_rounded),
      };

  String _profilAdi(KullaniciProfilModel p) {
    final ad = p.uye?.adi ?? p.antrenor?.adi ?? p.user.firstName;
    final soy = p.uye?.soyadi ?? p.antrenor?.soyadi ?? p.user.lastName;
    final tamAd = '$ad $soy'.trim();
    return tamAd.isEmpty ? p.user.username : tamAd;
  }

  @override
  Widget build(BuildContext context) {
    final groupedProfiles = <String, List<KullaniciProfilModel>>{};
    for (var p in widget.kullaniciProfilList) {
      groupedProfiles.putIfAbsent(p.rol, () => []).add(p);
    }

    // Grupları sabit sırayla göster (Yönetici → Ofis → Antrenör → Üye → Kafe →
    // diğer); her grup içinde profilleri ada göre alfabetik sırala. Aksi halde
    // gruplar en son eklenen veriye göre rastgele sırada geliyordu.
    const rolSirasi = ['yonetici', 'ofis', 'antrenor', 'uye', 'cafe'];
    int rolIndex(String r) {
      final i = rolSirasi.indexOf(r);
      return i == -1 ? rolSirasi.length : i;
    }

    final siraliRoller = groupedProfiles.keys.toList()
      ..sort((a, b) {
        final c = rolIndex(a).compareTo(rolIndex(b));
        return c != 0 ? c : a.compareTo(b);
      });
    for (final list in groupedProfiles.values) {
      list.sort((a, b) =>
          _profilAdi(a).toLowerCase().compareTo(_profilAdi(b).toLowerCase()));
    }

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _baslik(context),
            Expanded(
              child: widget.kullaniciProfilList.isEmpty
                  ? BosDurum(
                      ikon: Icons.inbox_rounded,
                      baslik: 'Profil bulunamadı',
                      aciklama: 'Bu hesaba bağlı bir profil yok.',
                      ikonRengi: context.cs.onSurfaceVariant,
                      eylemEtiketi: 'Çıkış yap',
                      eylemIkonu: Icons.logout_rounded,
                      onEylem: () => AuthService.logout(context),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: Bosluk.xl),
                      children: [
                        for (final rol in siraliRoller) ...[
                          _grupBasligi(
                              context, rol, groupedProfiles[rol]!.length),
                          _grupKutusu(context, groupedProfiles[rol]!),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Takım renginde başlık bandı.
  Widget _baslik(BuildContext context) {
    final geriVar = Navigator.of(context).canPop();
    return BaslikBandi(
      padding: EdgeInsets.fromLTRB(
          geriVar ? Bosluk.xs : Bosluk.l, Bosluk.m, Bosluk.l, Bosluk.l),
      child: Row(
        children: [
          if (geriVar)
            IconButton(
              tooltip: 'Geri',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil seç',
                  style: baslikYazi(context, context.metin.headlineSmall)
                      ?.copyWith(letterSpacing: -0.3),
                ),
                const SizedBox(height: 2),
                Text(
                  'Devam etmek için bir profil seçin',
                  style: baslikYazi(context, context.metin.bodySmall),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _grupBasligi(BuildContext context, String rol, int adet) {
    final (etiket, ikon) = _rolBilgisi(rol);
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Bosluk.l, Bosluk.xl, Bosluk.l, Bosluk.s),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ListeTonu.vurgu.zemin(context),
              borderRadius: BorderRadius.circular(Yaricap.s),
            ),
            child: Icon(ikon, size: 17, color: ListeTonu.vurgu.on(context)),
          ),
          const SizedBox(width: Bosluk.s + 2),
          Flexible(
            child: Text(
              etiket,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.metin.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: Bosluk.s),
          Text(
            '$adet',
            style: context.metin.labelMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Bir rolün profilleri tek kutuda; satırlar arasında ince ayraç.
  Widget _grupKutusu(
      BuildContext context, List<KullaniciProfilModel> profiller) {
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Bosluk.l),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Yaricap.l),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Yaricap.l - 1),
          child: Column(
            children: [
              for (final (i, p) in profiller.indexed) ...[
                _profilSatiri(context, p),
                if (i < profiller.length - 1)
                  const ListeAyraci(solBosluk: 70),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _profilSatiri(BuildContext context, KullaniciProfilModel p) {
    final ad = _profilAdi(p);
    final isletme = p.isletmeAdi;
    final aktif = p.id == _aktifProfilId;
    final cs = context.cs;

    // Alt satır: işletme adı (birden çok işletmede aynı isim/rol ayırt
    // edilebilsin). İşletme yoksa role düşer.
    final altSatir = isletme == null || isletme.isEmpty
        ? Text(
            _rolBilgisi(p.rol).$1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.metin.bodySmall,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_outlined,
                  size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isletme,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.metin.bodySmall,
                ),
              ),
            ],
          );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => _profilSecildi(p),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Bosluk.m, vertical: Bosluk.m),
          child: Row(
            children: [
              // Açık profil ana renk halkasıyla gösterilir.
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: aktif ? cs.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListeAvatari(
                  basHarfler: ListeAvatari.harfler(ad),
                  ton: ListeTonu.vurgu,
                  cap: 42,
                  // Üye profilinde kendi yüklediği fotoğraf.
                  fotoUrl: p.uye?.profilFotografi,
                ),
              ),
              const SizedBox(width: Bosluk.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.metin.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    altSatir,
                  ],
                ),
              ),
              if (aktif)
                Padding(
                  padding: const EdgeInsets.only(right: Bosluk.xs),
                  child: Text('Açık', style: context.metin.labelMedium),
                ),
              Icon(Icons.chevron_right_rounded,
                  size: 22, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
