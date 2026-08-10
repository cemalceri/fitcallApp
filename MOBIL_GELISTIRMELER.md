# Mobil Geliştirme — Durum ve Yol Haritası

Bu dosya mobil tarafın **tek durum dosyasıdır**: ne bitti, ne açık, ne sırada.
(2026-08-04'te `SONRAKI_ADIMLAR.md` buraya eritildi — iki ayrı "bekleyen iş" listesi tutulmuyor.)

Backend `C:\Django\tenis` (branch `master`). Kronolojik değişiklik kaydı orada `history.md`'de;
burada sadece **durum** tutulur, geçmiş anlatılmaz.

---

## 📌 Şu anki durum (2026-08-08)

| | |
|---|---|
| Mobil | `main` = `origin/main`, `pubspec` sürümü **3.7.0+40** — sürüm notları yazıldı |
| Testler | `flutter test` **672 geçiyor**, `flutter analyze` temiz |
| Backend | `master` = `origin/master`; hakediş uçları + migration `0080`/`0081` **canlıda değilse** önce onlar gider |
| Mağaza | Son yayınlanan sürüm **3.6.0**; 3.7.0 build'i Codemagic'te alınacak |

**Sıradaki adım — 3.7.0 yayını.** Mobil hakediş ekranı backend uçları olmadan çalışmaz
("Beklenmeyen bir hata oluştu" + boş antrenör listesi = uçlar canlıda yok demektir), o yüzden sıra şu:
1. `git push heroku master` (migration `0080`/`0081` dahil) — deploy kullanıcının işi
2. Codemagic build'i (`version:` zaten 3.7.0), mağaza metni `SURUM_NOTLARI.md`'de hazır

Codemagic sürüm adını `pubspec.yaml`'daki `version:` alanından, build numarasını mağazadaki
son build'den otomatik alır (`codemagic.yaml`). Yani yayın için **sadece `version:` bump'lanır**.

---

## 🔴 Açık işler

### 1. SSS/Yardım metni onayı
`lib/screens/1_common/yardim_page.dart` içindeki soru-cevap içeriği **taslak**; kullanıcı onayı /
düzeltmesi bekliyor. Son dokunuş `f5d1d62`.

### 2. Heroku Scheduler doğrulaması
Faz 1'in bildirim komutları Scheduler'a eklendi mi, teyit edilmedi (bu repodan doğrulanamaz):
- `python manage.py ders_bildirimleri` — 10 dakikada bir
- `python manage.py paket_bitis_bildirim` — günlük

### 3. Deploy sonrası gözlem (backend canlıya çıktı, izlenmeli)
- **İptal signal'ları:** `etkinlik_signals/` paketine `__init__.py` eklenmesiyle ~5,5 aydır işlemeyen
  telafi/paket iadesi/borç mantığı devreye girdi. İlk iptallerin finansal kayıtları gözle kontrol
  edilmeli. Geçmiş 5,5 ay geriye dönük işlenmiyor.
- **Tenant düzeltmesi:** 8 yönetici API ucu kimlik doğrulamasız ve tenant'sızdı (iki işletmenin
  verisi karışıyordu). Düzeltildikten sonra dashboard/rapor rakamlarının düşmesi **beklenen**
  davranıştır, hata değil.

---

## ✅ Tamamlanan turlar

### Cihaz kaydına izin durumları + uygulama sürümü (2026-08-10)

`FCMDevice` artık teşhis için gerekeni tutuyor: `marka`, `app_version` (`3.7.0+40`) ve
kullanılan üç iznin her biri ayrı kolonda — `bildirim_izni`, `kamera_izni`, `takvim_izni`.
"Bildirim gitmiyor" şikâyetinde izin kapalı mı, hangi sürüm, hangi marka artık admin'den
filtrelenerek görülüyor.

