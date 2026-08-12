# Mobil Geliştirme — Durum ve Yol Haritası

Bu dosya mobil tarafın **tek durum dosyasıdır**: ne bitti, ne açık, ne sırada.
(2026-08-04'te `SONRAKI_ADIMLAR.md` buraya eritildi — iki ayrı "bekleyen iş" listesi tutulmuyor.)

Backend `C:\Django\tenis` (branch `master`). Kronolojik değişiklik kaydı orada `history.md`'de;
burada sadece **durum** tutulur, geçmiş anlatılmaz.

---

## 📌 Şu anki durum (2026-08-12)

| | |
|---|---|
| Mobil | `main`, `pubspec` sürümü **3.8.0+40** — tasarım sistemi + koyu tema + iskelet/liste kalıbı turu içeride |
| Testler | `flutter test` **879 geçiyor**, `flutter analyze` temiz |
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
Antrenör tarafı yazıldı ve kullanıcı onayından geçti (bkz. tamamlanan turlar).
**Üye tarafı** (`lib/screens/1_common/yardim_page.dart`) hâlâ **taslak**; onay/düzeltme bekliyor.
Yönetici için ayrı bir yardım sayfası hiç yok — antrenör sayfası kalıp olarak kullanılabilir.

### 2. Heroku Scheduler — komutlar büyük olasılıkla HİÇ koşmuyor
Faz 1'in periyodik komutları Scheduler'a eklenmiş varsayılıyordu; `tenis/history.md`'nin
2026-08-10 log bakımı girdisi **Scheduler addon'unun olmadığını** söylüyor (o yüzden `log_temizle`
`Procfile`'ın release fazına alınmıştı). `Procfile`'da da yalnız `release` ve `web` var — clock
dyno yok. Yani şu komutlar üretimde tetiklenmiyor olmalı:
- `ders_bildirimleri` (10 dk) — üyeye `DERS_HATIRLATMA`, antrenöre `YOKLAMA_HATIRLATMA` push
- `paket_bitis_bildirim` (günlük)
- `update_antrenor_home_cards` — antrenör ana sayfasındaki bilgi kartlarını üreten tek yol

**Mobil etkisi:** yoklama hatırlatma bildirimi ve antrenör bilgi kartı karuseli kodda tamamen
hazır ama pratikte ölü. Yardım sayfasına bu iki konuda soru **bilerek konulmadı** — özellik
çalışmadan cevap yazmak kullanıcıyı yanıltır. Scheduler kurulunca ikisi de eklenmeli.

### 2b. Çalışma saatlerini okuyan canlı akış yok
`AntrenorCalismaGunleriModel` yazılıyor ama hiçbir yerde tüketilmiyor: mobilde
`getAntrenorUygunSaatleri` çağıran ekran yok, web'deki `uygun_saatler_view` ölü uç
(bkz. `tenis/history.md` 2026-07-30) ve `DersTalepPage` rotasına hiçbir yerden yönlendirme yok.
Ekranın kendi bilgi notu ("üyelerin ders talebi oluştururken gördüğü uygun saatleriniz") şu an
**karşılığı olmayan bir vaat** — ya ders talep akışı tamamlanmalı ya da not düzeltilmeli.

### 3. Deploy sonrası gözlem (backend canlıya çıktı, izlenmeli)
- **İptal signal'ları:** `etkinlik_signals/` paketine `__init__.py` eklenmesiyle ~5,5 aydır işlemeyen
  telafi/paket iadesi/borç mantığı devreye girdi. İlk iptallerin finansal kayıtları gözle kontrol
  edilmeli. Geçmiş 5,5 ay geriye dönük işlenmiyor.
- **Tenant düzeltmesi:** 8 yönetici API ucu kimlik doğrulamasız ve tenant'sızdı (iki işletmenin
  verisi karışıyordu). Düzeltildikten sonra dashboard/rapor rakamlarının düşmesi **beklenen**
  davranıştır, hata değil.

---

## ✅ Tamamlanan turlar

### İskelet yükleme + ortak liste kalıbı (2026-08-12)

