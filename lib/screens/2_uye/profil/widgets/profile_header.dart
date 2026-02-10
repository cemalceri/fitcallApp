import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final UyeModel uye;
  final Color seviyeRenk;

  const ProfileHeader({
    super.key,
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
