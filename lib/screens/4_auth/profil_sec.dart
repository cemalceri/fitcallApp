// ignore_for_file: use_build_context_synchronously
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFlow());
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

    // Grupları sabit sırayla göster (Yönetici → Antrenör → Üye → Kafe → diğer);
    // her grup içinde profilleri ada göre alfabetik sırala. Aksi halde gruplar
    // en son eklenen veriye göre rastgele sırada geliyordu.
    const rolSirasi = ['yonetici', 'antrenor', 'uye', 'cafe'];
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

    final isEmpty = widget.kullaniciProfilList.isEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 8),
              if (isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 80,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Profil Bulunamadı',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mevcut profil yok',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => AuthService.logout(context),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Çıkış Yap'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: siraliRoller
                        .map((rol) =>
                            _buildRoleSection(rol, groupedProfiles[rol]!))
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
                tooltip: 'Geri',
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: Theme.of(context).colorScheme.onSurface),
              ),
            if (!Navigator.of(context).canPop()) const SizedBox(width: 16),
            Expanded(
              child: Text('Profil Seç',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.3)),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 4),
          child: Text('Devam etmek için bir profil seçin',
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
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
                child: Icon(theme.icon, size: 18, color: theme.color),
              ),
              const SizedBox(width: 10),
              Text(theme.label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(width: 12),
              Expanded(
                  child: Container(
                      height: 1,
                      color: Theme.of(context).colorScheme.outlineVariant)),
            ],
          ),
          const SizedBox(height: 16),
          ...profiles.map((p) => _buildProfileCard(p, theme)),
        ],
      ),
    );
  }

  Widget _buildAltBilgi(KullaniciProfilModel p, _RolTheme theme) {
    final isletme = p.isletmeAdi;
    // İşletme adı varsa onu göster (asıl ayırt edici bilgi). Rol zaten üstteki
    // bölüm başlığında. İşletme boşsa role geri düş.
    if (isletme == null || isletme.isEmpty) {
      return Text(theme.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.storefront_outlined, size: 13, color: theme.color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(isletme,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.color)),
        ),
      ],
    );
  }

  String _profilAdi(KullaniciProfilModel p) {
    final ad = p.uye?.adi ?? p.antrenor?.adi ?? p.user.firstName;
    final soy = p.uye?.soyadi ?? p.antrenor?.soyadi ?? p.user.lastName;
    final tamAd = '$ad $soy'.trim();
    return tamAd.isEmpty ? p.user.username : tamAd;
  }

  Widget _buildProfileCard(KullaniciProfilModel p, _RolTheme theme) {
    final displayName = _profilAdi(p);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.withValues(alpha: 0.10)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
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
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: theme.color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Icon(theme.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.2)),
                      const SizedBox(height: 3),
                      // Alt satır: işletme adı (birden çok işletmede aynı
                      // isim/rol ayırt edilebilsin). İşletme yoksa role düşer.
                      _buildAltBilgi(p, theme),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
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
  _RolTheme(
      {required this.icon,
      required this.color,
      required this.gradient,
      required this.label});
}
