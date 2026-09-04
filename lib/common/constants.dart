/// Backend'deki `RolEnum` ile birebir. Rol adları token'a ve
/// `SistemKullaniciModel.rol` alanına yazıldığı için isimler aynen korunmalı.
enum Roller {
  yonetici,
  uye,
  antrenor,

  /// Ön büro. Ders açma/düzenleme/iptal/silme ve QR işlemleri bu profilde;
  /// ciro, bakiye, hakediş gibi bilgileri görmez (bkz. lib/screens/8_ofis/).
  ofis,
  cafe,
}

final Map<Roller, String> rollerEnums = {
  Roller.yonetici: 'yonetici',
  Roller.uye: 'uye',
  Roller.antrenor: 'antrenor',
  Roller.ofis: 'ofis',
  Roller.cafe: 'cafe',
};
