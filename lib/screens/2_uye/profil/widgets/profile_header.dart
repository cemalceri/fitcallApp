import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:flutter/material.dart';

/// Profil başlığı — avatar, ad ve üye numarası tek satırda.
///
/// Eski başlık ekranın yarısını (340 px) kaplıyordu: bilgiye ulaşmak için
/// kaydırmak gerekiyordu. Artık yatay bir düzen; durum rozetleri gövdeye indi
/// (bkz. `ProfilDurumRozetleri`).
class ProfileHeader extends StatelessWidget {
  final UyeModel uye;
  final Color seviyeRenk;

  const ProfileHeader({
    super.key,
    required this.uye,
    required this.seviyeRenk,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            seviyeRenk.withValues(alpha: 0.22),
            cs.surface,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Bosluk.l, Bosluk.xxl + Bosluk.s, Bosluk.l, Bosluk.l),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(uye: uye, seviyeRenk: seviyeRenk, boyut: 64),
              const SizedBox(width: Bosluk.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${uye.adi} ${uye.soyadi}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.metin.headlineSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Üye No: ${uye.uyeNo} · ${uye.uyeTuru}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.metin.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final UyeModel uye;
  final Color seviyeRenk;
  final double boyut;

  const _Avatar({
    required this.uye,
    required this.seviyeRenk,
    required this.boyut,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final foto = uye.profilFotografi;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: seviyeRenk.withValues(alpha: 0.35),
      ),
      child: Container(
        width: boyut,
        height: boyut,
        decoration: BoxDecoration(shape: BoxShape.circle, color: cs.surface),
        child: ClipOval(
          child: foto != null && foto.isNotEmpty
              ? Image(
                  image: CachedNetworkImageProvider(foto),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _bosAvatar(context),
                )
              : _bosAvatar(context),
        ),
      ),
    );
  }

  Widget _bosAvatar(BuildContext context) {
    final basHarfler =
        '${uye.adi.isNotEmpty ? uye.adi[0] : ''}${uye.soyadi.isNotEmpty ? uye.soyadi[0] : ''}';
    return Container(
      color: context.cs.surfaceContainerHighest,
      child: Center(
        child: Text(
          basHarfler,
          style: TextStyle(
            fontSize: boyut * 0.36,
            fontWeight: FontWeight.bold,
            color: seviyeRenk,
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
