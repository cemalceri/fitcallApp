// lib/screens/yonetici/yonetici_home_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/1_common/1_notification/notifications_bell.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:fitcall/services/core/notification_service.dart';
import 'package:flutter/material.dart';

class YoneticiHomePage extends StatefulWidget {
  const YoneticiHomePage({super.key});

  @override
  State<YoneticiHomePage> createState() => _YoneticiHomePageState();
}

class _YoneticiHomePageState extends State<YoneticiHomePage> {
  /* ---------------- Üst Menü (AntrenorHomePage ile aynı grid yapısı) ---------------- */
  final List<Map<String, dynamic>> menuItems = [
    {
      'name': routeEnums[SayfaAdi.qrKodKayit]!,
      'icon': Icons.qr_code,
      'text': 'QR Kod Oluştur',
    },
    {
      'name': routeEnums[SayfaAdi.qrKodDogrula]!,
      'icon': Icons.qr_code_2,
      'text': 'QR Kod Doğrula',
    },
  ];

  // İleride isim göstermek istersek doldururuz (örn. StorageService/Profil servisi).
  String _yoneticiAdi = "";

  @override
  void initState() {
    super.initState();
    NotificationService.refreshUnreadCount();
    _loadYoneticiAdi();
  }

  Future<void> _loadYoneticiAdi() async {
    // Not: Projede yöneticinin adı için net bir Storage/Service metodu verilmedi.
    // İlerde eklenince burada set edilecek. Şimdilik boş string kalsın.
    setState(() => _yoneticiAdi = "");
  }

  @override
  Widget build(BuildContext context) {
    final hosgeldinText = _yoneticiAdi.isEmpty
        ? "Hoşgeldiniz 🎾"
        : "Hoşgeldiniz $_yoneticiAdi 🎾";

    return Scaffold(
      appBar: AppBar(
        actions: [
          const NotificationsBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hosgeldinText,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Üst menü (AntrenorHomePage ile aynı grid)
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: menuItems.map(_buildMenuButton).toList(),
            ),

            const SizedBox(height: 24),

            // Hızlı QR İşlemleri kartı (AntrenorHomePage "Bir Sonraki Ders" kartına benzer yapı)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          const Icon(Icons.qr_code_scanner, color: Colors.blue),
                      title: const Text("Hızlı QR İşlemleri"),
                      subtitle: const Text(
                          "Etkinlik/içeri giriş için hızlıca QR üretin veya okutun."),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                                context, routeEnums[SayfaAdi.qrKodKayit]!),
                            icon: const Icon(Icons.qr_code),
                            label: const Text("QR Oluştur"),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                                context, routeEnums[SayfaAdi.qrKodDogrula]!),
                            icon: const Icon(Icons.qr_code_2),
                            label: const Text("QR Doğrula"),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bilgi kartı: süreç/akış açıklaması (kısa)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: Icon(Icons.info_outline, color: Colors.blueGrey),
                title: Text("İpucu"),
                subtitle: Text(
                    "Oluşturduğunuz QR’ı girişte okutun. Doğrulama ekranı, kodun geçerliliğini anında gösterir."),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* --------------------- Görsel iyileştirmeler (AntrenorHomePage ile aynı stil) --------------------- */
  Widget _buildMenuButton(Map<String, dynamic> item) => Padding(
        padding: const EdgeInsets.all(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, item['name']),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item['icon'], size: 34, color: Colors.blueAccent),
                const SizedBox(height: 6),
                Text(
                  item['text'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
}
