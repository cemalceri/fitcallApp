import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/methods.dart';
import 'package:fitcall/models/ders_models.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'widgets/ders_listesi_widget.dart';

// Örnek randevu modeli
class Randevu {
  final int id;
  final String baslangicTarihi;

  Randevu({required this.id, required this.baslangicTarihi});
}

class DersListesiPage extends StatefulWidget {
  const DersListesiPage({super.key});

  @override
  State<DersListesiPage> createState() => _DersListesiPageState();
}

class _DersListesiPageState extends State<DersListesiPage> {
  // Örnek randevu listesi
  List<DersModel?> gecmisDersler = [];
  List<DersModel?> gelecekDersler = [];

  @override
  void initState() {
    super.initState();
    _dersBilgileriniCek();
  }

  Future<void> _dersBilgileriniCek() async {
    var token = await getToken(context);
    if (token != null) {
      try {
        var response = await http.post(
          Uri.parse(getDersProgrami),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          List<DersModel?> tumDersler = DersModel.fromJson(response);
          setState(() {
            gecmisDersler = tumDersler
                .where((element) =>
                    element!.bitisTarihSaat.isBefore(DateTime.now()))
                .toList();
            gelecekDersler = tumDersler
                .where((element) =>
                    element!.bitisTarihSaat.isAfter(DateTime.now()))
                .toList();
          });
        } else {
          // Hata durumunda
          throw Exception('API isteği başarısız oldu: ${response.statusCode}');
        }
      } catch (e) {
        // Hata durumunda kullanıcıya bildirim gösterebilirsiniz
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ödeme bilgileri alınırken bir hata oluştu: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ders Listesi'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Geçmiş Dersler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            DersListesiWidget(dersler: gecmisDersler),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Gelecek Dersler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            DersListesiWidget(dersler: gelecekDersler),
          ],
        ),
      ),
    );
  }
}
