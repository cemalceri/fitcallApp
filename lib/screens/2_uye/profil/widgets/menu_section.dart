import 'package:fitcall/common/routes.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/screens/2_uye/profil/widgets/telafi_haklari_page.dart';
import 'package:fitcall/screens/2_uye/widgets/uye_urun_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MenuSection extends StatelessWidget {
  final UyeModel uye;
  final Color seviyeRenk;

  const MenuSection({
    super.key,
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
              color: context.renkler.bilgi,
              onTap: () => _showDetailSheet(
                context,
                title: 'İletişim Bilgileri',
                icon: Icons.contact_phone_outlined,
                color: context.renkler.bilgi,
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
              color: context.renkler.uyari,
              onTap: () => _showDetailSheet(
                context,
                title: 'Veli / Acil Durum',
                icon: Icons.family_restroom_outlined,
                color: context.renkler.uyari,
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
              color: context.renkler.basari,
              onTap: () => _showDetailSheet(
                context,
                title: 'Tenis Tercihi',
                icon: Icons.sports_tennis_outlined,
                color: context.renkler.basari,
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
              color: colorScheme.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UyeUrunListPage()),
              ),
            ),
            _ModernMenuTile(
              icon: Icons.event_repeat_rounded,
              title: 'Telafi Haklarım',
              subtitle: 'Telafi dersleri ve kullanım durumu',
              color: context.renkler.bilgi,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TelafiHaklariPage()),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Ayarlar — şifre, KVKK, bildirim izni, tema ve hesap silme tek
        // sayfada toplandı; profil ekranı kişisel bilgide kalıyor.
        _MenuCard(
          children: [
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

// Helper Widgets
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = Theme.of(context).colorScheme.primary;

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

// ChangePasswordPage ve DeleteUserAccountPage import edilmeli
// Bunlar profile_page.dart'ta zaten tanımlı, oradan kullanılabilir
