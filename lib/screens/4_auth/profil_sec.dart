// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:fitcall/common/constants.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/1_common/1_notification/pending_action.dart';
import 'package:fitcall/screens/1_common/1_notification/pending_action_store.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:fitcall/services/local/secure_storage_service.dart';
import 'package:fitcall/services/core/fcm_service.dart';

class ProfilSecPage extends StatelessWidget {
  final List<KullaniciProfilModel> kullaniciProfilList;
  const ProfilSecPage(this.kullaniciProfilList, {super.key});

  /* -------- Profil seçildi -------- */
  Future<void> _onTap(BuildContext ctx, KullaniciProfilModel p) async {
    Roller role;
    try {
      LoadingSpinner.show(ctx, message: 'Giriş yapılıyor...');
      role = await AuthService.loginUser(p);
    } on ApiException catch (e) {
      ShowMessage.error(ctx, e.message);
      return;
    } finally {
      LoadingSpinner.hide(ctx);
    }

    final tkn = await SecureStorageService.getValue<String>('token');
    if (tkn != null) await sendFCMDevice(tkn, isMainAccount: p.anaHesap);

    await _redirect(ctx, role);
  }

  /* -------- Yönlendirme -------- */
  Future<void> _redirect(BuildContext ctx, Roller role) async {
    final pending = await PendingActionStore.instance.take();
    if (pending != null) {
      switch (pending.type) {
        case PendingActionType.dersTeyit:
          Navigator.pushNamedAndRemoveUntil(
            ctx,
            routeEnums[SayfaAdi.dersTeyit]!,
            (_) => false,
            arguments: pending.data,
          );
          return;
        case PendingActionType.bildirimListe:
          Navigator.pushNamedAndRemoveUntil(
            ctx,
            routeEnums[SayfaAdi.bildirimler]!,
            (_) => false,
          );
          return;
      }
    }

    switch (role) {
      case Roller.antrenor:
        Navigator.pushNamedAndRemoveUntil(
            ctx, routeEnums[SayfaAdi.antrenorAnasayfa]!, (_) => false);
        break;
      case Roller.yonetici:
        Navigator.pushNamedAndRemoveUntil(
            ctx, routeEnums[SayfaAdi.yoneticiAnasayfa]!, (_) => false);
        break;
      default:
        Navigator.pushNamedAndRemoveUntil(
            ctx, routeEnums[SayfaAdi.uyeAnasayfa]!, (_) => false);
    }
  }

  /* ------------------- UI ------------------- */
  @override
  Widget build(BuildContext context) {
    // Otomatik seç: tek profil varsa liste yerine direkt _onTap çağır
    if (kullaniciProfilList.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onTap(context, kullaniciProfilList.first),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Profil Seç'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: kullaniciProfilList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (_, i) {
            final p = kullaniciProfilList[i];
            final ad = p.uye?.adi ?? p.antrenor?.adi ?? p.user.firstName;
            final soy = p.uye?.soyadi ?? p.antrenor?.soyadi ?? p.user.lastName;
            final tamAd = '$ad $soy';

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _onTap(context, p),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /* -------- Avatar -------- */
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4e54c8),
                          Color(0xFF8f94fb),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3), // Gradient çerçeve
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: p.uye?.profilFotografi != null
                            ? NetworkImage(p.uye!.profilFotografi!)
                            : p.antrenor?.profileImageUrl != null
                                ? NetworkImage(p.antrenor!.profileImageUrl!)
                                : null,
                        child: (p.uye?.profilFotografi == null &&
                                p.antrenor?.profileImageUrl == null)
                            ? Text(
                                ad.characters.first.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  /* -------- İsim -------- */
                  Text(
                    tamAd,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  /* -------- Profil Tipi Etiketi / Yer Tutucu -------- */
                  p.anaHesap
                      ? Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Ana Hesap',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : const SizedBox(
                          height: 24, // Etiket yüksekliği kadar boşluk
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
