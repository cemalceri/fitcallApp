// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:fitcall/common/api_urls.dart'; // getAnnouncements, getNotifications, getGaleriImages tanımlı olsun
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/1_common/1_notification/notifications_bell.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/models/1_common/duyuru_model.dart';
import 'package:fitcall/screens/1_common/2_fotograf/full_screen_image_page.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AntrenorHomePage extends StatefulWidget {
  const AntrenorHomePage({super.key});

  @override
  State<AntrenorHomePage> createState() => _AntrenorHomePageState();
}

class _AntrenorHomePageState extends State<AntrenorHomePage> {
  // Menü elemanları
  final List<Map<String, dynamic>> menuItems = [
    {'name': '/antrenor_profil', 'icon': Icons.person, 'text': 'Bilgilerim'},
    {
      'name': '/antrenor_dersler',
      'icon': Icons.sports_tennis,
      'text': 'Derslerim'
    },
    {
      'name': '/antrenor_ogrenciler',
      'icon': Icons.group,
      'text': 'Öğrencilerim'
    },
    {
      'name': routeEnums[SayfaAdi.qrKodKayit]!,
      'icon': Icons.qr_code,
      'text': 'QR Kod İle Giriş'
    },
    {
      'name': routeEnums[SayfaAdi.qrKodDogrula]!,
      'icon': Icons.qr_code_2,
      'text': 'QR Kod Doğrula'
    },
  ];

  // Django backend'den gelen duyuruları tutacak Future
  late Future<List<AnnouncementModel>> _announcementsFuture;
  // Galeri resimlerini tutacak Future
  late Future<List<String>> _galleryImagesFuture;

  @override
  void initState() {
    super.initState();
    _announcementsFuture = fetchAnnouncements();
    _galleryImagesFuture = fetchGalleryImages();
  }

  // Django API'den duyuruları çekiyoruz
  Future<List<AnnouncementModel>> fetchAnnouncements() async {
    try {
      String? token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse(getDuyurular),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return List<AnnouncementModel>.from(
            decoded.map((e) => AnnouncementModel.fromJson(e)));
      } else {
        ShowMessage.error(
            context, 'Duyurular alınamadı ${response.statusCode}');
        return [];
      }
    } catch (e) {
      ShowMessage.error(context, 'Duyurular alınamadı.');
      return [];
    }
  }

  // Django /gallery/ endpoint'ine POST isteği atarak resim URL'lerini çekiyoruz
  Future<List<String>> fetchGalleryImages() async {
    try {
      String? token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse(getGaleriImages),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return List<String>.from(decoded.map((e) => e["url"]));
      } else {
        ShowMessage.error(
            context, 'Hata: Galeri resimleri alınamadı ${response.statusCode}');
        return [];
      }
    } catch (e) {
      ShowMessage.error(context, 'Hata: Galeri resimleri alınamadı.');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrenör Ana Sayfası'),
        actions: [
          const NotificationsBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService.logout(context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Text(
                'Menü',
                style: TextStyle(color: Colors.white, fontSize: 28),
              ),
            ),
            // Menü elemanları
            ...menuItems.map((item) {
              return ListTile(
                leading: Icon(item['icon']),
                title: Text(item['text']),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, item['name']);
                },
              );
            }),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Üst Banner / Hoş Geldiniz Mesajı
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.lightBlueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Hoş Geldiniz!',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Güncel duyuruları ve galeriyi inceleyin.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Duyurular Bölümü
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Icon(Icons.announcement, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Duyurular',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<AnnouncementModel>>(
              future: _announcementsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Hiç duyuru bulunamadı'));
                }
                final announcements = snapshot.data!;
                return SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.9),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = announcements[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          onTap: () {
                            // Duyuruya tıklandığında yapılacak işlemler
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    announcement.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    announcement.subtitle,
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    announcement.content,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Resim Galerisi Bölümü
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Icon(Icons.photo_album, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Resim Galerisi',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<String>>(
              future: _galleryImagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Hiç resim bulunamadı'));
                }
                final galleryImages = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: galleryImages.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          showFullScreenImage(context, galleryImages[index]);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            galleryImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, error, stackTrace) {
                              return const Center(
                                  child: Text("Resim yüklenemedi"));
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
