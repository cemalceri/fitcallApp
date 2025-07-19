import 'package:fitcall/models/6_muhasebe/muhasebe_ozet_model.dart';
import 'package:http/http.dart' as http;
import 'package:fitcall/services/auth_service.dart';
import 'package:fitcall/common/api_urls.dart';

class MuhasebeService {
  static Future<List<MuhasebeOzetModel>> fetch() async {
    final token = await AuthService.getToken();
    final res = await http.post(
      Uri.parse(getMuhasebeOzet),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return MuhasebeOzetModel.listFromResponse(res.body);
    }
    throw Exception('Muhasebe özeti alınamadı');
  }
}
