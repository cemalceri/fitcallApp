import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/methods.dart';
import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/fotograf/full_screen_image_page.dart';
import 'package:fitcall/screens/widgets/notification_icon.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Menü elemanları
  final List<Map<String, dynamic>> menuItems = [
    {
      'name': routeEnums[SayfaAdi.profil]!,
      'icon': Icons.person,
      'text': 'Bilgilerim'
    },
    {
      'name': routeEnums[SayfaAdi.borcAlacak]!,
      'icon': Icons.payment,
      'text': 'Ödeme/Borç Bilgilerim'
    },
    {
      'name': routeEnums[SayfaAdi.dersler]!,
      'icon': Icons.sports_tennis,
      'text': 'Derslerim'
    },
    {
      'name': routeEnums[SayfaAdi.uyelikPaket]!,
      'icon': Icons.calendar_month,
      'text': 'Üyelik ve Paket Bilgilerim'
    },
    {
      'name': 'notifications',
      'icon': Icons.notifications,
      'text': 'Bildirimler'
    },
    {'name': 6, 'icon': Icons.help, 'text': 'Yardım'},
    {
      'name': routeEnums[SayfaAdi.qrKod]!,
      'icon': Icons.qr_code,
      'text': 'QR Kod Okut'
    },
  ];

  // Örnek duyuru verileri
  final List<Map<String, String>> announcements = [
    {
      'title': 'Önemli Duyuru',
      'subtitle': 'Öğrenciler için yeni ders programı yayınlandı.',
      'imageUrl': 'https://via.placeholder.com/300x200'
    },
    {
      'title': 'Yeni Özellik!',
      'subtitle': 'Mobil uygulamamız güncellendi, yeni özellikler eklendi.',
      'imageUrl': 'https://via.placeholder.com/300x200'
    },
  ];

  // Örnek bildirim verileri (Tarih bilgileri eklenmiştir)
  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Yeni Mesaj',
      'subtitle': 'Bir eğitmen size mesaj attı.',
      'date': DateTime.now(),
    },
    {
      'title': 'Güncelleme',
      'subtitle': 'Sistem bakım çalışması 22:00\'de başlayacak.',
      'date': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'title': 'Özel Teklif',
      'subtitle': 'Yeni indirimler sizi bekliyor.',
      'date': DateTime.now().subtract(const Duration(days: 10)),
    },
    {
      'title': 'Yorum Geldi',
      'subtitle': 'Bir gönderiniz beğenildi.',
      'date': DateTime.now().subtract(const Duration(hours: 5)),
    },
  ];

  // Galeri resimleri listesini tutacak Future
  late Future<List<String>> _galleryImagesFuture;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında galeri resimlerini çekiyoruz
    _galleryImagesFuture = fetchGalleryImages();
  }

  // Django /gallery/ endpoint'ine POST isteği atarak resim URL'lerini çekiyoruz
  Future<List<String>> fetchGalleryImages() async {
    try {
      // Login sonrası savePrefs("token", ...) ile kaydedilen token'ı okuyoruz:
      String? token = await getPrefs("token");

      final response = await http.post(
        Uri.parse(getGaleriImages),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // JSON veriyi decode ediyoruz -> ["url1","url2",...]
        var decoded = jsonDecode(response.body);
        return List<String>.from(decoded.map((e) => e["url"]));
      } else {
        throw Exception(
            "Galeri resimleri alınamadı. Status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Galeri verileri çekilirken hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          // Ortak NotificationIcon widget'ı kullanılarak bildirim sayfasına yönlendirme sağlanır.
          NotificationIcon(notifications: notifications),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              logout(context);
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
      // Galeri resimlerini FutureBuilder ile gösteriyoruz
      body: FutureBuilder<List<String>>(
        future: _galleryImagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Veriler yükleniyor
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Hata varsa
            return Center(child: Text('Hata oluştu: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Veri yok veya boşsa
            return const Center(child: Text('Hiç resim bulunamadı'));
          }

          // Veri başarılı şekilde geldiyse
          final galleryImages = snapshot.data!;

          return SingleChildScrollView(
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
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
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: NetworkImage(
                                      announcement['imageUrl'] ?? ''),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withAlpha(
                                        (0.3 * 255).toInt()), // karartma
                                    BlendMode.darken,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      announcement['title'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      announcement['subtitle'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Burada artık statik liste yerine sunucudan gelen liste kullanıyoruz
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: galleryImages.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 sütun
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
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
