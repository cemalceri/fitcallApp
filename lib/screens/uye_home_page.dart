import 'package:fitcall/common/routes.dart';
import 'package:fitcall/screens/1_common/1_notification/notifications_bell.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:fitcall/services/notification_service.dart';
import 'package:flutter/material.dart';

class UyeHomePage extends StatefulWidget {
  const UyeHomePage({super.key});

  @override
  State<UyeHomePage> createState() => _UyeHomePageState();
}

class _UyeHomePageState extends State<UyeHomePage> {
  final List<Map<String, dynamic>> menuItems = [
    {
      'name': routeEnums[SayfaAdi.profil]!,
      'icon': Icons.person,
      'text': 'Bilgilerim'
    },
    {
      'name': routeEnums[SayfaAdi.muhasebe]!,
      'icon': Icons.payment,
      'text': 'Ödeme/Borç'
    },
    {
      'name': routeEnums[SayfaAdi.dersler]!,
      'icon': Icons.sports_tennis,
      'text': 'Derslerim'
    },
    {
      'name': routeEnums[SayfaAdi.uyeGenelDersTalep]!,
      'icon': Icons.sports_baseball,
      'text': 'Ders Taleplerim'
    },
    {
      'name': routeEnums[SayfaAdi.qrKodKayit]!,
      'icon': Icons.qr_code,
      'text': 'QR Kod İle Giriş'
    },
    {'name': 6, 'icon': Icons.help, 'text': 'Yardım'},
  ];

  @override
  void initState() {
    super.initState();
    NotificationService.refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: const Text('Ana Sayfa'),
        actions: [
          NotificationsBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.logout(context),
          ),
        ],
      ),
      // drawer: Drawer(
      //   child: ListView(
      //     padding: EdgeInsets.zero,
      //     children: [
      //       DrawerHeader(
      //         decoration: BoxDecoration(
      //           gradient: LinearGradient(
      //             colors: [Theme.of(context).primaryColor, Colors.blueAccent],
      //           ),
      //         ),
      //         child: const Text(
      //           'Menü',
      //           style: TextStyle(color: Colors.white, fontSize: 28),
      //         ),
      //       ),
      //       ...menuItems.map((item) => ListTile(
      //             leading: Icon(item['icon']),
      //             title: Text(item['text']),
      //             onTap: () {
      //               Navigator.pop(context);
      //               Navigator.pushNamed(context, item['name']);
      //             },
      //           )),
      //     ],
      //   ),
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hoşgeldin! 🎾",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: menuItems
                  .map((item) => InkWell(
                        onTap: () => Navigator.pushNamed(context, item['name']),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item['icon'],
                                size: 36, color: Colors.blueAccent),
                            const SizedBox(height: 4),
                            Text(item['text'], textAlign: TextAlign.center),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text("Bir Sonraki Dersin"),
                subtitle: const Text("12 Ağustos, 17:00-18:00 Kort 1"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.pushNamed(context, routeEnums[SayfaAdi.dersler]!),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Haftalık Programım',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _dayCard("Pzt", "🎾 17:00"),
                  _dayCard("Sal", "Boş"),
                  _dayCard("Çar", "🎾 19:00"),
                  _dayCard("Per", "🎾 18:00"),
                  _dayCard("Cum", "Boş"),
                  _dayCard("Cmt", "🎾 11:00"),
                  _dayCard("Paz", "Boş"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayCard(String day, String activity) => Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
            color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(activity),
          ],
        ),
      );
}
