// ignore_for_file: use_build_context_synchronously
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/services/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:fitcall/services/core/fcm_service.dart';
import 'package:fitcall/screens/1_common/1_notification/pending_action.dart';
import 'package:fitcall/screens/1_common/1_notification/pending_action_store.dart';

class ProfilSecPage extends StatefulWidget {
  final List<KullaniciProfilModel> kullaniciProfilList;
  const ProfilSecPage(this.kullaniciProfilList, {super.key});

  @override
  State<ProfilSecPage> createState() => _ProfilSecPageState();
}

class _ProfilSecPageState extends State<ProfilSecPage> {
  bool _yonlendirildi = false;

  @override
  void initState() {
    super.initState();
    // Tüm akış bu sayfada: PendingAction → (tek profil ise) otomatik giriş
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _handlePendingAction();

      if (!_yonlendirildi && widget.kullaniciProfilList.length == 1) {
        _yonlendirildi = true;
        await _profilSecildi(widget.kullaniciProfilList.first);
      }
    });
  }

  // PendingAction varsa önce onu aç
  Future<void> _handlePendingAction() async {
    try {
      final action = await PendingActionStore.instance.take();
      if (action == null) return;
      if (!mounted) return;
      switch (action.type) {
        case PendingActionType.dersTeyit:
          await Navigator.pushNamed(context, routeEnums[SayfaAdi.dersTeyit]!,
              arguments: action.data);
          break;
        case PendingActionType.bildirimListe:
          await Navigator.pushNamed(context, routeEnums[SayfaAdi.bildirimler]!);
          break;
      }
    } catch (_) {/* ignore */}
  }

  Future<void> _profilSecildi(KullaniciProfilModel p) async {
    try {
      LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
      final rol = await AuthService.loginUser(p);
      await sendFCMDevice(isMainAccount: p.anaHesap);

      if (!mounted) return;
      await NavigationHelper.redirectAfterLogin(context, rol);
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } finally {
      LoadingSpinner.hide(context);
    }
  }

  // ---------- Rol yardımcıları ----------

  IconData _rolIkon(String rol) {
    switch (rol) {
      case 'yonetici':
        return Icons.admin_panel_settings_rounded;
      case 'antrenor':
        return Icons.sports_tennis_rounded;
      case 'uye':
        return Icons.person_rounded;
      default:
        return Icons.account_circle_rounded;
    }
  }

  Color _rolRenk(String rol, BuildContext context) {
    switch (rol) {
      case 'yonetici':
        return Colors.indigo;
      case 'antrenor':
        return Colors.teal;
      case 'uye':
        return Colors.deepOrange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _rolBaslik(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color.withAlpha(217)), // ~0.85
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              color: color.withAlpha(242), // ~0.95
              letterSpacing: .2,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(child: Container(height: 1, color: Colors.black12)),
        ],
      ),
    );
  }

// Profil kartı: alt satırda "Ana Hesap" / "Alt Hesap" göster
  Widget _profilKart(KullaniciProfilModel p) {
    final ad = p.uye?.adi ?? p.antrenor?.adi ?? p.user.firstName;
    final soy = p.uye?.soyadi ?? p.antrenor?.soyadi ?? p.user.lastName;
    final tamAd = '$ad $soy'.trim();

    final anaMi = p.anaHesap == true;
    final chipColor = anaMi ? Colors.green : Colors.grey;
    final chipText = anaMi ? 'Ana Hesap' : 'Bağlı hesap';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _profilSecildi(p),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4e54c8), Color(0xFF8f94fb)],
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person, size: 48, color: Colors.white),
          ),

          const SizedBox(height: 12),

          // İsim
          Text(
            tamAd.isEmpty ? p.user.username : tamAd,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 6),

          // Durum çipi: Ana Hesap / Alt Hesap
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: chipColor.withAlpha(20), // ~0.08
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: chipColor.withAlpha(51)), // ~0.20
            ),
            child: Text(
              chipText,
              style: TextStyle(
                color: chipColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _rolGrupGrid(List<KullaniciProfilModel> list) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 24,
      crossAxisSpacing: 24,
      childAspectRatio: 0.8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: list.map(_profilKart).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yoneticiler =
        widget.kullaniciProfilList.where((p) => p.rol == 'yonetici').toList();
    final antrenorler =
        widget.kullaniciProfilList.where((p) => p.rol == 'antrenor').toList();
    final uyeler =
        widget.kullaniciProfilList.where((p) => p.rol == 'uye').toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Profil Seç'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (yoneticiler.isNotEmpty) ...[
                _rolBaslik('Yönetici', _rolIkon('yonetici'),
                    _rolRenk('yonetici', context)),
                _rolGrupGrid(yoneticiler),
                const SizedBox(height: 8),
              ],
              if (antrenorler.isNotEmpty) ...[
                _rolBaslik('Antrenör', _rolIkon('antrenor'),
                    _rolRenk('antrenor', context)),
                _rolGrupGrid(antrenorler),
                const SizedBox(height: 8),
              ],
              if (uyeler.isNotEmpty) ...[
                _rolBaslik('Üye', _rolIkon('uye'), _rolRenk('uye', context)),
                _rolGrupGrid(uyeler),
              ],
              if (yoneticiler.isEmpty && antrenorler.isEmpty && uyeler.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text('Listelenecek profil bulunamadı.'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
