import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/screens/1_common/widgets/kimlik_yuzeyi.dart';
import 'package:fitcall/screens/2_uye/profil/widgets/profil_fotografi_secici.dart';
import 'package:flutter/material.dart';

/// Profil başlığı — avatar, ad ve üye numarası; sayfanın kimlik yüzeyi.
///
/// Eski başlık ekranın yarısını (340 px) kaplıyordu: bilgiye ulaşmak için
/// kaydırmak gerekiyordu. Artık yatay bir kart; durum rozetleri gövdeye indi
/// (bkz. `ProfilDurumRozetleri`). Seviye (top) rengi başlıkta değil rozette:
/// renkli kimlik yüzeyinin üstünde ikinci bir renk halkası gürültü olurdu.
///
/// Avatara dokununca üye kendi fotoğrafını ekler / değiştirir / kaldırır
/// (bkz. profil_fotografi_secici.dart). Yükleme sürerken avatarın üstünde
/// halka döner; sonuç burada tutulur, sayfa yeniden açılınca cihazdaki
/// güncellenmiş profilden okunur.
class ProfileHeader extends StatefulWidget {
  final UyeModel uye;
  final Color seviyeRenk;

  /// false ise avatar dokunulamaz (başkasının profili gösteriliyorsa).
  final bool duzenlenebilir;

  const ProfileHeader({
    super.key,
    required this.uye,
    required this.seviyeRenk,
    this.duzenlenebilir = true,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  late String? _foto = widget.uye.profilFotografi;
  bool _yukleniyor = false;

  @override
  void didUpdateWidget(covariant ProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sayfa profili yeniden çekince (yenile) sunucudaki adres esas.
    if (oldWidget.uye.profilFotografi != widget.uye.profilFotografi) {
      _foto = widget.uye.profilFotografi;
    }
  }

  Future<void> _fotografDegistir() async {
    final fotoVar = _foto != null && _foto!.isNotEmpty;
    final secim = await profilFotoSecimiSor(context, fotoVar: fotoVar);
    if (secim == null || !mounted) return;
    final sonuc = await profilFotografiIslemi(
      context,
      secim,
      yukleniyor: (v) {
        if (mounted) setState(() => _yukleniyor = v);
      },
    );
    if (sonuc.degisti && mounted) setState(() => _foto = sonuc.url);
  }

  @override
  Widget build(BuildContext context) {
    final uye = widget.uye;
    final foto = _foto;
    final ad = '${uye.adi} ${uye.soyadi}';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Bosluk.l, kToolbarHeight + Bosluk.xs, Bosluk.l, Bosluk.m),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: KimlikBaslik(
            // Renkli başlığın içinde: ayrı kart yüzeyi başlıkla aynı tonda
            // kayboluyordu; başlığın kendisi kimlik alanı.
            yuzeysiz: true,
            baslik: ad,
            basHarfler: basHarfleri(ad),
            altBaslik: 'Üye No: ${uye.uyeNo} · ${uye.uyeTuru}',
            onAvatarTap: widget.duzenlenebilir ? _fotografDegistir : null,
            avatarYukleniyor: _yukleniyor,
            avatarEtiketi: foto != null && foto.isNotEmpty
                ? 'Profil fotoğrafını değiştir'
                : 'Profil fotoğrafı ekle',
            avatar: foto != null && foto.isNotEmpty
                ? Image(
                    image: CachedNetworkImageProvider(foto),
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (c, _, __) => Center(
                      child: Text(
                        basHarfleri(ad),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: c.gecis.onKimlik,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Üyenin durum rozetleri — başlıktan gövdeye indi.
class ProfilDurumRozetleri extends StatelessWidget {
  final UyeModel uye;
  final Color seviyeRenk;

  const ProfilDurumRozetleri({
    super.key,
    required this.uye,
    required this.seviyeRenk,
  });

  @override
  Widget build(BuildContext context) {
    final renkler = context.renkler;

    return Wrap(
      spacing: Bosluk.s,
      runSpacing: Bosluk.s,
      children: [
        _Rozet(
          label: uye.aktifMi ? 'Aktif' : 'Pasif',
          color: uye.aktifMi ? renkler.basari : renkler.hata,
          icon:
              uye.aktifMi ? Icons.check_circle_outline : Icons.cancel_outlined,
        ),
        _Rozet(
          label: uye.seviyeRengi,
          color: seviyeRenk,
          icon: Icons.sports_tennis,
        ),
        if (uye.onaylandiMi)
          _Rozet(
            label: 'Onaylı',
            color: renkler.bilgi,
            icon: Icons.verified_outlined,
          ),
      ],
    );
  }
}

class _Rozet extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Rozet({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Bosluk.m, vertical: Bosluk.s),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Yaricap.xl),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: Bosluk.xs + 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
