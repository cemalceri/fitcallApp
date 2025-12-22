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

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UyeModel?>(
      future: StorageService.uyeBilgileriniGetir(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Bir hata oluştu: ${snapshot.error}')),
          );
        } else if (snapshot.data == null) {
          return const LoginPage();
        }

        final uye = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('Profil')),
          body: ListView(
            children: [
              _ProfileHeader(uye: uye),
              const Divider(),
              _ProfileTile(
                icon: Icons.person,
                title: 'Genel Bilgiler',
                onTap: () => _navigate(
                  context,
                  title: 'Genel Bilgiler',
                  data: {
                    'Adı Soyadı': '${uye.adi} ${uye.soyadi}',
                    'Üye Numarası': uye.uyeNo.toString(),
                    'Üye Türü': uye.uyeTuru,
                    'Seviye': uye.seviyeRengi,
                    'Aktiflik': uye.aktifMi ? 'Aktif' : 'Pasif',
                    'Onay Durumu': uye.onaylandiMi ? 'Onaylı' : 'Bekliyor',
                  },
                ),
              ),
              _ProfileTile(
                icon: Icons.phone,
                title: 'İletişim',
                onTap: () => _navigate(
                  context,
                  title: 'İletişim',
                  data: {
                    'Telefon': uye.telefon ?? '-',
                    'Mail': uye.email ?? '-',
                    'Adres': uye.adres,
                  },
                ),
              ),
              _ProfileTile(
                icon: Icons.family_restroom,
                title: 'Veli / Acil Durum',
                onTap: () => _navigate(
                  context,
                  title: 'Veli / Acil Durum',
                  data: {
                    'Acil Durum Kişi': uye.acilDurumKisi ?? '-',
                    'Acil Durum Tel': uye.acilDurumTelefon ?? '-',
                    'Anne Adı': uye.anneAdiSoyadi ?? '-',
                    'Anne Tel': uye.anneTelefon ?? '-',
                    'Baba Adı': uye.babaAdiSoyadi ?? '-',
                    'Baba Tel': uye.babaTelefon ?? '-',
                  },
                ),
              ),
              _ProfileTile(
                icon: Icons.sports_tennis,
                title: 'Tenis Tercihi',
                onTap: () => _navigate(
                  context,
                  title: 'Tenis Tercihi',
                  data: {
                    'Tenis Geçmişi': uye.tenisGecmisiVarMi ?? '-',
                    'Program Tercihi': uye.programTercihi ?? '-',
                    'Sorumlu Hoca': (uye.sorumluHoca?.toString() ?? '-'),
                  },
                ),
              ),
              _ProfileTile(
                icon: Icons.calendar_today,
                title: 'Üyelik / Paket Bilgilerim',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UyeUrunListPage()),
                ),
              ),
              const SizedBox(height: 8),

              // 🔽 Modern Ayarlar (yalnızca iki seçenek)
              _ProfileTile(
                icon: Icons.settings,
                title: 'Ayarlar',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Ortak ileri gitme helper’ı
  void _navigate(BuildContext ctx,
      {required String title, required Map<String, String> data}) {
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => _ProfileDetailPage(title: title, data: data),
      ),
    );
  }
}

/* ------------------------------ (alt sınıflar) ----------------------------- */

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.uye});
  final UyeModel uye;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage:
                (uye.profilFotografi != null && uye.profilFotografi!.isNotEmpty)
                    ? NetworkImage(uye.profilFotografi!)
                    : null,
            child: (uye.profilFotografi == null || uye.profilFotografi!.isEmpty)
                ? const Icon(Icons.person, size: 36)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${uye.adi} ${uye.soyadi}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Üye No: ${uye.uyeNo}',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Chip(
                  label: Text(
                    uye.seviyeRengi,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.blueGrey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ProfileDetailPage extends StatelessWidget {
  const _ProfileDetailPage({required this.title, required this.data});

  final String title;
  final Map<String, String> data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, index) {
          final key = data.keys.elementAt(index);
          final value = data[key] ?? '-';
          return ProfileInfoRow(label: key, value: value);
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: data.length,
      ),
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const ProfileInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(value),
          ),
        ),
      ],
    );
  }
}

