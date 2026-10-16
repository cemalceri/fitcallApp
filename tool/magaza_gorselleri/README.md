# Mağaza ekran görüntüleri

Uygulamanın gerçek sayfaları iOS modunda, demo veriyle, App Store boyutlarında çizilir:
iPhone 6.9" (1320×2868), iPhone 6.5" (1242×2688), iPad 13" (2064×2752).

1. **SF Pro fontu** (git'e girmez, lisans dağıtıma izin vermiyor): developer.apple.com/fonts
   adresinden `SF-Pro.dmg` indir, 7-Zip ile `dmg → SFProFonts.pkg → Payload → Payload~` zincirini aç,
   `Library/Fonts/SF-Pro-Text-*.otf` ve `SF-Pro-Display-*.otf` dosyalarını `fontlar/` altına koy.
   Emoji için Windows'un `seguiemj.ttf` fontu kullanılır.
2. `flutter test tool/magaza_gorselleri/magaza_gorselleri_test.dart`
3. Çıktı `build/magaza_gorselleri/<cihaz>/` altına RGBA PNG olarak yazılır. App Store saydamlık
   kanalı istemez; RGB'ye çevirip kökteki `magaza_gorselleri/` klasörüne koy (git'e girmez).

Yeni sahne eklemek için `sahneler.dart`'a bir `Sahne` ekle. Tanımsız API ucu konsola
`SAHTE API — tanımsız uç` diye yazılır; o ucun yanıtını sahnenin `api` haritasına ekle.
Tarihler çalıştırma gününe göre kurulur (`demo_veri.dart`).
