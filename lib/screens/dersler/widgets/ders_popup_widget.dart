import 'dart:io';
import 'package:fitcall/models/ders_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DersPopupWidget extends StatelessWidget {
  const DersPopupWidget({
    super.key,
    required this.ders,
    required this.index,
  });

  final DersModel ders;
  final int index;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ders ${index + 1}'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Antrenör: ${ders.antrenorAdi}',
            style: const TextStyle(
              color: Colors.grey, // Altyazı için gri renk
            ),
          ),
          Text(
            'Kort: ${ders.kortAdi}',
            style: const TextStyle(
              color: Colors.grey, // Altyazı için gri renk
            ),
          ),
          Text(
            'Tarih: ${DateFormat('dd.MM.yyyy HH:mm').format(ders.baslangicTarihSaat)}-${DateFormat('HH:mm').format(ders.bitisTarihSaat)}',
            style: const TextStyle(
              color: Colors.grey, // Altyazı için gri renk
            ),
          ),
          // Diğer altbilgiler buraya eklenebilir
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Popup'ı kapat
          },
          child: ders.bitisTarihSaat.isAfter(DateTime.now())
              ? GestureDetector(
                  onTap: () {
                    //TODO: Derse katılacağım whatsapp yönlendir isteği gönder
                    _launchUrl(context, ders, 'katılacağım');
                  },
                  child: const Text('Katılacağım'))
              : GestureDetector(
                  onTap: () {
                    //TODO: Derse yapıldı api isteği gönder
                  },
                  child: const Text('Ders Yapıldı')),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Popup'ı kapat
          },
          child: ders.bitisTarihSaat.isBefore(DateTime.now())
              ? GestureDetector(
                  onTap: () {
                    //TODO: Derse yapılmadı api isteği gönder
                  },
                  child: const Text('Ders Yapılmadı'),
                )
              : GestureDetector(
                  onTap: () {
                    //TODO: Derse katılamayacağım whatsapp yönlendir isteği gönder
                    _launchUrl(context, ders, 'katılamayacağım');
                  },
                  child: const Text('Katılamacağım')),
        ),
      ],
    );
  }
}

Future<void> _launchUrl(BuildContext context, DersModel ders, mesaj) async {
  var contact = "+905422462982";
  var androidUrl =
      "whatsapp://send?phone=$contact&text=Merhaba, ${DateFormat('dd.MM.yyyy HH:mm').format(ders.baslangicTarihSaat)} tarihinde ${ders.antrenorAdi ?? ''} ile olan derse $mesaj.";
  var iosUrl =
      "https://wa.me/$contact?text=${Uri.parse('Merhaba, ${DateFormat('dd-MM-yyyy HH-mm').format(ders.baslangicTarihSaat)} tarihinde ${ders.antrenorAdi ?? ''} ile olan derse $mesaj.')}";

  try {
    if (Platform.isIOS) {
      await launchUrl(Uri.parse(iosUrl));
    } else {
      await launchUrl(Uri.parse(androidUrl));
    }
  } on Exception catch (e) {
    //uyarı mesajı göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Whatsapp açılırken bir hata oluştu: $e'),
      ),
    );
  }
}
