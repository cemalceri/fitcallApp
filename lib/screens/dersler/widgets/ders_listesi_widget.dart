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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        color: Colors.blueGrey[100],
        child: dersler.isEmpty
            ? const Center(child: Text("Kayıt bulunamadı."))
            : ListView.builder(
                itemCount: dersler.length,
                itemBuilder: (context, index) {
                  DersModel ders = dersler[index]!;
                  return Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: GestureDetector(
                      onTap: () {
                        // Butona tıklandığında popup göster
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return DersPopupWidget(ders: ders, index: index);
                          },
                        );
                      },
                      child: DersCardWidget(ders: ders, index: index),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class DersCardWidget extends StatelessWidget {
  const DersCardWidget({
    super.key,
    required this.ders,
    required this.index,
  });

  final DersModel ders;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3, // Kartın yükselti derecesi
      // Kartın kenar boşluğu
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
    );
  }
}
