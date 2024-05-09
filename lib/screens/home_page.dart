import 'package:fitcall/common/methods.dart';
import 'package:fitcall/common/routes.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final List<Map<String, dynamic>> buttons = [
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ana Sayfa'), actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            logout(context);
          },
        ),
      ]),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: buttons.map((button) {
          return Card(
            elevation: 4,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, button['name']!);
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(button['icon'], size: 48),
                    const SizedBox(height: 10),
                    Text(
                      button['text'],
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