/* ============================== AYARLAR (sade) ============================= */

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Kullanıcı Ayarları'),
          _SettingCard(
            children: [
              _SettingsTile(
                icon: Icons.lock_reset,
                title: 'Şifreyi Değiştir',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ChangePasswordPage()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.delete_forever_rounded,
                title: 'Hesabı Kalıcı Sil',
                subtitle: 'Tüm kişisel verilerin kaldırılması',
                isDestructive: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const DeleteUserAccountPage()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Gizlilik ve KVKK'),
          _SettingCard(
            children: [
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'KVKK Aydınlatma Metni',
                subtitle: 'Veri işleme ve saklama bilgileri',
                onTap: () => showKvkkAydinlatmaModal(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ==================== ŞİFRE DEĞİŞTİR SAYFASI (YENİ) ======================= */

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
    // İstersen özel karakter / büyük harf şartı da koyabilirsin.
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_yeniCtrl.text != _yeni2Ctrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni şifreler eşleşmiyor.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final res = await UyeApiService.kullaniciSifreDegistir(
        eskiSifre: _eskiCtrl.text.trim(),
        yeniSifre: _yeniCtrl.text.trim(),
      );
      if (!mounted) return;

      ShowMessage.success(
        context,
        res.mesaj.isNotEmpty ? res.mesaj : 'Şifreniz başarıyla değiştirildi.',
      );
      AuthService.logout(context);
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      ShowMessage.error(
        context,
        'Hata: $e',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifreyi Değiştir')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              TextFormField(
                controller: _eskiCtrl,
                obscureText: !_showOld,
                decoration: InputDecoration(
                  labelText: 'Mevcut Şifre',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _showOld = !_showOld),
                    icon: Icon(
                        _showOld ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Zorunlu alan.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yeniCtrl,
                obscureText: !_showNew,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _showNew = !_showNew),
                    icon: Icon(
                        _showNew ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
                validator: _validateNew,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yeni2Ctrl,
                obscureText: !_showNew2,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _showNew2 = !_showNew2),
                    icon: Icon(
                        _showNew2 ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Zorunlu alan.' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ====================== Kullanıcı HESAP SİLME SAYFASI (güncel) ====================== */

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
      await StorageService.clearAll(); // proje metoduna göre düzenleyebilirsin

      if (!mounted) return;
      ShowMessage.success(
        context,
        res.mesaj.isNotEmpty
            ? res.mesaj
            : 'Kullanıcınız kalıcı olarak silindi.',
      );

      // Login’e dön (tüm stack’i temizle)
      AuthService.logout(context);
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      ShowMessage.error(
        context,
        'Silme başarısız: $e',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFinalSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16 + 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: 8),
              const Text(
                'Bu işlem geri alınamaz.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Hesabın ve ilişkili kişisel verilerin kalıcı olarak silinecek. '
                'Mevzuat gereği saklanması zorunlu kayıtlar varsa, kişisel bağın koparılarak anonimleştirilir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
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
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : const Text('Evet, kalıcı sil'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Hesabı Kalıcı Sil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DangerCard(
            title: 'Dikkat!',
            points: const [
              'Bu işlem geri alınamaz.',
              'Tüm profil verilerin ve uygulama içi içeriklerin kaldırılacaktır.',
              'Mevzuat gereği saklanması zorunlu finansal kayıtlar anonimleştirilebilir.',
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _confirmCtrl,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    labelText: 'Onay için "sil" yazın',
                    hintText: 'sil',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Vazgeç'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _canProceed
                              ? theme.colorScheme.error
                              : theme.colorScheme.error.withAlpha(153),
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        onPressed:
                            _canProceed && !_isLoading ? _showFinalSheet : null,
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.2),
                              )
                            : const Text('Hesabı Kalıcı Sil'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================== Yardımcı bileşenler ========================== */

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: c.primary.withAlpha(230),
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cardShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: cardShape,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children
            .expand((w) => [
                  w,
                  if (w != children.last)
                    Divider(
                      height: 1,
                      thickness: 0.6,
                      indent: 56,
                      color: Colors.grey.shade200,
                    ),
                ])
            .toList(),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? Theme.of(context).colorScheme.error.withAlpha(30)
              : Theme.of(context).colorScheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? color : null,
        ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
    );
  }
}

class _DangerCard extends StatelessWidget {
  const _DangerCard({required this.title, required this.points});
  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: c.error.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.error.withAlpha(60)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: c.error, size: 36),
          const SizedBox(height: 8),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...points.map(
            (e) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.circle, size: 6),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(e)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
