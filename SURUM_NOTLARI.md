# Sürüm Notları

> Mağaza vitrinine girilecek "Yenilikler" metni ve teknik özet.
> Yeni sürüm en üste eklenir.
>
> **Yalnızca tr-TR yazılır.** İngilizce metin eklenmez: mağazaya bir en-US
> yerelleştirmesi girildiği anda Apple o dil için ekran görüntüsü, açıklama ve
> gizlilik metni de istiyor — çıkmak istemediğimiz bir bakım yükü.
> (3.6.0 ve öncesindeki en-US bölümleri tarihsel kayıt olarak duruyor.)

## 3.8.0 — 2026-08-11

### Mağaza metni (tr-TR)

Uygulama baştan aşağı yenilendi: koyu tema geldi, kulüp renklerine geçildi, gezinme sabitlendi.

- **Koyu tema:** Ayarlar > Tema'dan Sistem / Açık / Koyu seçilebiliyor. Sistem seçiliyse telefonun
  karanlık mod ayarına uyuyor.
- **Yeni Ayarlar sayfası:** Tema, bildirim izni, şifre değiştirme, KVKK metni, yardım ve hesap
  işlemleri tek yerde toplandı.
- **Kulüp renkleri:** Arayüz kulübün turuncu-mavi kimliğine geçti.
- **Sabit alt menü:** Üye ve antrenörde alt bar artık kalıcı: Ana Sayfa, Takvim, QR, Hareketler
  (antrenörde Öğrenciler) ve Hesabım arasında geçerken sayfa sıfırlanmıyor, hangi sekmede
  olduğunuz görünüyor.
- **Takvim:** Hafta değiştirmek için şeridi yana kaydırmak yeterli. Yeni **Ajanda** görünümü
  derslerinizi gün başlıklarıyla liste hâlinde gösteriyor; ızgara görünümüne tek dokunuşla
  dönülüyor.
- **Ders işlemleri:** Antrenörde onay, iptal, devir ve detay ekranları alttan açılıyor — tek elle
  ulaşılabiliyor. Ders kutusuna uzun basınca kısayol menüsü çıkıyor.
- **Yardım & SSS:** Arama kutusu eklendi; antrenör tarafında bölüm filtreleri var.
- **Bildirimler:** Bildirimi yana kaydırarak silebiliyorsunuz, yanlışlıkla sildiyseniz "Geri al".
- **Giriş ekranı** sadeleşti ve şifre yöneticileri artık kullanıcı adı/şifreyi doldurabiliyor.
- **Profil** sayfaları kısaldı, bilgiye kaydırmadan ulaşılıyor.

### Teknik

- **Tasarım sistemi (`lib/common/tema.dart`):** marka renkleri kulüp formasından örneklendi
  (turuncu #F4661B / kobalt #2438C8). Açık zeminde metin için koyu turuncu (#C2500B, beyazla
  4.7:1) `ColorScheme.primary`; canlı ton dolgu yüzeylerde. Semantik renkler `FitcallRenkleri`
  ThemeExtension'ında (başarı/uyarı/bilgi/hata/nötr + takvim ders durumları), tipografi ve
  `Bosluk`/`Yaricap` ölçekleri aynı dosyada. 20+ bileşen teması tanımlı; `MaterialApp`'teki
  Flutter şablonu deepPurple tohumu kaldırıldı.
- **Koyu tema:** `darkTheme` + `themeMode`; tercih `TemaKontrol` (secure storage) üzerinden
  saklanıyor ve `StorageService.clearAll()` çıkışta koruyor. 53 dosyada sabit beyaz/gri/koyu
  renkler token'lara çevrildi; durum renkleri üzerindeki metin `uzerineYazi()` ile parlaklığa
  göre seçiliyor.
- **Sekme kabuğu:** `UyeKabuk` / `AntrenorKabuk` (`IndexedStack` + tembel sekme kurulumu) ve ortak
  `KabukAltBar`; ana hesap guard'ı kabuk içinde tekrar uygulanıyor (rota guard'ı sekme geçişinde
  çalışmaz). Eski `uye_bottom_bar` / `antrenor_bottom_bar` silindi.
