import 'package:fitcall/v2/modules/auth/models/kullanici_profil_model.dart';
import 'package:fitcall/v2/shared/api_urls.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static Future<List<KullaniciProfilModel>> login(
    String kullaniciAdi,
    String parola,
  ) async {
    final uri = Uri.parse(loginV2).replace(queryParameters: {
      'kullanici_adi': kullaniciAdi.trim().toLowerCase(),
      'parola': parola,
    });

    final response =
        await http.get(uri, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final profiller = (data['profiller'] as List<dynamic>)
          .map((e) => KullaniciProfilModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return profiller;
    } else {
      final hata = jsonDecode(response.body)['hata'] as String?;
      throw Exception(hata ?? 'Giriş işlemi başarısız.');
    }
  }
}
