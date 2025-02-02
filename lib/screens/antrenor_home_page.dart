import 'package:fitcall/common/methods.dart';
import 'package:flutter/material.dart';

class AntrenorHomePage extends StatelessWidget {
  AntrenorHomePage({super.key});

  // Menü elemanları (Sadece Derslerim ve Öğrencilerim)
  final List<Map<String, dynamic>> menuItems = [
    {
      'name': '/antrenor_profil', // Dersler sayfasına yönlendirme
      'icon': Icons.person,
      'text': 'Bilgilerim'
    },
    {
      'name': '/antrenor_dersler', // Dersler sayfasına yönlendirme
      'icon': Icons.sports_tennis,
      'text': 'Derslerim'
    },
    {
      'name': '/antrenor_ogrenciler', // Öğrenciler sayfasına yönlendirme
      'icon': Icons.group,
      'text': 'Öğrencilerim'
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
        title: const Text('Antrenör Ana Sayfası'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              logout(context);
            },
          ),
        ],
      ),
      // Sol menü (Drawer)
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
            // Menü elemanları: Derslerim ve Öğrencilerim
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
            // Üst Banner
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
              child: const Text(
                'Hoş Geldiniz, Antrenör!',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Duyurular
            const Text(
              'Duyurular',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9),
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final announcement = announcements[index];
                  return Card(
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
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              announcement['subtitle']!,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Resim Galerisi
            const Text(
              'Resim Galerisi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // GridView.builder(
            //   physics: const NeverScrollableScrollPhysics(),
            //   shrinkWrap: true,
            //   itemCount: galleryImages.length,
            //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            //     crossAxisCount: 3,
            //     crossAxisSpacing: 8,
            //     mainAxisSpacing: 8,
            //   ),
            //   itemBuilder: (context, index) {
            //     return ClipRRect(
            //       borderRadius: BorderRadius.circular(12),
            //       child: Image.network(
            //         galleryImages[index],
            //         fit: BoxFit.cover,
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