- **Takvim ortaklaştırma:** `timeline_view`, `week_day_selector` ve `TakvimColors` kopyaları
  `lib/screens/1_common/takvim/` altında tek bileşene indi (`TakvimZamanCizelgesi`,
  `HaftaGunSecici`, `TakvimAjanda`, `TakvimRenkleri`); ~900 satır tekrar kalktı. Hafta geçişi
  `PageView`, ders bloğu `blokYapici` ile rolden geliyor.
- **Alt sayfa kalıbı:** `altSayfaGoster()` + `AltSayfaBasligi`; antrenör takvimindeki 5 `Dialog`
  bottom sheet'e taşındı.
- **Ölü kod:** `MuhasebeTable`, `ParaHareketTable` ve `data_table_2` bağımlılığı silindi;
  `antrenor_profil_page.dart` 1.760 → ~950 satır (şifre/hesap silme sayfaları
  `lib/screens/1_common/hesap/` altında ortaklaştı).
- **Erişilebilirlik:** giriş formunda `AutofillGroup` + autofill hints, yeni bileşenlerde
  `Semantics`, ikon-only 40 `IconButton`'a tooltip.
- **Testler:** taşma matrisi uygulamanın gerçek temasıyla koşuyor ve her bileşen için bir de koyu
  tema koşusu yapıyor; toplam **755 test** geçiyor, `flutter analyze` temiz.

## 3.7.0 — 2026-08-08

### Mağaza metni (tr-TR)

Hakediş saatleri ekranı geldi; antrenör ve yönetici ders saatlerini ay ay görebiliyor.

- **Hakediş Saatleri:** Antrenör kendi ders saatlerini, yönetici istediği antrenörünkini son 12 ay
  boyunca ay ay görüyor. Hakediş alacak dersler, karar bekleyenler ve hakediş dışı kalanlar ayrı
  ayrı; bir gruba dokununca o derslerin listesi katılımcılarıyla açılıyor.
- **Plan dışı katılımcı:** Antrenör yoklama alırken derse plan dışı üye ya da misafir ekleyebiliyor;
  ofis anında bildirim alıyor.
- **Bildirimler:** Okunmamış bildirim varken uygulama simgesinde rozet çıkıyor. "Tümünü okundu yap"
  artık gerçekten tümünü işaretliyor, "Tümünü sil" seçeneği eklendi.
- **Antrenör ana sayfası** üye ve yönetici ekranlarıyla aynı düzene geçti: alt bar + yan menü.
- **QR ekranları:** QR gösterirken ekran parlaklığı otomatik olarak yükseliyor, turnikede okutmak
  kolaylaşıyor.

### Teknik

- **Hakediş saatleri (yeni ekran seti):** yönetici 3 ekran (ay seç → antrenör listesi → ay panosu →
  ders listesi), antrenör 2 ekran. Ay panosu ve ders listesi iki rolde **ortak**
  (`lib/screens/1_common/hakedis/`); rol farkı yalnızca `HakedisVeriKaynagi` implementasyonunda.
  Backend `api/yonetici/hakedis_metots.py` + `hakedis_servis.py`, 5 uç, migration `0080`/`0081`.
  Hakediş kuralı tek yerde (`hakedis_durumu`): hakediş bayrağı ders onayını ezer.
- **Ay ızgarası 4×3:** yatay şerit yerine tek bakışta 12 ay. Sıra **eskiden yeniye**, içinde
  bulunulan ay son hücrede ve açılışta seçili (`hakedis_servis.ay_listesi` ters çeviriyor; mobil
  diziyi olduğu gibi çiziyor). Sabit `childAspectRatio` 1.3 yazı ölçeğinde taştığı için
  `GridView` değil `IntrinsicHeight`'lı `Row`'lar kullanılıyor.
- **Antrenör yetkisi:** antrenör uçları `antrenor_id` parametresi kabul etmez; kimlik token'dan
  (`request.antrenor`) çözülür — antrenör başkasının hakedişini isteyemiyor.
- **Cache:** özet uçları işletme başına sürümlü anahtarla 5 dk cache'li
  (`calendarapp/services/hakedis_cache.py`); ders/onay yazan her sinyal sürümü artırıyor.