- `lib/services/core/fcm_service.dart` — `_collectDeviceInfo` bu alanları da yolluyor.
  İzinler yalnız **sorgulanıyor**, istenmiyor; token yenilemede de güvenle çağrılıyor.
- Bildirim izni iOS'ta Firebase'den okunuyor ("hiç sorulmadı"yı yalnız o ayırt ediyor),
  Android'de permission_handler'dan ("kalıcı red"i yalnız o görüyor). Takvim Android'de
  `uygulanamaz` — orada `add_2_calendar` intent kullanıyor, izin gerekmiyor.
- `notification_page.dart` izin istedikten sonra cihaz kaydını tazeliyor; yoksa alan bir
  sonraki girişe kadar bayat kalıyordu.
- Backend: migration `auths/0009`, `tests/api/test_cihaz_kaydi_izinler.py` (5 test).
  Uç hoşgörülü — tanınmayan izin değeri 400 vermek yerine `bilinmiyor`a çekiliyor.

**Deploy sırası: önce backend, sonra mobil.** Ters sırada yeni alanlar sessizce düşer.

### Faz 1 — üye & antrenör (2026-07-02)

**Üye**

| # | Özellik | Mobil | Backend |
|---|---------|-------|---------|
| 1 | **Yapılacaklar kartları** — bekleyen teyit, borç, değerlendirilmemiş ders, paket bitiyor, telafi süresi | `uye_home_page.dart` + `InfoCardsCarousel`, 5 kart tipi `home_card_model.dart` | `getUyeHomeOzet` (`api/uye/uye_home_ozet.py`) |
| 2 | **Özet şeridi** — Bakiye / Kalan Hak / Telafi | `widgets/uye_ozet_serit.dart` | aynı endpoint (`ozet` alanı) |
| 3 | **Paket bitiş uyarısı + CTA** | Yapılacaklar kartı → muhasebe | `paket_bitis_bildirim` komutu (kalan ≤ 2 **ve** son 45 günde kullanım) |
| 4 | **Takvime ekle + ders hatırlatma** | `add_2_calendar` + ders detay popup'ı | `ders_bildirimleri` → `DERS_HATIRLATMA` push (~1 saat önce) |
| 5 | **Geçmiş Dersler sayfası** | `gecmis_dersler/gecmis_dersler_page.dart`, rota `/uyeGecmisDersler` | `getUyeGecmisDersler` |

**Antrenör**

| # | Özellik | Mobil | Backend |
|---|---------|-------|---------|
| 15 | **Günlük kokpit** — ders/öğrenci sayısı, ilk-son ders, eksik yoklama | `home/widgets/gunluk_kokpit_card.dart` | `getAntrenorGunlukOzet` |
| 16 | **Yoklama push'u** — tıklayınca takvim + yoklama dialogu açılır | `notification_router.dart` `antrenor_yoklama` case'i | `ders_bildirimleri` → `YOKLAMA_HATIRLATMA` push |
| 17 | **Öğrenci detay sayfası** | `ogrenci_detay/antrenor_ogrenci_detay_page.dart` | `getAntrenorOgrenciDetay` (yetki: sorumlu hoca veya son 90 günde ders) |
| 18 | **Çalışma Saatlerim** | `calisma_saatleri/calisma_saatleri_page.dart` | `getAntrenorCalismaGunleri` / `setAntrenorCalismaGunleri` |

**Veri doğruluğu ilkeleri (kalıcı — yeni ekranlarda da geçerli)**
- Tüm hesaplar backend'de tek kaynaktan; Flutter hesap yapmaz.
- Veri alınamazsa ilgili bölüm **gizlenir** (yanlış sayı göstermek yerine).
- Katılım yüzdesi yalnızca yoklaması girilmiş dersler üzerinden; yoklama yoksa `null`/"—".
- Paket-bitiyor uyarısı yalnızca aktif kullanılan paketlere (45 gün filtresi).

### Yönetici ders yönetimi + altyapı (2026-07-24)

