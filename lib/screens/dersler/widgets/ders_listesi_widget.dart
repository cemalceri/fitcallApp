import 'package:fitcall/models/ders_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ders_popup_widget.dart';

class DersListesiWidget extends StatelessWidget {
  const DersListesiWidget({
    super.key,
    required this.dersler,
  });

  final List<DersModel?> dersler;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dersler.length,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(
            height: 10); // Liste elemanları arasına boşluk ekler
      },
      itemBuilder: (context, index) {
        DersModel ders = dersler[index]!;
        return GestureDetector(
          onTap: () {
            // Butona tıklandığında popup göster
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return DersPopupWidget(ders: ders, index: index);
              },
            );
          },
          child: Card(
            elevation: 3, // Kartın yükselti derecesi
            margin: const EdgeInsets.symmetric(
                horizontal: 10), // Kartın kenar boşluğu
            child: ListTile(
              title: Text(
                'Ders ${index + 1}', // Ders numarasını göster
                style: const TextStyle(
                    color: Colors.blue, // Başlık için mavi renk
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Antrenör: ${ders.antrenorAdi}',
                    style: const TextStyle(
                        color: Colors.black, // Altyazı için gri renk
                        fontSize: 18),
                  ),
                  Text(
                    'Kort: ${ders.kortAdi}',
                    style: const TextStyle(
                      color: Colors.black, // Altyazı için gri renk
                    ),
                  ),
                  Text(
                    'Başlangıç Tarihi: ${DateFormat('dd.MM.yyyy HH:mm').format(ders.baslangicTarihSaat)}',
                    style: const TextStyle(
                      color: Colors.black, // Altyazı için gri renk
                    ),
                  ),
                  Text(
                    'Bitiş Tarihi: ${DateFormat('dd.MM.yyyy HH:mm').format(ders.bitisTarihSaat)}',
                    style: const TextStyle(
                      color: Colors.black, // Altyazı için gri renk
                    ),
                  ),
                  // Diğer altbilgiler buraya eklenebilir
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