- **Plan dışı bildirimi:** `SetDersKatilimi` kaydetmeden önce/sonra plan dışı tablosunu
  fotoğraflayıp farkı tek bildirime çeviriyor — aynı yoklama tekrar kaydedilirse bildirim çıkmıyor.
  Ekleme kadar çıkarma da bildiriliyor. Yeni tip `OFIS_PLAN_DISI_KATILIM`.
- **Simge rozeti:** `app_badge_plus` + `AppBadgeService`; tek giriş noktası
  `NotificationService.refreshUnreadCount`. Uygulama kapalıyken FCM background handler saklanan
  sayacı artırıyor, açılışta gerçek değer düzeltiyor. iOS'ta kapalı uygulamada rozeti yalnızca
  APNs payload'ı güncelleyebildiği için backend `apns.aps.badge` gönderiyor.
- **Bildirim kapsamı düzeltmesi:** `getNotifications` son 50 kaydı döndürürken sayaç tümünü
  sayıyordu, zil "9+" takılı kalıyordu. Üç uç artık ortak `profil_bildirimleri(request)` kapsamını
  kullanıyor; `setNotificationsRead`/`setNotificationsDeleted` `tumu: true` destekliyor (soft delete).
- **Ekran parlaklığı:** `EkranParlaklikService` + platform kanalları (Kotlin/Swift); QR
  ekranlarından çıkınca eski değere dönülüyor.
- **Doğrulama:** `flutter test` 650, `flutter analyze` temiz; backend süiti 448 geçiyor.

## 3.6.0 — 2026-08-03

### Mağaza metni (tr-TR)

Ders saatleri artık her telefonda kulüp saatiyle (Türkiye saati) gösteriliyor.

- Saat dilimi farklı olan telefonlarda ders saatleri kaymıyor.
- Bildirimde yazan saat ile takvimde görünen saat her zaman aynı.
- "Takvime ekle" ile eklenen ders, telefon takviminde doğru saate ve hatırlatıcıya düşüyor.
- Geçmiş/gelecek ders ayrımı, "bugün" işareti ve teyit ekranları saat dilimi farkından etkilenmiyor.

### Store text (en-US)

Lesson times are now always shown in the club's time zone (Türkiye).

- Lesson times no longer shift on phones set to a different time zone.
- The time in a notification and the time in the calendar always match.
- "Add to calendar" now creates the event at the correct time, with the correct reminder.
- Past/upcoming lesson state, the "today" marker and confirmation screens are no longer affected by the device time zone.

### Teknik

- **Sorun:** `parseApiTarih` `.toLocal()` uyguluyordu; `.toLocal()` cihazın saat
  dilimini kullanır. Sunucu `2026-08-01T08:30:00+03:00` gönderirken saat dilimi
  Europe/Istanbul olmayan bir telefonda ders 11:30 (UTC+6) ya da 05:30 (UTC+0)
  görünüyordu. Bildirim metni sunucuda üretildiği için 08:30 diyor, takvim
  kayıyordu — kullanıcıya "bildirimler 3 saat farklı" olarak yansıdı.
- **Çözüm:** Gelen her an kulüp duvar saatine indirgeniyor
  (`kulupUtcOfseti = 3 saat`; Türkiye 2016'dan beri sabit UTC+3).
  `simdiKulup()` / `bugunKulup()` eklendi, API tarihleriyle karşılaştırılan
  81 `DateTime.now()` çağrısı bunlarla değiştirildi.
- `add_2_calendar` epoch milisaniye gönderdiği için orada gerçek an gerekiyor:
  `kulupAnI()` + `timeZone: 'Europe/Istanbul'`.
- **Doğrulama:** Paket 6 saat diliminde koşuldu (UTC+3/+0/+6/+9/−5/−11) →
  hepsinde 415/415. CI (`codemagic.yaml`) artık 4 saat diliminde test koşuyor;
  eskiden makine İstanbul'a sabitlendiği için bu sınıf hata CI'da görünmüyordu.
- Backend tarafındaki eşdeğer düzeltmeler `tenis` reposunda (v265).