- **Yönetici mobilden ders yönetimi:** `lib/screens/7_yonetici/program/` — gün seçici + kort×saat
  ızgarası, oluştur/düzenle/iptal(4 mod)/sil. Backend'de web ile **ortak servis**
  (`etkinlik_kaydet_service.py` + `etkinlik_iptal_service.py`); kural değişiklikleri orada yapılır.
- **Tarih-saat sözleşmesi:** tek standart (`lib/common/tarih_util.dart` ↔ `utils/tarih_util.py`).
  `EtkinlikModelSerializer`'daki gizli `+3 saat` hack'i kaldırıldı.
- **Taşma altyapısı:** app geneli yazı ölçeği clamp'i (`lib/common/ui_scale.dart`),
  `test/support/tasma_yardimcisi.dart` + `test/tasma_ekranlar_test.dart` (boyut×ölçek matrisi).
  **Her yeni sunum widget'ı buraya eklenir.**
- **Profil seçimi:** işletme adı gösteriliyor; aynı kullanıcının iki işletme profili ayırt ediliyor.

### Üye/antrenör geri bildirim turu (2026-07-25 → 07-29)

- Özet şerit etiketleri + yeni rotalar (`uyelikPaket`, `telafiHaklari`, ikisi de `anaHesapOnly`).
- Üyelik/Paket sayfası Paket / Aidat / Tek Ders gruplu ve açılır-kapanır.
- Geçmiş ders etiket-renk düzeni (kulüp onayında / iptal / yönetici-yapılmadı / katılmadı).
- Teyit Bekleyen Dersler sayfası (`teyit_bekleyenler_page.dart` + `getUyeTeyitBekleyenler`).
- Antrenör Eksik Yoklamalar ekranı (`antrenor_eksik_yoklama_page.dart` + `getAntrenorEksikYoklamalar`).
- Alt bar (Takvim · Geçmiş · QR · Hareketler · Hesabım) + drawer; eski menü grid'i silindi.
- Login "beni hatırla" tam ekran overlay'i; profil sıralaması Yönetici > Antrenör > Üye.

### Hakediş saatleri — yönetici + antrenör (2026-08-07)
- **İstek:** Yönetici, bir antrenörün ana/yardımcı antrenör olarak girdiği ders saatlerini ay ay
  görsün; hakediş alacağı dersler ile karar bekleyenler ayrışsın, gruba dokununca o derslerin özeti
  açılsın. Antrenör de aynı ekranı görsün ama **yalnız kendi** hakedişini.
- **Akış (yönetici, 3 ekran):** **ay seç → o ayın antrenör listesi** → antrenör panosu → ders
  listesi. İlk ekranda üstte 4×3 ay ızgarası var; altındaki liste seçili aya göre süzülüyor ve her
  satır o antrenörün **o aydaki** saatlerini gösteriyor (12 ay toplamı değil). Antrenöre
  dokununca pano **aynı ayda** açılıyor, içeride diğer aylara geçilebiliyor. Giriş iki yerden:
  drawer'daki "Hakediş Saatleri" ve Antrenörler sekmesindeki listeye dokunma (o zaman ay seçim
  adımı atlanır, içinde bulunulan aydan başlar).
- **Ay sırası (2026-08-08):** ızgara **eskiden yeniye** akıyor, içinde bulunulan ay **son hücrede**
  ve açılışta seçili. Sırayı backend veriyor (`hakedis_servis.ay_listesi` listeyi ters çeviriyor);
  mobil diziyi olduğu gibi çiziyor, yeniden sıralamıyor. Antrenör satırlarındaki `aylar` dizisi
  aynı listeyle index eşleşiyor — sıra değişirse iki ekran birden kayar. Seçili index veri gelmeden
  çözülemediği için nullable tutuluyor, ilk yüklemede son hücreye sabitleniyor.