Tasarım turunun ikinci ayağı. **Ana sayfa tasarımı kullanıcı kararıyla yine kapsam dışı** —
ana sayfada yalnız yükleme göstergeleri değişti, yerleşim aynı kaldı.

**(24) İskelet yükleme.** `lib/screens/1_common/widgets/iskelet.dart` (yeni, ortak):
`Parilti` (ShaderMask tabanlı, harici paket yok), `IskeletKutu`, `IskeletGecikmeli` ve dört hazır
iskelet — `IskeletListe`, `IskeletKart`, `IskeletTakvim`, `IskeletDashboard`. Eski
`7_yonetici/widgets/skeleton.dart` buraya taşındı ve silindi (Türkçe adlandırmaya geçti).

Uygulanan kurallar:
- İskelet gerçek içerikle **aynı yükseklikte** — veri gelince sayfa zıplamıyor.
- **300 ms'den kısa yüklemede hiç gösterilmiyor** (`IskeletGecikmeli`); yanıp sönme beklemekten
  rahatsız edici. `test/iskelet_test.dart` bunu doğruluyor.
- **Aşağı çekip yenilemede iskelet çıkmıyor**, mevcut liste duruyor.
- Renkler temadan (`surfaceContainerHigh` / `surfaceContainerLowest`); eski sabit gri koyu temada
  beyaz şerit bırakıyordu. "Hareketi azalt" açıkken parıltı dönmüyor.

Dönen halka **36 yerde kaldı** ve hepsi kural gereği: buton içi işlem göstergesi, giriş/kayıt/rota
guard akışı, `LoadingSpinner` engelleyici diyaloğu ve görsel indirme (belirlenimli) ilerlemesi.
Sayfa/bölüm seviyesinde tek bir `CircularProgressIndicator` kalmadı.

