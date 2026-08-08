# Sürüm Notları

> Mağaza vitrinine girilecek "Yenilikler" metni ve teknik özet.
> Yeni sürüm en üste eklenir.
>
> **Yalnızca tr-TR yazılır.** İngilizce metin eklenmez: mağazaya bir en-US
> yerelleştirmesi girildiği anda Apple o dil için ekran görüntüsü, açıklama ve
> gizlilik metni de istiyor — çıkmak istemediğimiz bir bakım yükü.
> (3.6.0 ve öncesindeki en-US bölümleri tarihsel kayıt olarak duruyor.)

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
