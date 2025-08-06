import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:http/http.dart' as http;

class EtkinlikService {
  /// Aktif üyenin içinde bulunduğu haftadaki dersleri döner.
  static Future<List<EtkinlikModel>> getirHaftalikDersBilgilerim() async {
    final token = await AuthService.getToken();
    final res = await http.post(
      Uri.parse(getHaftalikDersBilgilerim),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}), // parametre yok
    );

    if (res.statusCode == 200) {
      return EtkinlikModel.fromJson(res);
    } else {
      throw Exception('Haftalık ders listesi alınamadı (${res.statusCode})');
    }
  }

  static Future<List<EtkinlikModel>>
      getirAntrenorHaftalikDersBilgilerim() async {
    final token = await AuthService.getToken();
    final res = await http.post(
      Uri.parse(getAntrenorHaftalikEtkilikler),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}), // parametre yok
    );

    if (res.statusCode == 200) {
      return EtkinlikModel.fromJson(res);
    } else {
      throw Exception('Haftalık ders listesi alınamadı (${res.statusCode})');
    }
  }
}
