import 'package:fitcall/models/6_muhasebe/para_hareket_model.dart';
import 'package:http/http.dart' as http;
import 'package:fitcall/services/auth_service.dart';
import 'package:fitcall/common/api_urls.dart';

class ParaHareketService {
  static Future<List<ParaHareketModel>> fetchForPeriod(int yil, int ay) async {
    final token = await AuthService.getToken();
    final res = await http.post(
      Uri.parse(getParaHareketi),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: '{"yil":$yil,"ay":$ay}',
    );
    if (res.statusCode == 200) {
      return ParaHareketModel.listFromResponse(res.body);
    }
    throw Exception('Bakiye hareketleri alınamadı');
  }
}
