// lib/screens/1_common/program/program_gun_seridi.dart
//
// Haftanın gün seçici şeridi.
//
// Hücre yüksekliği sabit, içerik üç satır (gün kısaltması / gün no / ders
// sayısı). Yazı boyutu cihaz erişilebilirlik ayarıyla büyüyebildiğinden içerik
// FittedBox(scaleDown) ile sarılı: sığmazsa taşma hatası vermek yerine küçülür.

import 'package:fitcall/models/9_yonetici/etkinlik_yonetim_models.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_hedefi.dart';
import 'package:material_ui/material_ui.dart';

class ProgramGunSeridi extends StatelessWidget {
  final List<ProgramGunu> gunler;

  /// Seçili günün "YYYY-MM-DD" anahtarı
  final String seciliTarih;

  /// Bugünün "YYYY-MM-DD" anahtarı (çerçeveyle işaretlenir)
  final String bugunTarih;

  final ValueChanged<DateTime> onGunSec;

  /// Rehberin işaret edeceği gün; null dönen kimliksiz sarılır (hedef olmaz).
  final String? Function(ProgramGunu gun)? gunHedefi;

  /// Aynı güne birden çok rehber kimliği (ör. dersi olan ve iptalli dersi
  /// olan gün); [gunHedefi] ile birlikte verilebilir.
  final List<String> Function(ProgramGunu gun)? gunHedefleri;

  const ProgramGunSeridi({
    super.key,
    required this.gunler,
    required this.seciliTarih,
    required this.bugunTarih,
    required this.onGunSec,
    this.gunHedefi,
    this.gunHedefleri,
  });

  static const double yukseklik = 74.0;
  static const double _hucreGenisligi = 52.0;
  static const double _dikeyBosluk = 6.0;

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;

    return SizedBox(
      height: yukseklik,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: gunler.length,
        itemBuilder: (context, i) {
          final gun = gunler[i];
          final aktif = gun.tarihMetin == seciliTarih;
          final bugunMu = gun.tarihMetin == bugunTarih;

          Widget hucre = GestureDetector(
                onTap: () => onGunSec(gun.tarih),
                child: Container(
                  width: _hucreGenisligi,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: _dikeyBosluk,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  decoration: BoxDecoration(
                    color: aktif
                        ? renk.primary
                        : renk.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: bugunMu && !aktif
                        ? Border.all(color: renk.primary, width: 1.4)
                        : null,
                  ),
                  // Yazı ölçeği büyüdüğünde taşma yerine küçültme
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          gun.gunKisa,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                            color:
                                aktif ? renk.onPrimary : renk.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${gun.tarih.day}',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.2,
                            fontWeight: FontWeight.bold,
                            color: aktif ? renk.onPrimary : renk.onSurface,
                          ),
                        ),
                        Text(
                          '${gun.dersSayisi} ders',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 9.5,
                            height: 1.1,
                            color: aktif
                                ? renk.onPrimary.withValues(alpha: 0.85)
                                : renk.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
          for (final id in gunHedefleri?.call(gun) ?? const <String>[]) {
            hucre = ogrenmeHedefiSar(id, hucre);
          }
          return ogrenmeHedefiSar(gunHedefi?.call(gun), hucre);
        },
      ),
    );
  }
}
