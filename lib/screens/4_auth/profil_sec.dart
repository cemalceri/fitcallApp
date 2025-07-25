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
import 'package:fitcall/services/auth_service.dart';
import 'package:fitcall/services/secure_storage_service.dart';
import 'package:fitcall/services/fcm_service.dart';

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
              ctx, routeEnums[SayfaAdi.dersTeyit]!, (_) => false,
              arguments: pending.data);
          return;
        case PendingActionType.bildirimListe:
          Navigator.pushNamedAndRemoveUntil(
              ctx, routeEnums[SayfaAdi.bildirimler]!, (_) => false);
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Profil Seç')),
        body: ListView.builder(
          itemCount: kullaniciProfilList.length,
          itemBuilder: (_, i) {
            final r = kullaniciProfilList[i];
            final ad = r.uye?.adi ?? r.antrenor?.adi ?? r.user.firstName;
            final soy = r.uye?.soyadi ?? r.antrenor?.soyadi ?? r.user.lastName;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text('$ad $soy'),
                onTap: () => _onTap(context, r),
              ),
            );
          },
        ),
      );
}
