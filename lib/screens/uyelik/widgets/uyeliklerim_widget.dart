import 'package:fitcall/models/uyelik_paket_models.dart';
import 'package:flutter/material.dart';

class UyeliklerimWidget extends StatelessWidget {
  final List<UyelikModel>? uyelikListesi;
  const UyeliklerimWidget(
    this.uyelikListesi, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        color: Colors.blueGrey[100],
        child: Center(
          child: uyelikListesi == null || uyelikListesi!.isEmpty
              ? const Text("Üyelik bulunamadı")
              : ListView.builder(
                  itemCount: uyelikListesi!.length,
                  itemBuilder: (context, index) {
                    final uyelik = uyelikListesi![index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: MembershipCard(
                        title: "${uyelik.haftaninGunu} (${uyelik.kortAdi})",
                        subTitle:
                            "Başlangıç: ${uyelik.baslangicSaati}-Bitiş: ${uyelik.bitisSaati}",
                        icon: Icons.tv, // or another appropriate icon
                        color:
                            Colors.blueAccent, // or another appropriate color
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class MembershipCard extends StatelessWidget {
  final String title;
  final String subTitle;
  final IconData icon;
  final Color color;

  const MembershipCard({
    super.key,
    required this.title,
    required this.subTitle,
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
          subTitle,
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
