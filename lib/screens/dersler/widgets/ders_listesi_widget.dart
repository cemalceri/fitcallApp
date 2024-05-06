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
          height: 10,
        ); // Liste elemanları arasına boşluk ekler
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
              horizontal: 10,
            ), // Kartın kenar boşluğu
            color: Colors.blue[50], // Kartın arka plan rengi
            child: ListTile(
              title: Text(
                'Ders ${index + 1}', // Ders numarasını göster
                style: const TextStyle(
                  color: Colors.blue, // Başlık için mavi renk
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Antrenör: ${ders.antrenorAdi}',
                    style: const TextStyle(
                      color: Colors.black, // Antrenör adı için siyah renk
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Kort: ${ders.kortAdi}',
                    style: const TextStyle(
                      color: Colors.black, // Kort adı için siyah renk
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Tarih: ${DateFormat('dd.MM.yyyy HH:mm').format(ders.baslangicTarihSaat)}-${DateFormat('HH:mm').format(ders.bitisTarihSaat)}',
                    style: const TextStyle(
                      color: Colors.black, // Tarih için siyah renk
                      fontSize: 18,
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
