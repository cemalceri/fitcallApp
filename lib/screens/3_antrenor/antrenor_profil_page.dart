// lib/screens/3_antrenor/antrenor_profil_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/3_antrenor/antrenor_model.dart';
import 'package:fitcall/screens/3_antrenor/calisma_saatleri/calisma_saatleri_page.dart';
import 'package:fitcall/screens/4_auth/login_page.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AntrenorProfilPage extends StatelessWidget {
  const AntrenorProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AntrenorModel?>(
      future: StorageService.antrenorBilgileriniGetir(),
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
              child: const IskeletKart(),
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

        return _AntrenorProfilContent(antrenor: snapshot.data!);
      },
    );
  }
}

class _AntrenorProfilContent extends StatelessWidget {
  final AntrenorModel antrenor;

  const _AntrenorProfilContent({required this.antrenor});

  Color _colorFromHex(String? hex, {Color fallback = Colors.blueGrey}) {
    if (hex == null) return fallback;
    final s = hex.replaceFirst('#', '').trim();
    try {
      if (s.length == 6) return Color(int.parse('FF$s', radix: 16));
      if (s.length == 8) return Color(int.parse(s, radix: 16));
    } catch (_) {}
    return fallback;
  }

  static String _fmtDt(DateTime dt) {
    final d = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final antrenorRenk =
        _colorFromHex(antrenor.renk, fallback: colorScheme.primary);

    // Kabuk sekmesi olarak açıldığında geri okunun gideceği yer yok.
    final geriVar = Navigator.of(context).canPop();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            automaticallyImplyLeading: geriVar,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            title: Text('${antrenor.adi} ${antrenor.soyadi}'),
            actions: [
              IconButton(
                tooltip: 'Ayarlar',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () =>
                    Navigator.pushNamed(context, routeEnums[SayfaAdi.ayarlar]!),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              background: _ProfileHeader(
                antrenor: antrenor,
                antrenorRenk: antrenorRenk,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusBadge(
                        label: antrenor.isActive ? 'Aktif' : 'Pasif',
                        color: antrenor.isActive
                            ? context.renkler.basari
                            : context.renkler.hata,
                        icon: antrenor.isActive
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                      ),
                      _StatusBadge(
                        label: 'Antrenör',
                        color: antrenorRenk,
                        icon: Icons.sports_tennis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _QuickInfoSection(
                    antrenor: antrenor,
                    antrenorRenk: antrenorRenk,
                  ),
                  const SizedBox(height: 24),
                  _MenuSection(
                    antrenor: antrenor,
                    antrenorRenk: antrenorRenk,
                    formatDate: _fmtDt,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Profile Header                                */
/* -------------------------------------------------------------------------- */

class _ProfileHeader extends StatelessWidget {
  final AntrenorModel antrenor;
  final Color antrenorRenk;

  const _ProfileHeader({
    required this.antrenor,
    required this.antrenorRenk,
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
            antrenorRenk.withValues(alpha: 0.22),
            colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: antrenorRenk.withValues(alpha: 0.35),
                ),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surface,
                  ),
                  child: ClipOval(
                    child: antrenor.profileImageUrl != null &&
                            antrenor.profileImageUrl!.trim().isNotEmpty
                        ? Image(
                            image: CachedNetworkImageProvider(
                                antrenor.profileImageUrl!.trim()),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildAvatarPlaceholder(colorScheme),
                          )
                        : _buildAvatarPlaceholder(colorScheme),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${antrenor.adi} ${antrenor.soyadi}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (antrenor.ePosta != null || antrenor.telefon != null)
                      Text(
                        antrenor.ePosta ?? antrenor.telefon ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildAvatarPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          '${antrenor.adi[0]}${antrenor.soyadi[0]}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: antrenorRenk,
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
  final AntrenorModel antrenor;
  final Color antrenorRenk;

  const _QuickInfoSection({
    required this.antrenor,
    required this.antrenorRenk,
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
            value: antrenor.telefon ?? 'Belirtilmedi',
            color: antrenorRenk,
            onTap: antrenor.telefon != null
                ? () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: antrenor.telefon!));
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
            value: antrenor.ePosta ?? 'Belirtilmedi',
            color: colorScheme.secondary,
            onTap: antrenor.ePosta != null
                ? () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: antrenor.ePosta!));
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
  final AntrenorModel antrenor;
  final Color antrenorRenk;
  final String Function(DateTime) formatDate;

  const _MenuSection({
    required this.antrenor,
    required this.antrenorRenk,
    required this.formatDate,
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
              subtitle: 'Ad, soyad ve hesap detayları',
              color: antrenorRenk,
              onTap: () => _showDetailSheet(
                context,
                title: 'Genel Bilgiler',
                icon: Icons.badge_outlined,
                color: antrenorRenk,
                items: [
                  _DetailItem(
                      'Adı Soyadı', '${antrenor.adi} ${antrenor.soyadi}'),
                  _DetailItem('Durum', antrenor.isActive ? 'Aktif' : 'Pasif'),
                  _DetailItem('Kayıt Tarihi', formatDate(antrenor.createdAt)),
                ],
              ),
            ),
            _ModernMenuTile(
              icon: Icons.contact_phone_outlined,
              title: 'İletişim Bilgileri',
              subtitle: 'Telefon ve e-posta',
              color: Colors.teal,
              onTap: () => _showDetailSheet(
                context,
                title: 'İletişim Bilgileri',
                icon: Icons.contact_phone_outlined,
                color: Colors.teal,
                items: [
                  _DetailItem('Telefon', antrenor.telefon ?? 'Belirtilmedi'),
                  _DetailItem('E-posta', antrenor.ePosta ?? 'Belirtilmedi'),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Hesap
        _SectionTitle(title: 'Hesap', icon: Icons.settings_outlined),
        const SizedBox(height: 12),
        _MenuCard(
          children: [
            _ModernMenuTile(
              icon: Icons.schedule_rounded,
              title: 'Çalışma Saatlerim',
              subtitle: 'Haftalık uygunluk saatleri',
              color: context.renkler.bilgi,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CalismaSaatleriPage(),
                ),
              ),
            ),
            // Şifre değiştirme, KVKK, bildirim izni ve hesap silme Ayarlar
            // sayfasında toplandı; üye tarafıyla aynı sayfa kullanılıyor.
            _ModernMenuTile(
              icon: Icons.settings_outlined,
              title: 'Ayarlar',
              subtitle: 'Tema, bildirimler, şifre ve hesap',
              color: colorScheme.primary,
              onTap: () =>
                  Navigator.pushNamed(context, routeEnums[SayfaAdi.ayarlar]!),
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

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayColor = colorScheme.primary;

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

  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
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

  const _ModernMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
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
                        color: colorScheme.onSurface,
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
