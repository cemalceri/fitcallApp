import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/windgets/spinner_widgets.dart';
import 'package:fitcall/models/2_uye/uyelik_paket_model.dart';
import 'package:fitcall/screens/2_uye/uyelik/widgets/paketlerim_widget.dart';
import 'package:fitcall/screens/2_uye/uyelik/widgets/uyeliklerim_widget.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UyelikPaketPage extends StatefulWidget {
  const UyelikPaketPage({super.key});

  @override
  State<UyelikPaketPage> createState() => _UyelikPaketPageState();
}

class _UyelikPaketPageState extends State<UyelikPaketPage> {
  List<UyelikModel>? uyelikListesi = [];
  List<PaketModel>? paketListesi = [];
  bool _apiIstegiTamamlandiMi = false;

  @override
  void initState() {
    super.initState();
    _uyelikPaketBilgileriniCek();
  }

  Future<void> _uyelikPaketBilgileriniCek() async {
    var token = await AuthService.getToken();
    if (token != null) {
      await http.post(
        Uri.parse(getPaketBilgileri),
        headers: {'Authorization': 'Bearer $token'},
      ).then((response) {
        if (response.statusCode == 200) {
          List<UyelikModel>? uyelikModelList = UyelikModel.fromJson(response);
          List<PaketModel>? paketModelList = PaketModel.fromJson(response);
          if (mounted) {
            setState(() {
              paketListesi = paketModelList;
              uyelikListesi = uyelikModelList;
              _apiIstegiTamamlandiMi = true;
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Üyelik ve paket bilgileri alınırken bir hata oluştu'),
              ),
            );
          }
        }
      }).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Üyelik ve paket bilgileri alınırken bir hata oluştu: $e'),
            ),
          );
        }
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('İstek zaman aşımına uğradı'),
              ),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Üyelik ve Paketlerim'),
        ),
        body: _apiIstegiTamamlandiMi
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.blue[200],
                    child: const Text(
                      'Paketlerim',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PaketlerimWidget(paketListesi),
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.blue[200],
                    child: const Text(
                      'Üyeliklerim',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  UyeliklerimWidget(uyelikListesi),
                ],
              )
            : const LoadingSpinnerWidget(
                message: "Üyelik ve paket bilgileri alınıyor..."));
  }
}
