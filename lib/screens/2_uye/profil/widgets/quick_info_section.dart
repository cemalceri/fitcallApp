import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuickInfoSection extends StatelessWidget {
  final UyeModel uye;
  final Color seviyeRenk;

  const QuickInfoSection({
    super.key,
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