- **Akış (antrenör, 2 ekran):** drawer'daki "Hakediş Saatlerim" → doğrudan kendi ay panosu → ders
  listesi. Antrenör seçim adımı yok.
- **Dosya düzeni:** ay panosu ve ders listesi ekranları iki rolde **ortak** —
  `lib/screens/1_common/hakedis/`, modeller `lib/models/1_common/hakedis_models.dart`. Rol farkı
  `HakedisVeriKaynagi` soyutlamasında: `YoneticiHakedisKaynagi(antrenorId)` vs
  `AntrenorHakedisKaynagi()`. Ekranlar rolden habersiz, çatallanmıyor. Role özel tek ekran yönetici
  antrenör seçimi (`lib/screens/7_yonetici/hakedis/`) ve antrenör giriş sarmalayıcısı
  (`lib/screens/3_antrenor/hakedis/`).
- **Yetki:** antrenör uçları antrenör id'si taşımaz; backend kimliği token'dan çözer
  (`request.antrenor`), istekteki id'ye hiç bakmaz. Yani antrenör başkasının hakedişini isteyemez.
- **Ay panosu:** üstte son 12 ayın 4×3 ızgarası (karar bekleyen dersi olan ay noktalı), altında
  seçili ayın iki özet kutusu, oran çubuğu ve rol kartları. Rol kartındaki her satır bir gruptur —
  dokununca ders listesi açılır. Izgara yatay şerit değil: kaydırmadan görünmeyen aylar gözden
  kaçıyordu. Sabit `childAspectRatio` 1.3 yazı ölçeğinde taştığı için `GridView` yerine
  `IntrinsicHeight`'lı `Row`'lar var.
- **Üç durum:** *hakediş alacak* (yeşil), *bekliyor* (turuncu), *hakediş dışı* (gri). Üçüncüsü
  yöneticinin açıkça "almaz" dediği ve iptal edilen dersleri taşır; gizlenmiyor ki ay toplamı tutsun.
- **Kural backend'de** (`api/yonetici/hakedis_servis.hakedis_durumu`): hakediş bayrağı ders onayını
  ezer, bayrak yoksa yöneticinin ders onayına düşülür. Yani ders yapılmadığı halde hakediş
  verilebiliyor — o derslerde onay nedeni/açıklaması ders kartında not olarak gösteriliyor.
- **Ders kartı:** tarih/saat + süre, ürün · kort, katılımcılar (katıldı / katılmadı / yoklama
  alınmamış, plan dışı eklenenler ayrı renk ve "plan dışı" etiketiyle), onay notu.
- **Performans:** 12 ayın tamamı tek istekte gelir, ay değiştirmek yeni istek atmaz. Özet uçları
  backend'de 5 dk cache'li, ders/onay yazıldığında sayaçla geçersizleşir. Ders listesi ayrı uçta —
  katılımcı sorgusu ancak o ekrana girilince çalışsın diye.
- **Backend:** `yoneticiHakedisAntrenorler` / `yoneticiHakedisOzet` / `yoneticiHakedisDersler` +
  `antrenorHakedisOzet` / `antrenorHakedisDersler`, migration `0080` (yardımcı antrenör indeksi).
  İki rolün yanıt gövdesi aynı. Ayrıntı `tenis/history.md` 2026-08-07 girdisi.
- **Ay seçimi 4×3 ızgara** (`hakedis_ay_izgarasi.dart`), yatay kaydırmalı şerit değil — kaydırmadan
  görünmeyen aylar gözden kaçıyordu. Hücre yüksekliği sabit değil: `GridView` + `childAspectRatio`
  1.3 ölçekte taşıyordu, onun yerine `IntrinsicHeight`'lı satırlar kullanılıyor.
