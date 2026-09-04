// lib/screens/1_common/widgets/hesap_adi.dart

import 'package:fitcall/models/4_auth/user_model.dart';

/// Üye/antrenör kaydı olmayan profillerde (yönetici, ofis) gösterilecek ad.
///
/// Bu rollerde ad soyad doğrudan kullanıcı hesabından okunur; boşsa kullanıcı
/// adına düşer.
String hesapGorunenAdi(UserModel user) {
  final tamAd = '${user.firstName} ${user.lastName}'.trim();
  return tamAd.isNotEmpty ? tamAd : user.username;
}
