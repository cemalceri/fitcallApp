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

import 'package:fitcall/services/api_result.dart';
import 'package:fitcall/services/core/qr_code_api_service.dart';
import 'package:fitcall/models/1_common/event/event_model.dart';
import 'package:fitcall/screens/1_common/event_qr_page.dart';
import 'package:fitcall/services/core/storage_service.dart';

class ProfilSecPage extends StatefulWidget {
  final List<KullaniciProfilModel> kullaniciProfilList;
  const ProfilSecPage(this.kullaniciProfilList, {super.key});

  @override
  State<ProfilSecPage> createState() => _ProfilSecPageState();
}

class _ProfilSecPageState extends State<ProfilSecPage> {
  bool _routing = false; // eşzamanlı yönlendirme kilidi
  bool _suppressEventOnce =
      false; // Event’ten X/geri ile dönüldüğünde tek sefer atla

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFlow());
  }

  Future<void> _runFlow() async {
    if (!mounted || _routing) return;
    _routing = true;

    // 1) PendingAction
    try {
      final action = await PendingActionStore.instance.take();
      if (action != null && mounted) {
        switch (action.type) {
          case PendingActionType.dersTeyit:
            await Navigator.pushNamed(context, routeEnums[SayfaAdi.dersTeyit]!,
                arguments: action.data);
            break;
          case PendingActionType.bildirimListe:
            await Navigator.pushNamed(
                context, routeEnums[SayfaAdi.bildirimler]!);
            break;
        }
        _routing = false;
        Future.microtask(_runFlow); // geri dönünce akışı tekrar çalıştır
        return;
      }
    } catch (_) {/* sessiz geç */}

    // 2) Aktif Event (kullanıcı geri döndüyse bir kez bastır)
    if (!_suppressEventOnce) {
      final userId = await StorageService.getUserId();
      if (userId != null && userId > 0) {
        try {
          final ApiResult<EventModel?> evRes =
              await QrCodeApiService.getirEventAktifApi(userId: userId);
          if (evRes.data != null && mounted) {
            final closedByUser = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => EventQrPage(userId: userId)),
            );
            if (closedByUser == true) {
              _suppressEventOnce = true; // 🔑 geri/X ile döndü
            }
            _routing = false;
            Future.microtask(_runFlow);
            return;
          }
        } catch (_) {/* sessiz geç */}
      }
    }

    // 3) Tek profil ise otomatik giriş
    if (mounted && widget.kullaniciProfilList.length == 1) {
      await _profilSecildi(widget.kullaniciProfilList.first);
      _routing = false;
      return;
    }

    // Profil listesi gösterilecek
    _routing = false;
    _suppressEventOnce = false; // ekran görüldü; bastırmayı sıfırla
  }

  Future<void> _profilSecildi(KullaniciProfilModel p) async {
    try {
      LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
      final rol = await AuthService.loginUser(p);
      if (!mounted) return;
      await NavigationHelper.redirectAfterLogin(context, rol);
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
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
          Icon(icon, size: 18, color: color.withAlpha(217)),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: color.withAlpha(242),
                  letterSpacing: .2)),
          const SizedBox(width: 6),
          Expanded(child: Container(height: 1, color: Colors.black12)),
        ],
      ),
    );
  }

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
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4e54c8), Color(0xFF8f94fb)]),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(tamAd.isEmpty ? p.user.username : tamAd,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: chipColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: chipColor.withAlpha(51)),
            ),
            child: Text(chipText,
                style: TextStyle(
                    color: chipColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
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

  // ----------- Boş durum bileşeni (yalnızca EMPTY CASE için) -----------
  Widget _emptyState(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              spreadRadius: 0,
              offset: Offset(0, 6),
              color: Color(0x14000000),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hafif modern ikonlu başlık
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withAlpha((.15 * 255).toInt()),
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withAlpha((.05 * 255).toInt()),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.person_search_rounded,
                size: 40,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withAlpha((.9 * 255).toInt()),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kullanıcınıza ait herhangi bir üye profili bulunmuyor',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Bir yanlışlık olduğunu düşünüyorsanız lütfen iletişime geçin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.black.withAlpha((.55 * 255).toInt()),
              ),
            ),
            const SizedBox(height: 16),
            if (canPop)
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Geri'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
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
      appBar: AppBar(title: const Text('Profil Seç'), centerTitle: true),
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

              // ----------- Güncellenen boş durum -----------
              if (yoneticiler.isEmpty && antrenorler.isEmpty && uyeler.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: _emptyState(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
