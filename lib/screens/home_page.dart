import 'package:fitcall/common/methods.dart';
import 'package:fitcall/common/routes.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

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
    {'name': 5, 'icon': Icons.notifications, 'text': 'Bildirimler'},
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

  // Örnek resim galerisi verileri
  final List<String> galleryImages =
      List.generate(6, (index) => 'https://via.placeholder.com/150');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              logout(context);
            },
          ),
        ],
      ),
      // Sol tarafta açılır menü
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Colors.blueAccent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Text(
                'Menü',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                ),
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
            // Duyurular Bölümü Başlığı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Icon(Icons.announcement, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Duyurular',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Duyurular için swipeable PageView
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
                              image: NetworkImage(announcement['imageUrl']!),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withAlpha((0.3 * 255).toInt()),
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
                                  announcement['title']!,
                                  style: const TextStyle(
                                    color: Colors
                                        .black, // Daha okunabilir koyu renk
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  announcement['subtitle']!,
                                  style: const TextStyle(
                                    color: Colors
                                        .black87, // Alt bilgi için koyu ton
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
            // Resim Galerisi Bölümü Başlığı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Icon(Icons.photo_album, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Resim Galerisi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Resim Galerisi Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: galleryImages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      galleryImages[index],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
