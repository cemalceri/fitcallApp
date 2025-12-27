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

        await PendingActionStore.instance.clear();

        final notification = NotificationModel(
          id: action.notificationId,
          notificationType: '',
          title: action.title,
          body: action.body,
          actionType: action.actionType,
          actionScreen: action.actionScreen,
          actionParams: action.actionParams,
          isRead: false,
          timestamp: DateTime.now(),
        );

        await _router.route(context, notification);
        _routing = false;
        Future.microtask(_runFlow);
        return;
      }
    } catch (e) {
      // PendingAction hatası
    }

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

    if (mounted && widget.kullaniciProfilList.length == 1) {
      await _profilSecildi(widget.kullaniciProfilList.first);
      _routing = false;
      return;
    }

    _routing = false;
    _suppressEventOnce = false;
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
            color: const Color(0xFF14B8A6),
            gradient: const [Color(0xFF14B8A6), Color(0xFF10B981)],
            label: 'Antrenör');
      case 'uye':
        return _RolTheme(
            icon: Icons.person_rounded,
            color: const Color(0xFFF97316),
            gradient: const [Color(0xFFF97316), Color(0xFFFB923C)],
            label: 'Üye');
      default:
        return _RolTheme(
            icon: Icons.account_circle_rounded,
            color: const Color(0xFF64748B),
            gradient: const [Color(0xFF64748B), Color(0xFF94A3B8)],
            label: 'Kullanıcı');
    }
  }

  @override
  Widget build(BuildContext context) {
    final yoneticiler =
        widget.kullaniciProfilList.where((p) => p.rol == 'yonetici').toList();
    final antrenorler =
        widget.kullaniciProfilList.where((p) => p.rol == 'antrenor').toList();
    final uyeler =
        widget.kullaniciProfilList.where((p) => p.rol == 'uye').toList();
    final isEmpty =
        yoneticiler.isEmpty && antrenorler.isEmpty && uyeler.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (yoneticiler.isNotEmpty)
                            _buildRoleSection('yonetici', yoneticiler),
                          if (antrenorler.isNotEmpty)
                            _buildRoleSection('antrenor', antrenorler),
                          if (uyeler.isNotEmpty)
                            _buildRoleSection('uye', uyeler),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2))
      ]),
      child: Column(
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
      ),
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
    final isMain = p.anaHesap == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _profilSecildi(p),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: theme.gradient),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: theme.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]),
                  child: Center(
                      child: Text(_getInitials(displayName),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: isMain
                                      ? const Color(0xFF10B981)
                                          .withValues(alpha: 0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(isMain ? 'Ana Hesap' : 'Bağlı Hesap',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isMain
                                          ? const Color(0xFF10B981)
                                          : Colors.grey.shade600))),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                    color: Colors.grey.shade100, shape: BoxShape.circle),
                child: Icon(Icons.person_search_rounded,
                    size: 40, color: Colors.grey.shade400)),
            const SizedBox(height: 24),
            const Text('Profil bulunamadı',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text(
                'Kullanıcınıza ait herhangi bir profil bulunmuyor.\nBir yanlışlık olduğunu düşünüyorsanız\nlütfen iletişime geçin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, height: 1.5, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            if (Navigator.of(context).canPop())
              TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Geri Dön'),
                  style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF475569),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)))),
          ],
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
  const _RolTheme(
      {required this.icon,
      required this.color,
      required this.gradient,
      required this.label});
}
