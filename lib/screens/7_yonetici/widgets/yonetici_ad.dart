// lib/screens/7_yonetici/widgets/yonetici_ad.dart

import 'package:fitcall/models/4_auth/user_model.dart';

/// Yönetici ekranlarında gösterilecek kişi adı.
///
/// Yönetici profilinde üye/antrenör kaydı olmadığı için ad soyad doğrudan
/// kullanıcı hesabından okunur; boşsa kullanıcı adına düşer.
String yoneticiGorunenAd(UserModel user) {
  final tamAd = '${user.firstName} ${user.lastName}'.trim();
  return tamAd.isNotEmpty ? tamAd : user.username;
}
