import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/methods.dart';
import 'package:fitcall/common/widgets.dart';
import 'package:fitcall/models/ders_models.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'widgets/ders_listesi_widget.dart';

class DersListesiPage extends StatefulWidget {
  const DersListesiPage({super.key});

  @override
  State<DersListesiPage> createState() => _DersListesiPageState();
}

class _DersListesiPageState extends State<DersListesiPage> {
  // Örnek randevu listesi
  List<DersModel?> gecmisDersler = [];
  List<DersModel?> gelecekDersler = [];
  bool _apiIstegiTamamlandiMi = false;

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
        if (mounted) {
          // Hata durumunda kullanıcıya bildirim gösterebilirsiniz
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dersler alınırken bir hata oluştu: $e'),
            ),
          );
        }
        // Hata durumunda kullanıcıya bildirim gösterebilirsiniz
      } finally {
        setState(() {
          _apiIstegiTamamlandiMi = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ders Listesi'),
      ),
      body: _apiIstegiTamamlandiMi
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.blue[200],
                  child: const Text(
                    'Gelecek Dersler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DersListesiWidget(dersler: gelecekDersler),
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.blue[200],
                  child: const Text(
                    'Geçmiş Dersler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DersListesiWidget(dersler: gecmisDersler),
              ],
            )
          : const LoadingSpinnerWidget(message: 'Dersler yükleniyor...'),
    );
  }
}
