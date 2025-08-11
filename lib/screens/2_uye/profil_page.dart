import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/models/2_uye/uye_urun_list_page.dart';
import 'package:fitcall/screens/4_auth/login_page.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:flutter/material.dart';

/// Ana “Profil” ekranı – ayarlar menüsü stili (deep-link)
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UyeModel?>(
      future: AuthService.uyeBilgileriniGetir(),
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
                // -------------- YENİ: Liste sayfasına gider ------------------
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UyeUrunListPage()),
                ),
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
/* _ProfileHeader, _ProfileTile, _ProfileDetailPage, ProfileInfoRow            */
/*            – Aşağıda değişiklik yok, TAMAMI olduğu gibi –                  */

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
