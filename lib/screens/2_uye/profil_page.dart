// lib/screens/2_uye/profile_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/screens/1_common/widgets/kvkk.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/2_uye/widgets/uye_urun_list_page.dart';
import 'package:fitcall/screens/4_auth/login_page.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/uye/uye_api_serivce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Seviye renk haritası
  static const Map<String, Color> seviyeRenkleri = {
    'Kirmizi': Color(0xFFE53935),
    'Turuncu': Color(0xFFFF9800),
    'Sari': Color(0xFFFFEB3B),
    'Yesil': Color(0xFF4CAF50),
    'Mavi': Color(0xFF2196F3),
  };

  Color _getSeviyeColor(String seviye) {
    return seviyeRenkleri[seviye] ?? Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UyeModel?>(
      future: StorageService.uyeBilgileriniGetir(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bir hata oluştu',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.data == null) {
          return const LoginPage();
        }

        return _ProfileContent(
          uye: snapshot.data!,
          getSeviyeColor: _getSeviyeColor,
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final UyeModel uye;
  final Color Function(String) getSeviyeColor;

  const _ProfileContent({
    required this.uye,
    required this.getSeviyeColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final seviyeRenk = getSeviyeColor(uye.seviyeRengi);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              seviyeRenk.withValues(alpha: 0.08),
              colorScheme.surface,
              colorScheme.secondary.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Modern SliverAppBar
            SliverAppBar(
              expandedHeight: 340,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _ProfileHeader(
                  uye: uye,
                  seviyeRenk: seviyeRenk,
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),

            // İçerik
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Hızlı Bilgi Kartları
                    _QuickInfoSection(uye: uye, seviyeRenk: seviyeRenk),

                    const SizedBox(height: 24),

                    // Menü Bölümü
                    _MenuSection(uye: uye, seviyeRenk: seviyeRenk),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Profile Header                                */
/* -------------------------------------------------------------------------- */

class _ProfileHeader extends StatelessWidget {
  final UyeModel uye;
  final Color seviyeRenk;

  const _ProfileHeader({
    required this.uye,
    required this.seviyeRenk,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            seviyeRenk.withValues(alpha: 0.3),
            seviyeRenk.withValues(alpha: 0.1),
            colorScheme.surface,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              // Avatar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      seviyeRenk,
                      seviyeRenk.withValues(alpha: 0.6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: seviyeRenk.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surface,
                  ),
                  child: ClipOval(
                    child: uye.profilFotografi != null &&
                            uye.profilFotografi!.isNotEmpty
                        ? Image.network(
                            uye.profilFotografi!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildAvatarPlaceholder(colorScheme),
                          )
                        : _buildAvatarPlaceholder(colorScheme),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // İsim
              Text(
                '${uye.adi} ${uye.soyadi}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 6),

              // Üye No
              Text(
                'Üye No: ${uye.uyeNo}',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 12),

              // Durum Badge'leri
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusBadge(
                    label: uye.aktifMi ? 'Aktif' : 'Pasif',
                    color: uye.aktifMi ? Colors.green : Colors.red,
                    icon: uye.aktifMi
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                  ),
                  _StatusBadge(
                    label: uye.seviyeRengi,
                    color: seviyeRenk,
                    icon: Icons.sports_tennis,
                  ),
                  if (uye.onaylandiMi)
                    _StatusBadge(
                      label: 'Onaylı',
                      color: Colors.blue,
                      icon: Icons.verified_outlined,
                    ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          '${uye.adi[0]}${uye.soyadi[0]}',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: seviyeRenk,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
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

/* -------------------------------------------------------------------------- */
/*                            Quick Info Section                              */
/* -------------------------------------------------------------------------- */

class _QuickInfoSection extends StatelessWidget {
  final UyeModel uye;
  final Color seviyeRenk;

  const _QuickInfoSection({
    required this.uye,
    required this.seviyeRenk,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _QuickInfoCard(
            icon: Icons.phone_outlined,
            label: 'Telefon',
            value: uye.telefon ?? 'Belirtilmedi',
            color: seviyeRenk,
            onTap: uye.telefon != null
                ? () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: uye.telefon!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Telefon kopyalandı'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickInfoCard(
            icon: Icons.email_outlined,
            label: 'E-posta',
            value: uye.email ?? 'Belirtilmedi',
            color: colorScheme.secondary,
            onTap: uye.email != null
                ? () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: uye.email!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('E-posta kopyalandı'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

class _QuickInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _QuickInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (onTap != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.copy_rounded,
                      size: 12,
                      color: color.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Kopyala',
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Menu Section                                  */
/* -------------------------------------------------------------------------- */

class _MenuSection extends StatelessWidget {
  final UyeModel uye;
  final Color seviyeRenk;

  const _MenuSection({
    required this.uye,
    required this.seviyeRenk,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profil Bilgileri
        _SectionTitle(title: 'Profil Bilgileri', icon: Icons.person_outline),
        const SizedBox(height: 12),
        _MenuCard(
          children: [
            _ModernMenuTile(
              icon: Icons.badge_outlined,
              title: 'Genel Bilgiler',
              subtitle: 'Ad, soyad ve üyelik detayları',
              color: seviyeRenk,
              onTap: () => _showDetailSheet(
                context,
                title: 'Genel Bilgiler',
                icon: Icons.badge_outlined,
                color: seviyeRenk,
                items: [
                  _DetailItem('Adı Soyadı', '${uye.adi} ${uye.soyadi}'),
                  _DetailItem('Üye Numarası', uye.uyeNo.toString()),
                  _DetailItem('Üye Türü', uye.uyeTuru),
                  _DetailItem('Seviye', uye.seviyeRengi),
                  _DetailItem('Durum', uye.aktifMi ? 'Aktif' : 'Pasif'),
                  _DetailItem('Onay', uye.onaylandiMi ? 'Onaylı' : 'Bekliyor'),
                ],
              ),
            ),
            _ModernMenuTile(
              icon: Icons.contact_phone_outlined,
              title: 'İletişim Bilgileri',
              subtitle: 'Telefon, e-posta ve adres',
              color: Colors.teal,
              onTap: () => _showDetailSheet(
                context,
                title: 'İletişim Bilgileri',
                icon: Icons.contact_phone_outlined,
                color: Colors.teal,
                items: [
                  _DetailItem('Telefon', uye.telefon ?? 'Belirtilmedi'),
                  _DetailItem('E-posta', uye.email ?? 'Belirtilmedi'),
                  _DetailItem('Adres',
                      uye.adres.isNotEmpty ? uye.adres : 'Belirtilmedi'),
                ],
              ),
            ),
            _ModernMenuTile(
              icon: Icons.family_restroom_outlined,
              title: 'Veli / Acil Durum',
              subtitle: 'Aile ve acil durum bilgileri',
              color: Colors.purple,
              onTap: () => _showDetailSheet(
                context,
                title: 'Veli / Acil Durum',
                icon: Icons.family_restroom_outlined,
                color: Colors.purple,
                items: [
                  _DetailItem(
                      'Acil Durum Kişi', uye.acilDurumKisi ?? 'Belirtilmedi'),
                  _DetailItem(
                      'Acil Durum Tel', uye.acilDurumTelefon ?? 'Belirtilmedi'),
                  _DetailItem('Anne Adı', uye.anneAdiSoyadi ?? 'Belirtilmedi'),
                  _DetailItem('Anne Tel', uye.anneTelefon ?? 'Belirtilmedi'),
                  _DetailItem('Baba Adı', uye.babaAdiSoyadi ?? 'Belirtilmedi'),
                  _DetailItem('Baba Tel', uye.babaTelefon ?? 'Belirtilmedi'),
                ],
              ),
            ),
            _ModernMenuTile(
              icon: Icons.sports_tennis_outlined,
              title: 'Tenis Tercihi',
              subtitle: 'Program ve hoca bilgileri',
              color: Colors.green,
              onTap: () => _showDetailSheet(
                context,
                title: 'Tenis Tercihi',
                icon: Icons.sports_tennis_outlined,
                color: Colors.green,
                items: [
                  _DetailItem(
                      'Tenis Geçmişi', uye.tenisGecmisiVarMi ?? 'Belirtilmedi'),
                  _DetailItem(
                      'Program Tercihi', uye.programTercihi ?? 'Belirtilmedi'),
                  _DetailItem('Sorumlu Hoca',
                      uye.sorumluHoca?.toString() ?? 'Belirtilmedi'),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Üyelik Bilgileri
        _SectionTitle(title: 'Üyelik', icon: Icons.card_membership_outlined),
        const SizedBox(height: 12),
        _MenuCard(
          children: [
            _ModernMenuTile(
              icon: Icons.calendar_today_outlined,
              title: 'Üyelik/Paket Bilgilerim',
              subtitle: 'Aktif paketler ve üyelikler',
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UyeUrunListPage()),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Ayarlar
        _SectionTitle(title: 'Ayarlar', icon: Icons.settings_outlined),
        const SizedBox(height: 12),
        _MenuCard(
          children: [
            _ModernMenuTile(
              icon: Icons.lock_reset_rounded,
              title: 'Şifreyi Değiştir',
              subtitle: 'Hesap güvenliği',
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
              ),
            ),
            _ModernMenuTile(
              icon: Icons.privacy_tip_outlined,
              title: 'KVKK Aydınlatma Metni',
              subtitle: 'Veri işleme ve saklama bilgileri',
              color: Colors.blue,
              onTap: () => showKvkkAydinlatmaModal(context),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Tehlikeli Bölge
        _SectionTitle(
          title: 'Tehlikeli Bölge',
          icon: Icons.warning_amber_rounded,
          color: colorScheme.error,
        ),
        const SizedBox(height: 12),
        _MenuCard(
          borderColor: colorScheme.error.withValues(alpha: 0.2),
          children: [
            _ModernMenuTile(
              icon: Icons.delete_forever_rounded,
              title: 'Hesabı Kalıcı Sil',
              subtitle: 'Tüm verilerin kaldırılması',
              color: colorScheme.error,
              isDestructive: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DeleteUserAccountPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDetailSheet(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<_DetailItem> items,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetailSheet(
        title: title,
        icon: icon,
        color: color,
        items: items,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;

  const _SectionTitle({
    required this.title,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayColor = color ?? colorScheme.primary;

    return Row(
      children: [
        Icon(icon, size: 20, color: displayColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: displayColor,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  final Color? borderColor;

  const _MenuCard({
    required this.children,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              borderColor ?? colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: children.asMap().entries.map((entry) {
            final isLast = entry.key == children.length - 1;
            return Column(
              children: [
                entry.value,
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 72,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ModernMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ModernMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive
                            ? colorScheme.error
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Detail Sheet                                  */
/* -------------------------------------------------------------------------- */

class _DetailItem {
  final String label;
  final String value;

  _DetailItem(this.label, this.value);
}

class _DetailSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_DetailItem> items;

  const _DetailSheet({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 24),

                // Items
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: items.asMap().entries.map((entry) {
                      final isLast = entry.key == items.length - 1;
                      final item = entry.value;

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    item.value,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Kapat'),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                           Change Password Page                             */
/* -------------------------------------------------------------------------- */

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _eskiCtrl = TextEditingController();
  final _yeniCtrl = TextEditingController();
  final _yeni2Ctrl = TextEditingController();
  bool _showOld = false, _showNew = false, _showNew2 = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _eskiCtrl.dispose();
    _yeniCtrl.dispose();
    _yeni2Ctrl.dispose();
    super.dispose();
  }

  String? _validateNew(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Yeni şifre zorunludur.';
    if (s.length < 8) return 'En az 8 karakter olmalı.';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'[0-9]').hasMatch(s)) {
      return 'Harf ve rakam içermeli.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_yeniCtrl.text != _yeni2Ctrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Yeni şifreler eşleşmiyor.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await UyeApiService.kullaniciSifreDegistir(
        eskiSifre: _eskiCtrl.text.trim(),
        yeniSifre: _yeniCtrl.text.trim(),
      );

      ShowMessage.success(
        context,
        res.mesaj.isNotEmpty ? res.mesaj : 'Şifreniz başarıyla değiştirildi.',
      );
      AuthService.logout(context);
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } catch (e) {
      ShowMessage.error(context, 'Hata: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.withValues(alpha: 0.1),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Şifreyi Değiştir',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            size: 48,
                            color: Colors.orange,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Form Fields
                        _ModernTextField(
                          controller: _eskiCtrl,
                          label: 'Mevcut Şifre',
                          obscureText: !_showOld,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _showOld = !_showOld),
                            icon: Icon(_showOld
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Zorunlu alan.' : null,
                        ),

                        const SizedBox(height: 16),

                        _ModernTextField(
                          controller: _yeniCtrl,
                          label: 'Yeni Şifre',
                          obscureText: !_showNew,
                          prefixIcon: Icons.lock_rounded,
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _showNew = !_showNew),
                            icon: Icon(_showNew
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                          validator: _validateNew,
                        ),

                        const SizedBox(height: 16),

                        _ModernTextField(
                          controller: _yeni2Ctrl,
                          label: 'Yeni Şifre (Tekrar)',
                          obscureText: !_showNew2,
                          prefixIcon: Icons.lock_rounded,
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _showNew2 = !_showNew2),
                            icon: Icon(_showNew2
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Zorunlu alan.' : null,
                        ),

                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Şifreyi Değiştir',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _ModernTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    required this.prefixIcon,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                           Delete Account Page                              */
/* -------------------------------------------------------------------------- */

class DeleteUserAccountPage extends StatefulWidget {
  const DeleteUserAccountPage({super.key});

  @override
  State<DeleteUserAccountPage> createState() => _DeleteUserAccountPageState();
}

class _DeleteUserAccountPageState extends State<DeleteUserAccountPage> {
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed => _confirmCtrl.text.trim().toLowerCase() == 'sil';

  Future<void> _performDelete() async {
    setState(() => _isLoading = true);
    try {
      final res = await UyeApiService.kullaniciSil();
      await StorageService.clearAll();

      ShowMessage.success(
        context,
        res.mesaj.isNotEmpty
            ? res.mesaj
            : 'Kullanıcınız kalıcı olarak silindi.',
      );
      AuthService.logout(context);
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } catch (e) {
      ShowMessage.error(context, 'Silme başarısız: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFinalSheet() {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 48,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bu işlem geri alınamaz!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hesabın ve ilişkili kişisel verilerin kalıcı olarak silinecek. '
                    'Mevzuat gereği saklanması zorunlu kayıtlar varsa, kişisel bağın koparılarak anonimleştirilir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Vazgeç'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  _performDelete();
                                },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: colorScheme.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Evet, Kalıcı Sil'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.error.withValues(alpha: 0.08),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hesabı Kalıcı Sil',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Warning Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 56,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Dikkat!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _WarningPoint(
                              text: 'Bu işlem geri alınamaz.',
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 8),
                            _WarningPoint(
                              text:
                                  'Tüm profil verilerin ve uygulama içi içeriklerin kaldırılacaktır.',
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 8),
                            _WarningPoint(
                              text:
                                  'Mevzuat gereği saklanması zorunlu finansal kayıtlar anonimleştirilebilir.',
                              color: colorScheme.error,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Confirmation Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Onay',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Devam etmek için aşağıya "sil" yazın.',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _confirmCtrl,
                              textCapitalization: TextCapitalization.none,
                              decoration: InputDecoration(
                                hintText: 'sil',
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: colorScheme.error,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Vazgeç'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _canProceed && !_isLoading
                                        ? _showFinalSheet
                                        : null,
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      backgroundColor: _canProceed
                                          ? colorScheme.error
                                          : colorScheme.error
                                              .withValues(alpha: 0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Hesabı Sil'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningPoint extends StatelessWidget {
  final String text;
  final Color color;

  const _WarningPoint({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