- **Renk sistemi** `hakedis_stil.dart`'ta `HakedisRenk` (dolgu + kenar + metin üçlüsü) olarak
  toplandı. İlk sürümde her şey `%10 alfa` yıkamasıydı ve ekran soluk çıkıyordu; artık metin rengi
  dolgunun üstünde okunacak koyulukta ayrı hesaplanıyor, koyu temada açılıyor. Doğrudan
  `ana.withValues(...)` yazmayın.
- **İptal paneli:** iptal edilen ders kartında kim iptal etti, ne zaman, sebep ve açıklama ayrı bir
  kırmızı panelde. İptaller "hakediş dışı" grubunda çıktığı için o satırın karşılığı buradan
  okunuyor.
- **Not — antrenör ne görüyor:** ekran birebir aynı olduğu için antrenör "hakediş dışı" grubunu,
  iptal panelini ve yöneticinin onay açıklaması/nedenini de görüyor. Şeffaflık amaçlı; yöneticinin
  oraya iç not yazması durumunda gözden geçirilmeli.
- Testler: `tests/api/test_hakedis.py` (39), taşma testine 7 bileşen. Ders kartı testleri
  `SingleChildScrollView` ile sarılı — kart gerçekte listede duruyor, çıplak Scaffold'da uzun kart
  ekran boyunu aşıp gerçekte oluşmayan bir dikey taşma üretiyordu.

### Plan dışı katılımcı → ofis bildirimi (2026-08-07)
- **İstek:** Antrenör derse plan dışı üye ya da misafir eklediğinde ofis grubundaki kullanıcılara
  otomatik bildirim gitsin.
- **Backend (asıl iş):** `SetDersKatilimiApiView` kaydetmeden önce ve sonra dersin plan dışı
  tablosunu fotoğraflayıp farkı tek bildirime çeviriyor (`calendarapp/utils/plan_disi_bildirim.py`).
  Antrenör aynı yoklamayı tekrar kaydederse fark çıkmadığı için bildirim de üretilmiyor. Ekleme
  kadar **çıkarma** da bildiriliyor: kişiyi listeden çıkarmak ya da dersi "yapılmadı"ya çevirmek
  ofisin karar kuyruğundan kayıt düşürüyor. Alıcı yalnız `rol=ofis`, isteğin işletmesinde.
  Yeni tip `OFIS_PLAN_DISI_KATILIM`, migration `0081` (yalnız choices).
- **Mobil:** Bildirim tipi sabiti + listede kendi ikonu (`person_add_alt_1`) ve turuncu rengi —
  plan dışı kayıtlar antrenör/yönetici ekranlarında da turuncu "Plan Dışı" etiketiyle gösteriliyor.
  Detay sheet'inde ders künyesi + eklenen/çıkarılan kişi listesi (`PlanDisiBildirimOzeti`); sheet
  içeriği artık kaydırılabilir, değişken uzunluktaki liste küçük ekranda taşmasın diye.
- **Not:** `Roller` enum'unda `ofis` yok — ofis kullanıcısı mobile giriş yapamıyor, bildirimi web
  zilinde görüyor. Mobil taraf, ofis rolü mobile açılırsa ya da bildirimi gören yönetici için hazır.
- Testler: `tests/api/test_plan_disi_ofis_bildirimi.py` (19, gerçek uç üzerinden),
  `test/bildirim_plan_disi_test.dart` (10), taşma testine 4 bileşen (36 kombinasyon).

### Uygulama simgesi rozeti — okunmamış bildirim (2026-08-06)
- **İstek:** Okunmamış bildirim varken uygulama simgesinde sayı/işaret görünsün.
- **Mobil:** `app_badge_plus` paketi + `services/notification/app_badge_service.dart`.
  Tek giriş noktası `NotificationService.refreshUnreadCount`: sunucudan gelen sayı hem zile hem
  simge rozetine yazılır (sayı değişmese bile senkronlanır — arka planda tahmini artırılmış
  olabilir). Tazeleme noktaları: üye/antrenör/yönetici ana sayfa açılışı, `main.dart`'taki
  lifecycle observer ile arka plandan dönüş, önplandaki FCM mesajı, bildirim sayfası kapanışı.
  Çıkışta rozet temizlenir (`AuthService.logout`).
