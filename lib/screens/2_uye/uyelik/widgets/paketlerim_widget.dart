import 'package:fitcall/models/2_uye/uyelik_paket_model.dart';
import 'package:flutter/material.dart';

class PaketlerimWidget extends StatelessWidget {
  final List<PaketModel>? paketListesi;

  const PaketlerimWidget(
    this.paketListesi, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        color: Colors.blueGrey[100],
        child: paketListesi == null || paketListesi!.isEmpty
            ? const Center(child: Text("Paket bulunamadı"))
            : ListView.builder(
                itemCount: paketListesi!.length,
                itemBuilder: (context, index) {
                  final paket = paketListesi![index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: PackageCard(
                      title: paket.paketAdi,
                      description:
                          "Ders sayısı: ${paket.adet} Kalan:${paket.kalanAdet}",
                      icon: Icons.tv, // or another appropriate icon
                      color: Colors.green, // or another appropriate color
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class PackageCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const PackageCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: color,
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward,
          color: Colors.white,
        ),
      ),
    );
  }
}
