// ignore_for_file: use_build_context_synchronously
import 'package:fitcall/services/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:fitcall/screens/1_common/1_notification/pending_action_store.dart';
import 'package:fitcall/services/api_result.dart';
import 'package:fitcall/services/core/qr_code_api_service.dart';
import 'package:fitcall/models/1_common/event/event_model.dart';
import 'package:fitcall/screens/1_common/event_qr_page.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/notification/notification_router.dart';
import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/main.dart';

class ProfilSecPage extends StatefulWidget {
  final List<KullaniciProfilModel> kullaniciProfilList;
  const ProfilSecPage(this.kullaniciProfilList, {super.key});

  @override
  State<ProfilSecPage> createState() => _ProfilSecPageState();
}

class _ProfilSecPageState extends State<ProfilSecPage> {
  bool _routing = false;
  bool _suppressEventOnce = false;
  late final NotificationRouter _router;

  @override
  void initState() {
    super.initState();
    _router = NotificationRouter(navigatorKey: navigatorKey);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFlow());
  }

  Future<void> _runFlow() async {
    if (!mounted || _routing) return;
    _routing = true;

    try {
      final action = await PendingActionStore.instance.take();
      if (action != null && mounted) {
        final targetUyeId = action.actionParams?['uye_id'];
        final targetAntrenorId = action.actionParams?['antrenor_id'];

        if (targetUyeId != null || targetAntrenorId != null) {
          final activeProfile =
              await StorageService.uyeProfilBilgileriniGetir();
          final currentUyeId = activeProfile?.uye?.id;
          final currentAntrenorId = activeProfile?.antrenor?.id;

          final isCorrectProfile =
              (targetUyeId != null && currentUyeId == targetUyeId) ||
                  (targetAntrenorId != null &&
                      currentAntrenorId == targetAntrenorId);

          if (!isCorrectProfile) {
            await PendingActionStore.instance.set(action);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Bu bildirim başka bir profile ait. Lütfen doğru profili seçin.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3)));
            }
            _routing = false;
            return;
          }
        }

        // ✅ Doğru profil ama henüz seçilmemiş
        // Pending action'ı koru, kullanıcı profil seçsin
        // _profilSecildi() içinde işlenecek
        await PendingActionStore.instance.set(action);
        _routing = false;
        return;
      }
    } catch (e) {
      // PendingAction hatası
    }

    // Event kontrolü
    if (!_suppressEventOnce) {
      final userId = await StorageService.getUserId();
      if (userId != null && userId > 0) {
        try {
          final ApiResult<EventModel?> evRes =
              await QrCodeApiService.getirEventAktifApi(userId: userId);
          if (evRes.data != null && mounted) {
            final closedByUser = await Navigator.push<bool>(context,
                MaterialPageRoute(builder: (_) => EventQrPage(userId: userId)));
            if (closedByUser == true) {
              _suppressEventOnce = true;
            }
            _routing = false;
            Future.microtask(_runFlow);
            return;
          }
        } catch (_) {}
      }
    }

    // Tek profil varsa otomatik login
    if (mounted && widget.kullaniciProfilList.length == 1) {
      await _profilSecildi(widget.kullaniciProfilList.first);
      _routing = false;
      return;
    }

    _routing = false;
    _suppressEventOnce = false;
  }

  // ✅ DÜZELTİLMİŞ _profilSecildi
  Future<void> _profilSecildi(KullaniciProfilModel p) async {
    try {
      LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
      final rol = await AuthService.loginUser(p);
      if (!mounted) return;

      // ✅ Pending action var mı kontrol et
      final pendingAction = PendingActionStore.instance.current;

      if (pendingAction != null) {
        // Pending action varsa, önce onu temizle
        await PendingActionStore.instance.clear();

        final notification = NotificationModel(
          id: pendingAction.notificationId,
          notificationType: '',
          title: pendingAction.title,
          body: pendingAction.body,
          actionType: pendingAction.actionType,
          actionScreen: pendingAction.actionScreen,
          actionParams: pendingAction.actionParams,
          isRead: false,
          timestamp: DateTime.now(),
        );

        // Home'a git
        await NavigationHelper.redirectAfterLogin(context, rol);

        // Kısa bekle, sonra notification route'unu çağır
        await Future.delayed(Duration(milliseconds: 300));
        if (mounted) {
          await _router.route(context, notification);
        }
      } else {
        // Pending action yoksa normal akış
        await NavigationHelper.redirectAfterLogin(context, rol);
      }
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } finally {
      LoadingSpinner.hide(context);
    }
  }

  _RolTheme _getRolTheme(String rol) {
    switch (rol) {
      case 'yonetici':
        return _RolTheme(
            icon: Icons.shield_rounded,
            color: const Color(0xFF6366F1),
            gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            label: 'Yönetici');
      case 'antrenor':
        return _RolTheme(
            icon: Icons.sports_tennis_rounded,
            color: const Color(0xFFEC4899),
            gradient: const [Color(0xFFEC4899), Color(0xFFF43F5E)],
            label: 'Antrenör');
      case 'cafe':
        return _RolTheme(
            icon: Icons.local_cafe_rounded,
            color: const Color(0xFF8B5CF6),
            gradient: const [Color(0xFF8B5CF6), Color(0xFFA855F7)],
            label: 'Kafe');
      default:
        return _RolTheme(
            icon: Icons.person_rounded,
            color: const Color(0xFF10B981),
            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            label: 'Üye');
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedProfiles = <String, List<KullaniciProfilModel>>{};
    for (var p in widget.kullaniciProfilList) {
      groupedProfiles.putIfAbsent(p.rol, () => []).add(p);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: groupedProfiles.entries
                      .map((e) => _buildRoleSection(e.key, e.value))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (Navigator.of(context).canPop())
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: Color(0xFF1E293B))),
            if (!Navigator.of(context).canPop()) const SizedBox(width: 16),
            const Expanded(
                child: Text('Profil Seç',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3))),
          ],
        ),
        Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text('Devam etmek için bir profil seçin',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600))),
      ],
    );
  }

  Widget _buildRoleSection(String rol, List<KullaniciProfilModel> profiles) {
    final theme = _getRolTheme(rol);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: theme.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(theme.icon, size: 18, color: theme.color)),
              const SizedBox(width: 10),
              Text(theme.label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
              const SizedBox(width: 12),
              Expanded(
                  child: Container(height: 1, color: Colors.grey.shade200)),
            ],
          ),
          const SizedBox(height: 16),
          ...profiles.map((p) => _buildProfileCard(p, theme)),
        ],
      ),
    );
  }

  Widget _buildProfileCard(KullaniciProfilModel p, _RolTheme theme) {
    final ad = p.uye?.adi ?? p.antrenor?.adi ?? p.user.firstName;
    final soy = p.uye?.soyadi ?? p.antrenor?.soyadi ?? p.user.lastName;
    final tamAd = '$ad $soy'.trim();
    final displayName = tamAd.isEmpty ? p.user.username : tamAd;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _profilSecildi(p),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: theme.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(theme.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        theme.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RolTheme {
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final String label;

  _RolTheme({
    required this.icon,
    required this.color,
    required this.gradient,
    required this.label,
  });
}
