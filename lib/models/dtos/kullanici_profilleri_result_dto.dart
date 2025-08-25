import 'package:fitcall/models/4_auth/user_model.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';

class KullaniciProfilleriResult {
  final UserModel? user; // backend yeni formatta dolu gelir
  final List<KullaniciProfilModel> profiller;

  KullaniciProfilleriResult({required this.user, required this.profiller});
}