- **Uygulama kapalıyken:** FCM background handler API'ye gidemediği için saklanan sayacı bir
  artırır (`AppBadgeService.artir`) ve Android bildirimine `number` olarak iliştirir; uygulama
  açılınca gerçek değer düzeltir.
- **Backend:** `notification_tasks.py` → `okunmamis_sayisi()` + FCM mesajına
  `apns.aps.badge` ve `android.notification.notification_count`. iOS'ta uygulama tamamen
  kapalıyken rozeti **yalnızca** APNs payload'ı güncelleyebiliyor. Sayacın kapsamı bilinçli olarak
  `getUnreadNotificationCount` ile aynı (profil bazlı) — ayrışsa simge ile zil farklı sayı gösterir.
- **Android:** `AndroidManifest.xml`'e launcher rozet izinleri (Samsung/Huawei/Sony/HTC/Apex/Solid).
  Rozeti desteklemeyen launcher'larda (ör. stok Pixel) sayı yerine Android 8+ bildirim noktası çıkar.
- **Xiaomi düzeltmesi (2026-08-08, 3.7.0'DA YOK — sonraki sürümde çıkacak):** `app_badge_plus`
  Xiaomi/Redmi/POCO'da (MIUI + HyperOS) rozeti "aktif bildirim sayısı" üzerinden kuruyor, yani
  **N için N adet sahte bildirim** gönderiyor (`MiUIBadge` →
  `NotificationBadgeHelper.updateMiuiBadgeHyperOs`; başlık uygulama adı, gövde 1..N). Okunmamışı 15
  olan antrenör uygulamayı açınca gölgeye 15 satır düştü. Artık Android'de plugin'e **yalnız 0**
  gönderiliyor (`AppBadgeService.pozitifRozetYazilir`); pozitif sayıyı gerçek bildirim taşıyor
  (backend `notification_count` + `AndroidNotificationDetails.number`). 0 gönderimi şart: plugin
  bıraktığı bildirimleri o çağrıda siliyor. iOS etkilenmiyor, rozet APNs'ten geliyor.
- Testler: `test/app_badge_service_test.dart` (15), `tests/utils/test_bildirim_rozeti.py` (8).

### Bildirim zili sayacı + tümünü sil (2026-08-06)
- **Bug:** "Tümünü Okundu Yap" sonrası zil "9+" kalıyordu. `getNotifications` son **50** kaydı
  döndürüyor, `getUnreadNotificationCount` ise okunmamışların **tamamını** sayıyordu; mobil de
  ekrandaki id'leri gönderdiği için 50'nin dışındaki eski okunmamışlar hiç işaretlenmiyordu.
  (Model dosyasındaki nota göre en aktif alıcıda ~1.948 bildirim var.)
- **Çözüm:** Backend'de üç uç ortak `profil_bildirimleri(request)` kapsamını kullanıyor;
  `setNotificationsRead` artık `tumu: true` ile profilin tüm okunmamışlarını işaretliyor.
- **Yeni:** `setNotificationsDeleted` — `tumu: true` ya da `ids` ile **soft delete**
  (`is_deleted=True, is_active=False`). `TenantQuerySet` zaten `is_deleted=False` süzdüğü için
  silinenler listeden ve sayaçtan otomatik düşer, veri saklanır.
- **Mobil:** Bildirimler başlığındaki uzun metin butonu ⋮ menüsüne dönüştü — "Tümünü okundu yap"
  (okunmamış varken) + "Tümünü sil" (onay dialogu ile).
- Testler: `tests/api/test_bildirim_api.py` (8 test — kapsam taşması, profil izolasyonu, soft delete).

### Saat dilimi bağımsızlığı (2026-08-02, sürüm 3.6.0)

Ders saatleri artık cihazın saat diliminden bağımsız, kulüp duvar saatiyle gösteriliyor.
Detay `SURUM_NOTLARI.md` → 3.6.0.

---

## 📋 Bekleyen öneriler — sonraki fazlar

### Üye
- **(6)** Gelişim/istatistik ekranı — aylık ders sayısı, katılım %, seviye ilerlemesi, rozet
- **(7)** Antrenör karnesi — ders sonrası not/puanın üyeye "karne" akışıyla açılması (`GorusmeNotu` + `EtkinlikDegerlendirme` altyapısı hazır)
- **(8)** Ders talep sihirbazı — antrenör kartları + uygun saat ısı haritası (`getAntrenorUygunSaatleri` mevcut)
- **(9)** Self-servis telafi — telafi hakkını boş slotlardan üyenin planlaması
- **(10)** Veli görünümü — ana hesabın birden çok çocuğun dersini/borcunu tek ekranda görmesi
- **(11)** Kayıtlı kart / tek tık ödeme + PDF makbuz
- **(12)** Açık kort dersinde hava durumu göstergesi
- **(13)** "Hitting partner" eşleştirme — seviyeye göre antrenman partneri
- **(14)** Boş kort kiralama — self-servis rezervasyon + online ödeme (yeni gelir kanalı)

### Antrenör
- **(19)** Öğrenci gelişim defteri — etiketli hızlı notlar (servis, forehand...), zaman içinde gelişim
- **(20)** Hakediş/kazanç ekranı — aylık yapılan/onaylanan dersler (`EtkinlikOnayModel.antrenor_hakedis_alacak_mi` mevcut)
- **(21)** Haftalık takvim görünümü — doluluk/boşluk genel bakışı
- **(22)** Video/foto geri bildirim — ders videosu yükleyip öğrenciyle paylaşma

### Platform / Ortak
- **(24)** Skeleton (shimmer) loading — spinner yerine iskelet kartlar
- **(25)** Offline cache — stale-while-revalidate ile hızlı açılış
- **(26)** Karanlık tema (Material 3 hazır)
- **(27)** Bildirim tercihleri — kullanıcı hangi bildirim türlerini alacağını seçsin
- **(28)** Üye ↔ antrenör ↔ yönetim iletişim kısayolu (mesaj/WhatsApp deep-link)

> (23) Bottom navigation bar 2026-07-29 turunda yapıldı — listeden çıkarıldı.

---

## 🔍 Test geri bildirimi

Kullanıcı testi sonrası tespit edilen hata/düzeltmeler.

| Tarih | Ekran/Özellik | Sorun | Durum |
|-------|---------------|-------|-------|
| — | — | — | — |

---

## 🗄️ Arşiv — çözülmüş kritik bug'lar

**Takvimde hiç ders gelmiyor / "Dersler yüklenirken timeout" (2026-07-28 çözüldü).**
Uzun süre `TenantManager` filtresi ve backend commit `9d8f554` suçlandı — **ikisi de yanlıştı**
(o commit hiç deploy edilmemişti, veri de temizdi). Gerçek sebep: `getUyeDersProgrami` mobilin
gönderdiği `start`/`end` aralığını yok sayıp üyenin **tüm** derslerini dönüyordu, ağır N+1
serializer'la birlikte endpoint 220sn sürüyordu; `ApiClient`'ın 20sn timeout'u `_loadWeek` içinde
sessizce yutuluyordu → boş takvim. Semptomu asıl büyüten kurulum: **lokal Django + uzak prod DB**
(sorgu başına ~150ms internet gecikmesi). Düzeltme: aralık filtresi (`api/etkinlik/metots.py`),
220sn → 7,6sn. Benzer bir "boş liste / timeout" şikâyetinde **önce endpoint süresine bak, tenant'a
değil.**
