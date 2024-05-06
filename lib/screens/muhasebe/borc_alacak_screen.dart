// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/common/methods.dart';
import 'package:fitcall/models/muhasebe_models.dart';
import 'package:fitcall/common/api_urls.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'widgets/odeme_borc_listesi_widget.dart';

class BorcAlacakPage extends StatefulWidget {
  const BorcAlacakPage({super.key});

  @override
  State<BorcAlacakPage> createState() => _BorcAlacakPageState();
}

class _BorcAlacakPageState extends State<BorcAlacakPage> {
  List<OdemeBorcModel?> odemeBorcListesi = [];
  double kalanBakiye = 0;

  @override
  void initState() {
    super.initState();
    _odemeBilgileriniCek();
  }

  Future<void> _odemeBilgileriniCek() async {
    var token = await getToken(context);
    if (token != null) {
      try {
        var response = await http.post(
          Uri.parse(getOdemeBilgileri),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          List<OdemeBorcModel?> odemeBorcModel =
              OdemeBorcModel.fromJson(response);
          setState(() {
            odemeBorcListesi = odemeBorcModel;
            kalanBakiye = _kalanBakiyeHesapla(odemeBorcModel);
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
        title: const Text('Ödeme ve Borç Bilgilerim'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
              child: OdemeBorcListesiWidget(
            baslik: 'Borç Bilgilerim',
            odemeBorcModelList: odemeBorcListesi
                .where((element) => element!.hareketTuru == 'Borc')
                .toList(),
          )),
          Expanded(
              child: OdemeBorcListesiWidget(
            baslik: 'Ödeme Bilgilerim',
            odemeBorcModelList: odemeBorcListesi
                .where((element) => element!.hareketTuru == 'Odeme')
                .toList(),
          )),
          KalanBakiyeWidget(kalanBakiye: kalanBakiye),
        ],
      ),
    );
  }
}

_kalanBakiyeHesapla(List<OdemeBorcModel?> odemeBorcModel) {
  double toplamBorcTutari = odemeBorcModel
      .where((element) => element!.hareketTuru == 'Borc')
      .map((e) => double.parse(e!.tutar))
      .fold(0, (previousValue, element) => previousValue + element);
  double toplamOdemeTutari = odemeBorcModel
      .where((element) => element!.hareketTuru == 'Odeme')
      .map((e) => double.parse(e!.tutar))
      .fold(0, (previousValue, element) => previousValue + element);
  return toplamBorcTutari - toplamOdemeTutari;
}
