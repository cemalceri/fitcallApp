// test/yoklama_durumu_test.dart
//
// Kilitli ders ekranındaki üç durumun ayrımı. Regresyon: antrenör onay satırı
// hiç yokken ekran "Ders Yapılmadı" gösteriyordu — yönetici onayı o satırı
// yazmadığı için kayıt yokluğu antrenörün kararı sayılamaz.

import 'package:fitcall/screens/3_antrenor/takvim/widgets/lesson_approval_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('yoklamaDurumu', () {
    test('antrenör "yapıldı" dediyse', () {
      expect(yoklamaDurumu(true), YoklamaDurumu.yapildi);
    });

    test('antrenör "yapılmadı" dediyse', () {
      expect(yoklamaDurumu(false), YoklamaDurumu.yapilmadi);
    });

    test('antrenör hiç yoklama almadıysa "yapılmadı" sayılmaz', () {
      expect(yoklamaDurumu(null), YoklamaDurumu.alinmadi);
    });
  });
}