**Ortak liste kalıbı.** `lib/screens/1_common/widgets/liste_satiri.dart` (yeni):
`ListeSatiri`, `ListeAvatari`, `ListeAyraci`, `ListeGrupBasligi` (+ yapışkan sliver delegate'i),
`ListeTonu` ve kaydırarak eylem (`ListeEylemi`). Kart yığını yerine düz satır: 44 px dairesel
avatar, iki metin satırı, sağda tek değer, saç teli ayraç — aynı alanda 6 yerine ~10 satır.

| Ekran | Ne değişti |
|---|---|
| Yönetici · Üyeler | `CustomScrollView` + `floating/snap` başlık (aşağı kaydırınca arama gizlenir, yukarı çekince döner). **Yapışkan grup başlıkları**: Borçlu / Güncel. Satır `ListeSatiri`; kaydırınca **Ara / WhatsApp**. Boş durum + arama sonuçsuz durumu `BosDurum`. `uye_liste_item.dart` silindi. |
| Yönetici · Borçlu üyeler | Aynı satır kalıbı, satır içi mini butonlar kaydırma eylemine dönüştü. Özet kart token'landı (`Colors.red` → `renkler.hata`). |
| Yönetici · Dersler | `ders_liste_item.dart` `ListeSatiri` üzerine kuruldu; avatar yerine **saat bloğu**. Durum renkleri `ListeTonu`'ya bağlandı. |
| Yönetici · Antrenörler | `antrenor_liste_item.dart` sadeleşti; puan rozeti `sonEk` olarak sağda. |
| Antrenör · Öğrencilerim | 2 sütunlu **kart ızgarası → düz liste**. `_StudentCard` (230 satır) ve kademeli ölçek animasyonu silindi; fotoğraf varsa dairesel avatar olarak geliyor. |
| Üye · Geçmiş dersler | Kart → düz satır + `ListeGrupBasligi` (ay). Durum renkleri sabit hex'ten token'a. |
| Üye · Hesap hareketleri | Zaman çizelgesi korundu; `Colors.green/red` → token, sayfalama göstergesi iskelet oldu. |
| Bildirimler | Tarih grup başlıkları ortak `ListeGrupBasligi` kalıbına geçti (`Dismissible` zaten vardı). |

Kaydırma jesti `Dismissible` ile değil, tek sürükleme denetleyicisiyle yazıldı (satır listeden
atılmıyor, yerinde kalıp eylem şeridini açıyor) — yeni paket eklenmedi. **Uzun basınca** aynı
eylemler alt sayfada listeleniyor: kaydırma ekran okuyucuyla kullanılamıyor.

**Aşağı çekip yenileme** eksik kalan son sayfaya (`calisma_saatleri_page.dart`) eklendi; geri kalan
`RefreshIndicator`'sız dosyalar alt sayfa/diyalog/drawer ya da statik içerik (KVKK, SSS).

**Taşma testi:** `ListeSatiri` (üç varyant), `ListeGrupBasligi`, `AntrenorListeItemWidget` ve dört
iskelet matrise eklendi. `flutter test` 879 yeşil.

### Antrenöre özel Yardım & SSS sayfası (2026-08-10)

- **Sorun:** Antrenör drawer'daki "Yardım" ortak `yardim_page.dart`'a gidiyordu; oradaki 13 sorunun
  tamamı üye diliyle yazılmış (kayıt olma, bakiye, paket, telafi, QR giriş). Antrenör kendi işine
  yarayan tek bir cevap bulamıyordu.
- **Çözüm:** `lib/screens/3_antrenor/antrenor_yardim_page.dart` — 10 bölüm, 50 soru. Yeni rota
  `SayfaAdi.antrenorYardim` (`/antrenor_yardim`, `AccessRule.anyone`), antrenör drawer'ı buraya
  bağlandı. Üye sayfası olduğu gibi duruyor.
- **Kapsam:** yoklama ve ders onayı (8), eksik yoklamalar (3), plan dışı katılımcı ve misafir (6),
  ders devri (7), ders iptali (3), hakediş saatleri (8), takvim (5), çalışma saatleri (2),
  öğrencilerim (5), genel (3).
- **Cevaplar kural kaynaklarından türetildi**, ekran metninden değil: hakediş üçlüsü ve çakışma
  tekilleştirmesi `api/yonetici/hakedis_servis.py`, yoklama kilitleri (`LOCKED_BY_YONETICI`,
  `KARAR_VERILMIS`, `DERS_IPTAL`) `api/etkinlik/metots.py`, devir kuralları
  `api/antrenor/metots.py`, eksik yoklama pencereleri (kokpit bugün+7 gün / sayfa 30 gün)
  `api/antrenor/gunluk_ozet.py`. **Kural değişirse bu sayfa da güncellenmeli.**
- **Yazarken doğrulanan üç yanlış varsayım** — karşılığı olmadığı için soru olarak
  yazılmadı: yoklama hatırlatma bildirimi ve antrenör bilgi kartları Scheduler'a bağlı (açık iş 2),
  çalışma saatlerini okuyan canlı akış yok (açık iş 2b).
- **Dikkat çeken cevaplar:** "Öğrencilerim" listesi ders verilen herkesi değil yalnız *sorumlu
  hocası siz olan* aktif üyeleri gösteriyor; "yapılmadı" nedenleri hiçbir otomatik işlem
  tetiklemiyor, yalnız yöneticinin kararına dayanak oluyor; hakediş bayrağı ders onayını eziyor.
- **Test:** sayfa API çağırmadığı için taşma testine doğrudan girdi
  (`tasmaTesti('AntrenorYardimPage', ...)`). Süit **681 passed**, `flutter analyze` temiz.

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
- ~~**(24)** Skeleton (shimmer) loading~~ — **2026-08-12 turunda yapıldı**, aşağı çekip yenileme
  boşlukları da kapatıldı.
- **(25)** Offline cache — stale-while-revalidate ile hızlı açılış
- **(26)** Karanlık tema (Material 3 hazır).
  *Ölçüm (2026-08-11):* `MaterialApp`'te `darkTheme`/`themeMode` **hiç tanımlı değil**, yani
  uygulama daima açık temada. Buna rağmen 5 ekran `isDark` dallanması taşıyor (`login_page.dart`
  başta olmak üzere neredeyse her widget çift renk hesaplıyor) — **hiçbir zaman çalışmayan ölü
  kod**. (29) girdikten sonra yapılmalı, ölü dallar aynı turda temizlenmeli.
- **(27)** Bildirim tercihleri — kullanıcı hangi bildirim türlerini alacağını seçsin
- **(28)** Üye ↔ antrenör ↔ yönetim iletişim kısayolu (mesaj/WhatsApp deep-link)

### Tasarım / arayüz denetimi — 2026-08-11 turunda **yapıldı**

Üç rolün tüm ekranları tarandı (143 dosya, 47.439 satır), maddeler tek turda kodlandı.
Kapsam dışı bırakılan tek başlık: **ana sayfa kart yerleşimi ve görsel tasarımı** (üye + antrenör),
kullanıcı kararıyla.

**Marka renkleri kulüp formasından alındı:** turuncu gövde + kobalt mavi yazı.
`lib/common/tema.dart` tek kaynak: `Marka.turuncu` (#F4661B) dolgu yüzeylerde, açık zeminde
metin/ikon için koyu hâli (#C2500B, beyazla 4.7:1) `ColorScheme.primary` olarak kullanılır;
ikincil renk kobalt mavi (#2438C8). Koyu temada turuncu açılır (#FF9351), zeminler sıcak
siyaha (#15120F) iner.

| # | Madde | Ne yapıldı |
|---|---|---|
| (29) | Tasarım sistemi / tema token'ları | `lib/common/tema.dart`: marka + semantik renkler (`FitcallRenkleri` ThemeExtension), tipografi, `Bosluk`/`Yaricap` ölçekleri, 20+ bileşen teması. `main.dart`'taki deepPurple tohumu gitti. `context.cs` / `context.renkler` / `context.metin` kısayolları. |
| (26) | Koyu tema | `darkTheme` + `themeMode`; tercih `TemaKontrol` ile cihazda saklanır, çıkışta silinmez. Varsayılan **sistem teması**. Ekranlardaki sabit beyaz/gri/koyu renkler token'a çevrildi (53 dosya). |
| — | **Ayarlar sayfası** (yeni) | `lib/screens/1_common/ayarlar/ayarlar_page.dart`: tema seçimi, bildirim izni, şifre değiştir, KVKK, yardım, sürüm, çıkış, hesap silme. Profil sayfalarındaki ayar menüleri buraya taşındı. Üç rolde de drawer'dan ve profil ekranından açılır. |
| (30) | Üye/antrenör sekme kabuğu | `UyeKabuk` / `AntrenorKabuk`: `IndexedStack` + ortak `KabukAltBar`. Sekmeler: **Ana Sayfa · Takvim · [QR] · Hareketler/Öğrenciler · Hesabım**. Aktif sekme göstergesi (üst çubuk + ikon + kalın etiket), tek renk ikon, geri tuşu ana sekmeye döner. Bildirim zili kullanıcı kararıyla ana sayfa üst barında kaldı. Ana hesap kontrolü kabukta yapılıyor (rota guard'ı sekme geçişinde çalışmaz). |
| (31) | Yönetici sol menü | Kullanıcı kararı: Dersler + Haftalık Program bara alınmadı, sol menünün en üstündeki **"Ders yönetimi"** bölümüne çıkarıldı; drawer aktif sekmeyi işaretliyor. Alt bar da ortak `KabukAltBar`'a geçti. |
| (32) | Takvimde yatay kaydırma | Hafta şeridi `PageView` üzerinde — yana kaydırarak hafta değişir. Ek olarak **Ajanda / Izgara** anahtarı: üye varsayılanı ajanda (yapışkan gün başlıkları, boş saat yok), antrenör varsayılanı ızgara. |
| (33) | Takvim ikizleri | `timeline_view` + `week_day_selector` + `TakvimColors` kopyaları silindi; `lib/screens/1_common/takvim/` altında tek bileşen (`TakvimZamanCizelgesi`, `HaftaGunSecici`, `TakvimRenkleri`). Ders bloğu rolün kendi widget'ı olarak `blokYapici` ile veriliyor. ~900 satır tekrar gitti. |
| (34) | Ders işlemlerinde kalıp birliği | Antrenör takvimindeki 5 diyalog (onay, iptal, devir, detay, iptal bilgisi) `showModalBottomSheet`'e taşındı (`altSayfaGoster`). Ders bloğuna **uzun basınca bağlam menüsü**: yoklama/detay/devir/iptal tek dokunuş. |
| (35) | Erişilebilirlik + autofill | Giriş formunda `AutofillGroup` + `AutofillHints.username/password` + `TextInput.finishAutofillContext()`. Yeni bileşenlerde `Semantics` (sekmeler, gün hücreleri, ajanda satırları, ayar satırları). İkon-only 40 `IconButton`'a tooltip (ekran okuyucu etiketi). |
| (36) | Yardım sayfalarında arama | İki SSS sayfasına `AppBar.bottom` içinde yapışkan arama kutusu; antrenörde ayrıca bölüm çipleri. Sonuç yoksa yönlendiren boş durum. |
| (37) | Giriş ekranı | Buzlu cam katmanları kaldırıldı, düz yüzey + tema renkleri. Form doğrulama, `textInputAction`, klavye tipi, şifre alanına odak zinciri. |
| (38) | Bildirim listesi | `Dismissible` ile kaydırarak silme + **geri alma çubuğu** (sunucuya ancak geri alınmazsa gidiyor; backend `ids` ile silmeyi zaten destekliyordu). Boş durum ikonu kalp → çan, metin eyleme yönlendiriyor. |
| (39) | Profil başlığı | Üye ve antrenörde `expandedHeight` 340/320 → **190**; avatar + ad yatay düzende, kaydırınca ad başlığa oturuyor. Durum rozetleri gövdeye indi. Başlıkta Ayarlar kısayolu. |
| (40) | Ölü kod | `MuhasebeTable` + `ParaHareketTable` ve `data_table_2` bağımlılığı silindi. `antrenor_profil_page.dart` 1.760 → ~950 satır: şifre değiştirme ve hesap silme sayfaları `lib/screens/1_common/hesap/` altında ortaklaştı. |
| (41) | Boş durumlar | Ortak `BosDurum` bileşeni (ikon + başlık + açıklama + eylem). Takvim, ajanda, hesap hareketleri, üyelik/paket ve geçmiş dersler ekranlarına uygulandı. |

**Taşma testi:** `test/support/tasma_yardimcisi.dart` artık uygulamanın gerçek temasıyla render
ediyor ve her bileşen için bir de **koyu tema** koşusu yapıyor (token eksikliğinden doğan hataları
yakalar). Yeni ortak bileşenler (`KabukAltBar`, `HaftaGunSecici`, `TakvimZamanCizelgesi`,
`TakvimAjanda`) matrise eklendi.

**Bu turda kapsanmayan:** ana sayfa tasarımı (kullanıcı kararı — 2026-08-12 turunda da kapsam
dışı bırakıldı), (25) offline cache, (27) bildirim tercihleri, (28) iletişim kısayolu. Yönetici program ekranındaki ızgara sabitleri
(`program_constants.dart`) ve model içindeki durum renkleri `BuildContext` görmediği için
token yerine iki temada da okunan nötr değerlerle bırakıldı.

---

## 🔍 Test geri bildirimi

Kullanıcı testi sonrası tespit edilen hata/düzeltmeler.

| Tarih | Ekran/Özellik | Sorun | Durum |
|-------|---------------|-------|-------|
| 2026-08-12 | Üye + antrenör takvimi, liste (ajanda) görünümü | Üstteki hafta şeridinden hangi güne basılırsa basılsın liste değişmiyor, birden fazla günün dersi görünüyordu (ajanda haftanın tamamını besliyor, `secilenGun`'u kullanmıyordu). | ✅ Liste haftalık kaldı ama seçili günün başlığına kayıyor; başlık vurgulanıyor, o günde ders yoksa "ders yok" satırı çıkıyor. Yan fayda: yapışkan başlıklar `SliverMainAxisGroup` ile artık tepede yığılmıyor. `test/takvim_ajanda_test.dart` |

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
