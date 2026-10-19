# Mobil Geliştirme — Durum ve Yol Haritası

Bu dosya mobil tarafın **tek durum dosyasıdır**: ne bitti, ne açık, ne sırada.
(2026-08-04'te `SONRAKI_ADIMLAR.md` buraya eritildi — iki ayrı "bekleyen iş" listesi tutulmuyor.)

Backend `C:\Django\tenis` (branch `master`). Kronolojik değişiklik kaydı orada `history.md`'de;
burada sadece **durum** tutulur, geçmiş anlatılmaz.

---

## 📌 Şu anki durum (2026-10-18)

| | |
|---|---|
| Mobil | `pubspec` sürümü **3.12.0+45** — "Neler yeni?" popup'ı, yönetici antrenör değerlendirmeleri, başlık bantları, ofis çıkış düğmesi, yönetici Dashboard (bugünün özeti üstte) / Raporlar (iki ayrı dönem seçici, haftalık ısı haritası) / Üyeler (sayılı kart filtreleri). **`v3.12.0` tag'lendi** (2026-10-16) → Codemagic: Play production + App Store incelemesi. Önceki: 3.11.0+44 `v3.11.0` (2026-10-13) |
| Testler | `flutter test` **3621 geçiyor** (2026-10-19, kurumsal temalardan sonra — takım temaları kalkınca tema matrisi küçüldü; yerel 3.41.8), `flutter analyze` temiz; backend `uye-filtre` dalında (dekont + #12) **1408 geçiyor**, kırık yok (2026-10-19) |
| Backend | Canlı: `7788ffa` (Heroku **v327**, 2026-10-18) — ders kayıt talebi + antrenörün salt-okunur tüm programı (`0097_ders_kayit_talebi`); öncesinde başka oturumdan paket hak düzelt/devret, paket notları (`0096_uyeurun_aciklama`), auditlog mobil aktörü. GitHub master canlıyla eşit. Deploy bekleyen yok |
| Mağaza | **3.10.0 ve 3.11.0 mağazaya çıkmadı** (kullanıcı 2026-10-16; 3.11.0 App Store'da 2.3.3 ile döndü, gönderim iptal). 3.12.0'ın mağaza metni ve "Neler yeni?" notları kullanıcı isteğiyle **3.9.0 dahil** sonraki bütün sürümleri anlatıyor. **İkisi bağımsız:** mağaza metni elle yazılır, `surum_notlari.json`'dan beslenmez. Daha önce: 3.9.0 `v3.9.0` (2026-09-08), 3.8.1 |

**3.8.1 yayını (2026-08-18).** "Kayıt ve şifremi unuttum native oldu" turu sürüme alındı; bağlı
olduğu uçlar (`kayitFormVerileri`, `uyeBasvuru`, `sifremiUnuttum`, `sifreSifirlamaGonder`) canlıda
doğrulandı, yayın sırası **önce backend deploy, sonra Codemagic** kuralına uyuldu. `v3.8.1` tag'i
push edildi → Codemagic `yayin` workflow'u Play "production" ve App Store incelemesine yüklüyor.

**Sürüm notu popup'ı (2026-10-16).** Yeni sürümü kuran kullanıcı ilk açılışta kendi profiline ait
yenilikleri tam ekran açılır listede görüyor (üye/antrenör/ofis/yönetici; ofis ve yönetici kabukları
artık `AcilisPopuplari.calistir`'ı çağırıyor, duyuru popup'ı hâlâ yalnız üye+antrenör). Sıra:
doğum günü → duyuru → sürüm notu, açılış başına tek popup. İçerik backend'den geliyor
(`getSurumYenilikleri`), kaynağı backend deposundaki `surum_notlari.json`; adımlar
`SURUM_NOTLARI.md`'nin başındaki "Sürüm notu popup'ı" bölümünde. Kalıcı erişim: Ayarlar ›
"Neler yeni". **Yeni sürümde `surum_notlari.json`'a blok yazmak sürüm başına elle yapılacak işlere
eklendi.**

**Sürüm başına elle yapılacak iş:** `pubspec.yaml`'daki `version:` bump'ı + **`release_notes.json`'ı
o sürüm için yeniden yazmak** + tag. Release notes dosyası güncellenmezse mağazaya bir önceki metin
gider — 3.7.0 ve 3.8.0'da olan buydu. Metin **kısa madde listesi** olarak yazılıyor ve `tr-TR`
(Play) ile `tr` (App Store) girdilerine aynı şekilde konuyor; Play sınırı 500 karakter, uzun
anlatım `SURUM_NOTLARI.md`'de kalıyor. Yayın sonrası
`mobil_uygulama_konfig` adımı aşağıdaki listede.

Codemagic sürüm adını `pubspec.yaml`'daki `version:` alanından, build numarasını mağazadaki
son build'den otomatik alır (`codemagic.yaml`). Yani yayın için **sadece `version:` bump'lanır**.

---

## 🔴 Açık işler

### 14. Takım temaları kalktı, yerine 4 kurumsal tema — kodlandı, sürüm bekliyor (2026-10-19)
**Talep:** takım renk temaları (GS/FB/TS/BJK/Ay-Yıldız) kaldırılsın; marka kılavuzundaki renklerle
5 kurumsal tema olsun, varsayılan turuncu. Kullanıcı sonra beyazı iptal etti → **4 tema**: Turuncu
`FE5000` (Pantone Orange 021C), Mavi `00A9E0` (801C), Yeşil `43B02A` (802C), Siyah `000000`.

**Kullanıcı kararları:** mevcut tema yapısı **aynen** kalır, yalnız renkler kılavuz kodlarına uyar.
Başlık ve alt menü marka renginin koyu tonu, yazı beyaz. Bu ton, beyaz yazıyı 4.5:1 tutturan en
açık ton: turuncuda `D34200`, mavide `007EA7`, yeşilde `338520`. Birebir marka kodu QR butonunda
duruyor. Mavi ve yeşil QR'da beyaz ikon okunmuyor (2.7–2.8:1), bu yüzden ikon koyu (kullanıcı onayı).
**Sonra (aynı gün):** turuncu kahveye kayıyordu → kullanıcı "B" seçeneğini seçti: turuncu başlık
**birebir `FE5000`** (iki modda), beyaz yazı 3.3:1. Bunun için başlık testi eşiği 4.5'ten **3:1**'e
indi (WCAG büyük/kalın metin), seçili başlık çipi de 3:1. Yarı saydam ikon kutusu 2.85:1 (eşik 2.8;
ikon başlığa karşı 3.3). Alt menü `A33400` (koyu modda `9A3100`), kimlik `B83A00→D34200`. Durum
çubuğu ikonları artık zemine göre değil, `onBaslik`'e göre seçiliyor (`baslikDurumCubugu(baslik, yazi)`).
Bir UI/UX ajanı "birebir marka rengi başlık + koyu yazı" önerdi; kullanıcı mevcut yapıyı seçti.

**Kod:** `TakimTemasi` = `binay` (Turuncu; kod `binay` korunduğu için seçim kaybolmaz), `mavi`,
`yesil`, `siyah`. Kaldırılan kodlar cihazda varsayılana düşüyor; eski `siyah_beyaz` → Siyah.
`Marka.turuncu` artık `FE5000` (koyu `D34200`, açık `FE854D`), Binay şeması ve geçişleri buna göre
güncellendi. Kontrast, tema ve taşma testleri yeşil.

**Kalan:** sürüm notu ve mağaza görselleri. Görseller turuncu temayla çekiliyor, renk değiştiği için
yeniden üretilmeli mi, karar kullanıcının (`tool/magaza_gorselleri`).

### 13. Ödeme sayfasına IBAN + karekod, havale yapanlar için dekont yükleme — kodlandı, deploy/sürüm bekliyor (2026-10-18)
**Talep:** ödeme sayfasında kulübün IBAN bilgisi ve bu IBAN'ın karekodu gösterilecek. Havale/EFT ile ödeme
yapan üye, dekontunu uygulamadan yükleyebilecek.

**Bugünkü durum:** üyenin ödeme sayfası Muhasebe sekmesi (`lib/screens/6_muhasebe/muhasebe_page.dart`).
Kartla online ödeme (Param POS, `widgets/payment_summary_sheet.dart` → WebView) kodda var ama **bağlı değil**: "Öde"
butonu bugün `_OdemeBilgiSheet`'i ("Online Ödeme Yakında!" + WhatsApp) açıyor, `PaymentSummarySheet` hiçbir yerden
çağrılmıyor. Havale, ödeme yolunun ilk gerçek içeriği olacak. Mobilde ve backend'de IBAN ya da dekont yükleme yok. Havaleler bugün muhasebeye elle giriliyor: son 180 günde işletme 1'de
400 `Banka` ödemesi (~12,1 M₺, tahsilatın ~%45'i); Datça'da bu dönemde hiç ödeme yok. **Ad çakışmasına dikkat:**
`PaymentOrderModel.dekont_id`, Param POS'un işlem numarası; üyenin yüklediği dekont dosyası değil. Dosya yükleme
için örnek, profil fotoğrafı akışı (`uyeProfilFotografi`, Pillow).

**Kullanıcı kararları (2026-10-18):**
- **Hesaplar:** işletme başına **birden çok** banka hesabı (örn. şirket / şahıs). Her hesapta IBAN, alıcı adı,
  banka adı ve karekod görseli. `IsletmeModel`'de alan yok, `mobil_uygulama_konfig` platform başına satır tuttuğu
  için uygun değil → ayrı model (işletmeye FK, sıra, aktif bayrağı), admin'den yönetilir.
- **Karekod:** kulübün banka uygulamasının ürettiği para alma (FAST) karekodu **görsel olarak** yüklenir, uygulama
  aynen gösterir; IBAN'dan biz üretmiyoruz. IBAN ve alıcı adının yanında kopyala düğmesi.
- **Dekont formu:** yalnız **dosya zorunlu** (fotoğraf, ekran görüntüsü ya da **PDF**). **Tutar** ve **açıklama**
  isteğe bağlı. Havale tarihi sorulmuyor. Üye **hesap seçmiyor**.
- **Bildirim:** yeni dekontta **yalnız ofis** profillerine push: "X ödeme dekontu yükledi. Kontrol edip muhasebeye
  işleyebilirsiniz." **Bildirimde tutar yok.** Yöneticiye gitmez.
- **İşleme yeri: web.** Yeni web Dekontlar sayfası (SayfaYetki ile açılır). Onaylayan dekontu görür; **tutarı, hesabı ve
  ödeme şeklini kendisi seçer** (`OdemeSekli`: Banka, Banka KDV, Şirket, Şahıs…). Onayla birlikte `ParaHareketiModel`'e
  `ODEME` satırı **kendiliğinden** düşer ve dekont ona bağlanır. Bakiye yalnız onayla değişir.
- **Ofis sınırı korunuyor:** ofis mobil uygulamada dekont, tutar ya da hesap görmez; yalnız bildirimdeki üye adı.
  Dekont işini mobilde yapma ekranı **yok** (kullanıcı bu seçeneği reddetti).
- **Üyeye dönüş:** push **yok**. Muhasebe sayfasında "Dekontlarım" listesi: bekliyor / onaylandı / reddedildi.
  **Ret gerekçesi zorunlu**, listede görünür.

**Kodlarken varsayılanlar (kullanıcıya sorulmadı, itiraz gelirse değişir):** dekont başına tek dosya; boyut sınırı **5 MB** (kullanıcı kararı 2026-10-18),
fotoğraflar sunucuda küçültülür (profil fotoğrafı akışı gibi); bekleyen dekontu üye geri çekebilir, işlenmişi
silemez. Üyelerin web'de ödeme sayfası yok, yalnız mobil. Ekran tasarımı: ön muhasebe, UI/UX ve ürün yönetimi ajanlarının uzlaştığı 3 tasarım (Gelen kutusu / İnceleme masası / Defterin içinde) tasarım tuvalinde çizildi (2026-10-18), kullanıcının seçimi bekleniyor.

**Tasarım:** 3 ajanın (ön muhasebe, UI/UX, ürün yönetimi) uzlaştığı üç tasarımdan **Tasarım 2 "İnceleme masası"**
seçildi (ön muhasebenin tercihi; kullanıcı onayı 2026-10-18), ekran duyarlı. Maketler: tasarım tuvali
"IBAN ve Dekont Tasarımları". Dosya sınırı **5 MB**.

**Kodlandı (2026-10-18):**
- **Backend** (`C:\Django\tenis-dekont` worktree'si, dal **`dekont`**, migration **`0098_dekont`**; GitHub'da `origin/dekont`,
  master'a alınmadı, deploy yok): `BankaHesabiModel` (admin'den, karekod görseli yükleme), `DekontModel`, `ParaHareketiModel.dekont`
  (1 dekont → N satır). Kurallar `calendarapp/services/dekont_service.py`; dosya Firebase'de **gizli** blob, yalnız
  yetkili uçlardan. Mobil uçlar `api/dekont/metots.py`: `uyeBankaHesaplari`, `uyeDekontlarim`, `uyeDekontYukle`
  (multipart `dosya`), `uyeDekontGeriCek`, `uyeDekontDosya`. Ofis push'u `OFIS_DEKONT_YUKLENDI` (tutarsız,
  `action_params` yalnız `uye_id`). Web masası `muhasebe/dekontlar/` (≥1400 px üç sütun, 992–1399 iki sütun,
  <992 liste→detay): onay + kardeşe bölme, olası mükerrer kutusu + onay adımlı "Bu kayda bağla", aramalı bağlama,
  gerekçeli ret (çipler tam cümle doldurur), "Onayı geri al", J/K ile gezinme, menüde "Dekontlar (n)" rozeti.
  Son bağlı ödeme satırı silinirse dekont "yeniden kontrol" ile kuyruğa döner (`dekont_signals`). 43 test
  (`tests/api/test_dekont.py`), süit **1357 geçti**.
- **Mobil** (`main`, sürüm yok): Hesap Özeti'nde "Öde" artık hep görünür (borç yoksa "Ödeme yap") ve eski
  "Online Ödeme Yakında!" yer tutucusu yerine **Havale / EFT** sayfasını açar (`6_muhasebe/havale/`): başlıkta
  Hesaplar | Dekontlarım; hesap kartında 4'lü gruplu seçilebilir IBAN, kopyala (✓ + snackbar), açılır karekod +
  Paylaş + "galeriden okut" notu; tam ekran **Dekont yükle** (Kamera / Galeri / PDF — `file_selector` eklendi,
  fotoğraf 2000 px / %85 küçültülür, 5 MB ve tür satır içi denetlenir); yüklemeden sonra Dekontlarım'a geçip yeni
  satırı vurgular; ret gerekçesi listede, geri çekme kaydırarak. Bekleyen dekont varsa bakiye kartının altında
  bilgi satırı. Ofis push'una dokununca ofis üye detayı açılır. Testler: `test/dekont_test.dart` + taşma testleri.

**Kullanıcıya sorulacak tek nokta:** dekont onaylanınca açılan ödeme satırı, her ödemede olduğu gibi mevcut
"ödeme alındı" bildirimini üyeye gönderir (`uye_bilgilendirme_signals`). "Dekont durumu için push yok" kararıyla
çelişip çelişmediği teyit edilmeli; istenirse dekonttan açılan satırlar bu bildirimden muaf tutulabilir.

**Sıra:** backend `dekont` dalı master'a → deploy (migration 0098) → mobil sürüm. Canlıda önce admin'den banka
hesapları (IBAN + karekod görseli) girilmeli; web sayfası kısıtlı kullanıcılarda SayfaYetki'ye
`calendarapp:dekontlar` eklenince görünür. #12 kendi migration'ını `0099` olarak almalı.

### 12. Yönetici Üyeler: birlikte çalışan filtre + sıralama, web'de borç kesinleşmesi — kodlandı, deploy/sürüm bekliyor (2026-10-19)

**Durum (2026-10-19):** aşağıdaki plan kodlandı.
- **Backend:** dal **`uye-filtre`** (worktree `C:\Django\tenis-uye-filtre`, commit `c6d9270`), **`dekont` dalının üstünde**:
  migration `0099_uye_borc_kontrol` `0098_dekont`'a bağlı, yani bu iş canlıya **dekont ile birlikte** (önce dekont)
  çıkar. Push yok, master'a alınmadı. Süit 1408 geçti, 0 kırık. Yeni test: `tests/api/test_yonetici_uye_filtreleri.py`.
- **Mobil:** `main`'de yerel commit (push yok), sürüm yok. `BorcluUyelerPage` silindi; Dashboard
  "Toplam Alacak" kartı ve menüdeki "Borçlu Üyeler" Üyeler sekmesini borçlu ön ayarıyla açar
  (`UyeOnAyarIstegi`). Yeni testler: `test/uye_filtreleri_test.dart`, `test/uye_istatistik_kartlar_test.dart`
  (yeniden yazıldı), taşma matrisine filtre sayfası, sıralama sayfası ve çip şeridi.
- **Plandan farklar / kodlarken netleşenler:** (1) `sadece_sayi: true` eklendi: filtre sayfasındaki canlı sayı
  liste ve istatistik hesaplatmadan yalnız sayar. (2) `ders_once` hiç dersi olmayanı da getirir ("o günden beri
  derse gelmeyen"). (3) Kart vurgusu yalnız filtrelere bakar; sıralama değişince vurgu kalır. (4) Tarihe göre
  sıralamada ikinci satır o tarihi gösterir (son kontrol, son ödeme ve son ders). (5) Web kartı muhasebe üye
  sayfasının en üstünde (tablo uzun olunca aşağıda kayboluyordu).
- **Sıra:** backend `dekont` → `uye-filtre` → master → deploy (0098 + 0099) → mobil sürüm. Mobil backend'den önce
  çıkmaz: eski sunucu `filtreler`'i yok sayar, liste süzülmez.

**Amaç:** yönetici Üyeler sekmesinde, alışveriş sitesindeki ürün aramasında olduğu gibi birden çok filtre
birlikte uygulanır ve üstüne bir sıralama seçilir. Hepsi sunucuda çalışır, liste sayfalı kalır (20'şer).
İki yeni alan **web'de girilir**; mobil bu alanları yalnız okur ve onlarla süzer, çünkü yönetici kabuğu
raporlama içindir ve aksiyon ekranı yoktur. Ofis bu alanları hiç görmez.

**Kullanıcı kararları (2026-10-18):**
- "Borç kesinleşti" ve "son kontrol tarihi" **üyeye ait**, ay satırına değil: her üyenin tek bayrağı ve tek tarihi var.
- **Tamamen elle yönetilir:** kontrolden sonra yeni aidat, geriye dönük ders düzeltmesi, yeniden hesaplama ya da
  ödeme girilmesi bayrağa ve tarihe dokunmaz. Otomatik düşürme ya da "kontrolden sonra değişti" uyarısı yok.
- Son kontrol tarihi **takvimden elle seçilir** (bugün otomatik yazılmaz). "Kesinleşti" ayrı bir onay kutusu; ikisi bağımsız.
- Mobildeki ayrı **Borçlu Üyeler sayfası kalkar.** Dashboard kartı ve menü, Üyeler sekmesini "borçlu + en borçlu önce"
  ön ayarıyla açar; tek liste, tek filtre sistemi kalır.

**Backend (`C:\Django\tenis`)**
1. **Model:** `UyeBorcKontrolModel(BaseAbstract)`, `calendarapp/models/concrete/muhasebe.py`'de. Alanlar:
   `uye` OneToOne→UyeModel (CASCADE, `related_name="borc_kontrol"`), `borc_kesinlesti` Bool (varsayılan False),
   `son_kontrol_tarihi` DateField (null). Kimin ne zaman değiştirdiği BaseAbstract'taki `guncelleyen` /
   `guncellenme_zamani` alanlarından ve auditlog'dan okunur. Satırı olmayan üye kesinleşmemiş ve hiç kontrol
   edilmemiş sayılır.
   - **Neden UyeModel'e alan eklenmiyor:** `api/auth/serializers.py` ve `api/etkinlik/serializers.py` UyeModel'i
     `fields='__all__'` ile dışarı veriyor. Alan oraya eklenirse üyenin kendi profiline ve antrenöre giden
     katılımcı verisine sızar.
   - **Migration:** canlıdaki en son `0097_ders_kayit_talebi` (2026-10-18); bu işinki `0098` olur (başlarken
     master'daki en son numarayı yine kontrol et).
2. **Web** (`muhasebe_list` görünümü, `templates/calendarapp/muhasebe/uye_muhasebe/muhasebe_list.html`): üye
   özetinin yanına küçük bir kart eklenir. Kartta "Borç kesinleşti" onay kutusu, "Son kontrol tarihi" tarih seçici
   ve Kaydet düğmesi var; kayıt AJAX ile yeni `muhasebe/borc-kontrol-kaydet/` ucuna gider (`custom_login_required`).
   Kartın altında "Son güncelleyen X · gg.aa.yyyy ss:dd" yazar. Tarih boş bırakılabilir (temizlemek için) ama
   gelecek bir tarih olamaz; bu, sunucuda doğrulanır.
3. **API** (`yoneticiUyeler`, `api/yonetici/metots.py` → `YoneticiUyelerApiView`): istek gövdesine `filtreler`
   nesnesi ve `yon` gelir. Eski parametreler (`filtre`, `siralama`, `sadece_borclu`, `hepsi`) 3.12.0 ve öncesi
   için **aynı anlamla kalır**. Filtreler VE ile birleşir; boş ya da eksik olan uygulanmaz:

   | Anahtar | Değerler | Anlamı |
   |---|---|---|
   | `durum` | `aktif` / `pasif` | `aktif_mi` |
   | `borc` | `borclu` / `borcsuz` / `fazla_odemis` | bakiye < 0 / = 0 / > 0 (API'de bakiye = ödeme − borç) |
   | `borc_min`, `borc_max` | tutar | borç tutarı (= −bakiye), iki uç dahil |
   | `kesinlesti` | `true` / `false` | `borc_kesinlesti`; satırı olmayan üye `false` sayılır |
   | `kontrol_sonra`, `kontrol_once` | `YYYY-AA-GG` | son kontrol tarihi aralığı, iki uç dahil |
   | `kontrol_yok` | `true` | hiç kontrol edilmemiş (`son_kontrol_tarihi` boş) |
   | `odeme_sonra`, `odeme_once` | `YYYY-AA-GG` | son ödeme tarihi aralığı |
   | `odeme_yok` | `true` | hiç ödeme yapmamış |
   | `ders_once` | `YYYY-AA-GG` | son dersi bu günden önce ("X'ten beri derse gelmeyen") |
   | `kayit_sonra` | `YYYY-AA-GG` | kayıt tarihi (bugünkü `yeni` filtresinin genel hali) |

   Sıralama `siralama` + `yon` (`artan` / `azalan`) ile seçilir. `yon` gelmezse her alanın varsayılan yönü
   uygulanır, böylece eski istemciler aynı sonucu alır. Her sıralamanın sonuna `id` eklenir (sayfalı listede
   aynı üye iki sayfada görünmesin; mevcut kural):

   | `siralama` | Varsayılan yön | Boş değer nerede |
   |---|---|---|
   | `ad` | A→Z | — |
   | `uye_no` | yeni kayıt önce | — |
   | `borc` (eski `bakiye` bunun azalan hali) | en borçlu önce | — |
   | `son_kontrol` | en eski kontrol önce | "hiç kontrol edilmemiş" eskiden yeniye sırada en başta, yeniden eskiye sırada en sonda |
   | `son_odeme` | en eski ödeme önce | "hiç ödememiş" aynı kuralla |
   | `son_ders` | en yeni ders önce | sonda (bugünkü gibi) |

   - **Annotation:** `son_odeme_tarihi`, yalnız `ODEME` türündeki son hareketin `tarih`'idir; web muhasebe
     ekranındaki `_son_odeme_tarihleri` ile aynı tanım. **Tuzak:** `calendarapp/models/concrete/muhasebe.py`'deki
     `ODEME_TURLERI` indirim, iade ve iptali de içeriyor, `muhasebe_views.ODEME_TURLERI` ise yalnız ödemeyi;
     burada ikincisi kullanılmalı. `borc_kesinlesti` ve `son_kontrol_tarihi` `borc_kontrol` üzerinden gelir
     (left join, `Coalesce(False)`).
   - **Yanıt:** her satıra `borc_kesinlesti`, `son_kontrol_tarihi` ve `son_odeme_tarihi` eklenir. İlk sayfaya
     ayrıca `filtre_ozeti: {uye_sayisi, toplam_borc}` gelir; bu, süzülen kümedeki borçların toplamıdır ve ekranda
     "37 üye · 48.200 ₺ borç" diye görünür. `yoneticiUyeDetay` yanıtına da aynı iki alan eklenir.
   - **Ofis sınırı:** `uye_listesi_qs` ofisle ortak. Yeni filtreler, sıralamalar ve annotation'lar **yalnız
     yönetici yolunda** çalışır: ayrı bir `yonetici_uye_filtrele(qs, filtreler)` yardımcısıyla ya da ortak
     fonksiyona yönetici bayrağı vererek. Ofis ucu (`api/ofis/metots.py`) bu parametreleri yok sayar ve para
     alanı döndürmez.
   - **Doğrulama:** bilinmeyen anahtar ya da değer yok sayılır, 400 dönülmez (eski ve yeni istemci kırılmasın).
     Tarihler `%Y-%m-%d` biçiminde okunur, geçersiz tarih yok sayılır. `son_kontrol_tarihi` ve
     `ParaHareketiModel.tarih` DateField olduğu için doğrudan karşılaştırılır. `kayit_sonra` ise
     DateTime olan `olusturulma_zamani` üzerinde çalışır; bugünkü `yeni` filtresi gibi `gun_baslangici` ile.
     Tutar Decimal'e çevrilir, negatif değer yok sayılır.
   - **Testler:** her filtre tek başına ve birlikte; her sıralama iki yönde, boş değerler doğru yerde; sayfa
     sınırında tekrar ya da eksik yok; eski parametrelerle eski davranış; ofis ucu etkilenmiyor; `filtre_ozeti` doğru.
4. Bitince `history.md`'ye bir girdi, `MODEL_ILISKILERI.md`'ye de yeni model eklenir.

**Mobil**
1. **Model ve servis:** `UyeListeItem`'a `borcKesinlesti`, `sonKontrolTarihi`, `sonOdemeTarihi` eklenir
   (`parseApiGun`). `lib/models/9_yonetici/`'ye iki yeni tip gelir: değişmez `UyeFiltreleri` (`copyWith`,
   `toJson`, `aktifSayisi`, `bosMu`) ve `UyeSiralama` (alan + yön). `getUyeler`'e `filtreler:` ve `yon:` eklenir.
2. **Üyeler ekranı** (`7_yonetici/uyeler/`):
   - Arama kutusunun altında iki düğme durur: **Filtrele (n)** ve **Sırala: <seçili>**.
   - **Filtre sayfası** tam boy bir alt sayfadır. Bölümleri: Durum · Borç (borçlu / borçsuz / fazla ödemiş ve
     min–max tutar) · Kesinleşme (tümü / kesinleşti / kesinleşmedi) · Son kontrol (tarihten sonra / önce / hiç
     kontrol edilmedi) · Son ödeme (tarihten sonra / önce / hiç ödeme yok) · Son ders · Kayıt tarihi. Tarih
     alanlarında hızlı çipler ("son 30 gün", "son 3 ay") ve takvimden seçme var. Altta **"124 üyeyi göster"**
     düğmesi ve "Temizle" bulunur. Düğmedeki sayı canlıdır: filtre değiştikçe, beklemeli (debounce) bir `sayfa: 1`
     isteğinin `toplam_uye` değerinden gelir.
   - **Sırala** radyo listeli küçük bir alt sayfadır.
   - Listenin üstünde etkin filtreler çip olarak görünür (her birinde ×) ve "Tümünü temizle" düğmesi bulunur.
     Altında `filtre_ozeti` yazar.
   - **Sayılı kartlar** (Toplam / Aktif / Pasif / Borçlu / Yeni) kalır ve hızlı ön ayar olur: dokununca filtre
     durumu o ön ayara geçer (Borçlu = `borc: borclu` + borç azalan). Kart yalnız filtre durumu tam o ön ayara
     eşitken vurgulu görünür.
   - **Satır:** kesinleşmiş üyede küçük bir "Kesin" işareti çıkar. Son kontrol ya da son ödeme sıralamasında
     ikinci satır o tarihi gösterir (öneri, kodlarken netleşir).
   - Seçimler sekme değişince korunur, uygulama yeniden açılınca sıfırlanır (cihazda saklanmaz).
3. **Borçlu Üyeler sayfası kalkar:** `borclu_uyeler_page.dart` silinir. Dashboard kartı
   (`yonetici_dashboard_page.dart`) ve drawer (`yonetici_drawer.dart`) Üyeler sekmesine geçip borçlu ön ayarını
   uygular. Bunun için `YoneticiMainPage`'de sekmeyle birlikte bir ön ayar geçişi gerekir (ör.
   `ValueNotifier<UyeFiltreleri?>`). Mobildeki `hepsi: true` çağrısı kalkar; sunucu parametreyi eski istemciler
   için tutmaya devam eder.
4. **Üye detay** (`uye_detay_page.dart`): bakiye kartına salt-okunur "Borç kesinleşti · son kontrol 12.10.2026" satırı eklenir.
5. **Testler:** `UyeFiltreleri.toJson` ve ön ayar eşleşmesi için birim testleri. Filtre sayfası, sıralama sayfası
   ve çip şeridi `tasma_ekranlar_test.dart`'a eklenir; kontrast ve gömülü renk testleri de geçmeli.

**Sıra:** backend (model + web + API ve testleri) → deploy → mobil. Mobil sürüm backend canlı olmadan çıkmaz:
eski backend `filtreler`'i yok sayar, ekranda süzülmemiş liste görünür.

**Kapsam dışı (istenirse ayrı iş):** web muhasebe ana listesine (`muhasebe/index`) kesinleşme ve kontrol
sütunları ya da filtreleri; mobilden kesinleşme işaretleme (yönetici kabuğu aksiyonsuz kalır).

### 11. Ders kayıt talebi + antrenörün tüm programı — backend canlı (v327), mobil sürüm bekliyor (2026-10-18)
- **Antrenör:** Takvim başlığındaki ikon → salt-okunur **Tüm Program** (`3_antrenor/program/`): ofisin
  ızgarasının aynısı (ortak `1_common/program/`), kendi dersleri vurgulu, derse dokununca yalnız bilgi.
  Tek eylem **"+ Ders kayıt talebi"**: tarih, kort, başlangıç, bitiş, açıklama (hepsi zorunlu, dolu açılır).
  Bekleyen talep ızgarada kesik çizgili blok; dokununca "Geri çek". Sonuç bildirimle gelir.
- **Ofis:** Ana Sayfa'da "Ders kayıt talepleri (n)" → liste (`8_ofis/ders_kayit_talepleri/`): not, "Programda
  göster", Reddet (gerekçe zorunlu), "Kayıt oluştur" → haftalık programın formu talepten dolu açılır, kayıt
  `yoneticiEtkinlikKaydet`'e `talep_id` ile gider (kurallar haftalık programla aynı, talep aynı işlemde kapanır).
  Ofis programında da talepler kesik çizgili blok; dokununca aynı iki işlem. Web: `/etkinlik/ders-kayit-talepleri`.
- **Kullanıcı kararları (2026-10-16):** antrenör diğer derslerde katılımcıların **tam adını** görür (misafir adı,
  iptal nedeni, onay/hakediş durumu gizli — `api/ders_kayit_talebi/metots.py` beyaz listesi); yeni talepte
  **ofise push** gider. Model (`DersKayitTalebiModel`) üye talebine hazır; üye ekranı ileride.
- **Backend canlı (2026-10-18, Heroku v327):** dal master'ın üstüne rebase edildi, migration `0097_ders_kayit_talebi`
  olarak yeniden numaralandı (`0096_uyeurun_aciklama`'ya bağlı), süit 1313 geçti. Yeni uçlar canlıda yanıt veriyor.
- **Sıradaki:** mobil sürüm (kullanıcı henüz sürüm geçmeyecek). Web sayfası, sayfa yetkisi kısıtlı kullanıcılarda
  admin'deki SayfaYetki'ye `calendarapp:ders_kayit_talepleri` eklenince görünür.

### 10. 3.12.0 yayını — backend canlı (v323), `v3.12.0` tag'lendi (2026-10-16)
- **App Store 3.11.0 (45) reddi:** Guideline 2.3.3, eski 6.7"/6.5" ekran görüntüleri. "Bug fix" muafiyeti
  istendi, Apple kabul etmedi; gönderim kullanıcı tarafından iptal edildi. Yeni görseller
  `tool/magaza_gorselleri/` ile üretildi (6.3" zorunlu grup, 6.9", 6.5", iPad 13") ve 3.11.0 sürüm sayfasına
  yüklendi. Codemagic düzenlenebilir sürümü (DEVELOPER_REJECTED dahil) bulup numarasını 3.12.0 yapıyor ve build'i
  ona bağlıyor — görseller korunur (codemagic-cli-tools `_get_editable_app_store_version`).
- **Yapıldı:** kullanıcı "Neler yeni?" önizlemesini onayladı; 3.12.0 `yayinda_mi` açık (güncelleyen otomatik görür,
  popup yalnız 3.12.0 kurulu cihazda çıkar), `v3.12.0` tag'i push'landı → Codemagic.
- **Sıradaki:** Codemagic build'ini ve App Store incelemesini izlemek; mağazada canlı görülünce
  `mobil_uygulama_konfig` (kullanıcı admin'den yönetiyor).
- **Açık bulgu:** `CreateIptalTalebiApiView` de `user_id`'yi istekten alıyor (değerlendirme uçlarıyla aynı
  sınıf açık); bu turda dokunulmadı.


### 9. 2026-10-12 notlar turu + 10-13 denetim düzeltmeleri — yayında (3.11.0, Heroku v310)
Ayrıntı aşağıda "Tamamlanan turlar"da. Yayın sırası kuralı geçerli: **önce backend, sonra mobil**.
- **Backend:** `python manage.py migrate` (0091 + 0092; 0091 önceki turdan bekliyor). `requirements.txt`'te
  **Pillow 10.4.0** (fotoğraf kırpma; Heroku build kurar). Yeni uçlar: `uyeProfilFotografi`,
  `uyeProfilFotografiSil`, `ofisBekleyenIsler`, `ofisDersYonetimiGun`, `ofisDersOnay`, `ofisGunuOnayla`, `ofisDersHakedis`,
  `ofisPaketDusum`, `ofisManuelTeyit`, `ofisTeyitHatirlat`, `ofisPlanDisiBekleyenler/Secenekler/Karar`. "Paket bitiyor"
  kartının adresi (`/uyelikPaket`) yalnız backend değişikliği — deploy edilince eski uygulamalarda da düzelir.
- **Mobil:** yeni yerel paket `image_picker`. Sürüm **3.11.0+44** olarak yükseltildi, `release_notes.json`
  yeniden yazıldı (349 karakter), `SURUM_NOTLARI.md`'ye 3.11.0 bölümü eklendi. iOS `Info.plist`'e fotoğraf galerisi izni metni eklendi, kamera metni profil fotoğrafını da anıyor.
- **Fotoğraf hattı tek (2026-10-13):** web üye formu da `profil_fotografi_yukle` ile Firebase'e yazıyor, web profil
  sayfası ve admin `profil_fotografi_url`'i gösteriyor. `UyeModel.profil_fotografi` (ImageField) terk edildi — alan
  duruyor ama kimse yazmıyor; ileride ayrı bir migration'la düşürülebilir (**kullanıcı kararı bekliyor**, geri
  dönüşü olmayan veri kaybı).
- **Çıktı boyutu:** sunucu 512 px JPEG üretiyor, üst sınır 200 KB (kalite kademeli iner). Ölçüm: gürültülü en kötü
  durumda 109 KB, normal fotoğrafta 5–70 KB. İstemci 1200 px gönderiyor.
- **Cihazda denenecek:** fotoğraf çek/galeri izni (Android 13+ fotoğraf seçici, iOS izin penceresi), ofis "Hepsini
  onayla", takım renklerinde başlık/alt menü (6 tema × açık/koyu).

**2026-10-13 — iki bağımsız ajan denetimi ve düzeltmeleri.** Süitler yeşildi; bulgular testlerin bakmadığı
yerlerdeydi. Kapatılanlar:
- `baseUrl` yanlışlıkla `baseUrlLocal` commit edilmişti (`e5be4c3`) — bu hâlde çıkan sürüm hiçbir API'ye
  ulaşamazdı. Prod'a alındı. **Tag atmadan önce bu satır her turda kontrol edilmeli.**
- Backend: hakediş düğmesi onay satırı olmayan derste `tamamlandi=False` yazıp dersi sessizce "yapılmadı"
  yapıyordu; hakediş ucunda iptal/bitmemiş ders denetimi yoktu. İkisi de düzeltildi.
- Bekleyen plan dışı sayısı kuyruk / ders sayacı / sol menü rozetinde üç ayrı süzgeçle hesaplanıyordu
  ("yapılmadı" dersin rozeti hiç sıfırlanmıyordu) — tek süzgeç (`bekleyen_suz`).
- Bucket temizliği: `delete_from_firebase` klasörü atıyordu (duyuru görselleri hiç silinmiyordu), üye silinince
  fotoğraf kalıyordu, web "fotoğrafı sil" Firebase'e dokunmuyordu, hesap silme çok işletmeli hesapta profil
  atlıyordu. Hepsi kapatıldı.
- Mobil: üye listesi istatistiklerinde yarış durumu (`SayfaliListe.ek` nesil korumasına girdi); ofis Ana Sayfa boş
  yanıtta sonsuz iskelette kalıyordu; üye kabuğunda `anaHesap` varsayılanı fail-open'dı; profil seçiminde fazladan
  `pop()`; "ders bitti" ölçütü satır ile sheet arasında ayrışıyordu (artık modelde `bittiMi` / `kararVerilebilir`).
- Tema: ders istatistik kartları eşik altı sabit renklerle çiziliyordu (turuncu 2,16:1) — `ListeTonu`'ya çevrildi;
  şifre değiştir / ödeme özeti / ders onay-iptal dialoglarındaki kalan sabit renkler de token'a alındı. Taşma
  matrisine `ProfileHeader`, `ErisimKisitli`, `GecisCubugu`, başlık bandı parçaları ve `KimlikBaslik(yuzeysiz)`;
  kontrast testine `ListeTonu` ön plan/zemin çiftleri eklendi.

**Düzeltmelerin doğrulanması (aynı gün, iki yeni ajan).** İki regresyon yakalandı: ders onay dialoğundaki
iskelet 200 px'lik kutuda 6 px taşıyordu (yükseklik kaldırıldı; görünüm `DersOnayYukleniyor` olarak ayrılıp
taşma matrisine eklendi — kaçmasının sebebi testte olmamasıydı) ve backend'de hakediş güncellemesi satır
kilidini kaybetmişti. Ek olarak: `_anaHesapKontrol` try/catch'siz olduğu için güvenli depo hata verirse sekme
kalıcı iskelette donuyordu; ofis Ana Sayfa `ApiException` dışını yakalamıyordu; katılımcı bölümü hâlâ bayat
`baglam`a bakıyordu (`baslamadiMi` eklendi); `ToggleButtons` seçili yazısı koyu modda okunmuyordu; `Colors.x`
mandal tabanı 176 → 144 indirilerek kazanım kilitlendi.

### 2. Heroku Scheduler — kurulu (kullanıcı teyidi 2026-09-29)
Bu maddede "Scheduler addon'u yok, periyodik komutlar koşmuyor olmalı" deniyordu (dayanak:
`tenis/history.md` 2026-08-10). **Kullanıcı teyidi: Scheduler kurulu, bildirimler gidiyor.** Push'u
gönderen tek yol `process_notifications` olduğu için bu, `ders_bildirimleri` /
`paket_bitis_bildirim` / `update_antrenor_home_cards`'ın da koştuğu anlamına geliyor.

**Kalan küçük iş:** antrenör SSS'ine yoklama hatırlatma bildirimi ve bilgi kartları hakkında soru
**bilerek konulmamıştı** (özellik çalışmıyor sanılıyordu). Artık eklenebilir.

### 3. Deploy sonrası gözlem (backend canlıya çıktı, izlenmeli)
- **İptal signal'ları:** `etkinlik_signals/` paketine `__init__.py` eklenmesiyle ~5,5 aydır işlemeyen
  telafi/paket iadesi/borç mantığı devreye girdi. **2026-09-29 kod denetimi:** 24 saat kuralı,
  telafi / paket / borç dalları ve tekrar çalışma güvenliği doğru; iki hata bulundu ve düzeltildi
  (iptal geri almada onay/finans kalıyordu; iptal tek transaction değildi — bkz. 09-29 turu).
  Prod verisi bu ortamdan okunamadı; kontrol için deploy sonrası çalıştırılacak komut:
  `heroku run python manage.py veri_tutarlilik_kontrol --ders-basi 2026-07-23 --kategori paket,tekders,telafi,onay,ekstra`
  (yeni `ONAY-IPTAL-GERI-ALMA-KALINTISI` bulgusu eski geri almaların bıraktığı kalıntıyı listeler).
  Geçmiş 5,5 ay geriye dönük işlenmiyor.
- **Tenant düzeltmesi:** 8 yönetici API ucu kimlik doğrulamasız ve tenant'sızdı (iki işletmenin
  verisi karışıyordu). Düzeltildikten sonra dashboard/rapor rakamlarının düşmesi **beklenen**
  davranıştır, hata değil.

### 4. Yönetici ekranı veri düzeltmeleri — ciro kararı bekliyor (2026-09-25)
Yönetici ekranlarında yanlış gösterilen rakamlar düzeltildi (ayrıntı: aşağıdaki tur ve
`tenis/history.md` 2026-09-25). Kalanlar:
- **Deploy:** tamam. Backend canlıda (v297'den beri); mobil kısım (reddedilen dersin "Yapılmadı"
  etiketi, "Bekleyen Telafi" etiketi) **3.10.0** ile gönderildi.
- **Ciro kararı (bilinçli olarak dokunulmadı):** ciro yalnız yönetici onaylı dersleri sayıyor ve
  `urun.toplam_ucret` üzerinden hesaplanıyor. Borç ise `ucret` + fiyat geçmişi + katılımcı sayısıyla
  yazılıyor. Onaylar Haziran'dan beri birikiyor (Eylül'de biten derslerin ~%5'i onaylı), bu yüzden
  ciro kartı gerçeğin çok altında. Geç iptal edilip "yapıldı" sayılan dersler de ciroya girmiyor.
- **Süreç:** onay birikimi aynı zamanda tek seferlik derslerin borcunu da bekletiyor (borç onayda
  yazılıyor) — gösterim değil, faturalama konusu.

### 7. Açılış popup'ları + yönetici/ofis duyuruları — yayında (2026-10-10)
- Backend uçları (`getPopupDuyuru`, `yoneticiDuyurular`, `yoneticiDuyuruOkumaDurumu`) Heroku v305'te canlı, mobil 3.10.0
  ile gönderildi.
- Akademiye not (yapılacak): popup yalnız aksiyon gerektiren duyurular için, aynı anda tek popup (form 1'den
  fazlasında uyarıyor), alt başlık popup'ta özet olarak görünür (~120 karakter), kare görsel önerilir.

### 8. Renk temaları — 3.10.0 ile gönderildi (2026-10-10)
Mağaza ekran görüntüleri güncellenecekse **Binay temasıyla** çekilmeli; mağaza metninde kulüp adı geçmez (bkz.
tamamlanan turlar → Renk temaları). Yayın öncesi ekran denetiminde ertelenen küçük maddeler:
- Yönetici rapor bölümleri (üye/antrenör istatistik kartları, ciro/tahsilat/doluluk/performans) hâlâ çok renkli ve
  açık modda bazı ikon/yazılar düşük kontrastlı (turuncu ~2,2, amber "Ort. Puan" ~1,6) — dashboard gibi ana renge
  çekilmeli.
- Antrenör profil başlığı kısa içerikte tam kapanamıyor (kimlik kartından ince şerit kalıyor).
- Takvim bloğu 1.3 yazı ölçeğinde bir saatlik dersi kompakt moda düşürüyor; temanın `showDragHandle`'ı ders
  iptal sayfasında ikinci tutamaç çiziyor; devir bildirimindeki "Reddet" butonları dolu kırmızı.

### 6. Repodaki sırlar — şimdilik bekliyor (kullanıcı kararı 2026-09-29)
`tenis/eventcalendar/settings.py`'de prod DB şifresi, SMS/e-posta/Param şifreleri, repoda da Firebase
servis anahtarı (`eventcalendar/keys/serviceAccountKey.json`) duruyor. Heroku config var'a taşıma +
anahtar yenileme ileride yapılacak.

---

## ✅ Tamamlanan turlar

### Kullanıcı notları turu: tema yayılımı, profil fotoğrafı, ofis bekleyen işler (2026-10-12)

Yedi not netleştirildi (kararlar: tema **A + B**, ofise web Ders Yönetimi'nin hepsi, "Sizden Gelenler" ertelendi).
- **Takım rengi bütün sayfalarda (A + B, HTML maket onaylı):** sayfa zemini baştan sona takımın açık tonu
  (`TemaGecisleri.sayfaRengi`, koyuda derin ton; eski 280 px yıkama kalktı), başlık çubuğu ve alt menü dolu takım
  renginde (`baslik` / `altBar`, yazı `onBaslik` / `onAltBar` tam opak). AppBar'lar tema ile; elle çizilen başlıklar
  (ana sayfalar, dersler, bildirimler, hesap özeti, profil seç, ofis programı, çekmeceler, bildirim diyalogları) ortak
  `BaslikBandi` ile; içerik kayan sayfalarda durum çubuğu `RenkliDurumCubugu` ile başlık renginde sabit. Bant içi zil,
  profil değiştir ve ikon butonları (`BaslikIkonButonu`) başlık rengine uyar; çipler `BaslikCipi`. Kontrast için
  Binay açık birincil C2500B → B54A0A, açık mod `renkler.hata` DC2626 → C62828 (renkli zeminde 4.2:1'e düşüyordu),
  Siyah-Beyaz zemin F1F1F1. Testler: zemin üstü metin/link/durum, başlık/alt menü/seçili çip/QR halkası kontrastı.
- **Profil seç:** gruplar kutulu (rol ikonu + sayı başlıkta, profiller tek yüzeyde) — eski "sade düz liste" kararı
  kullanıcı isteğiyle değişti. Üye profilinde fotoğraf varsa avatar fotoğraf.
- **Profil fotoğrafı:** üye profil başlığındaki avatara dokunup çeker / seçer / kaldırır; fotoğraf telefonda küçültülür,
  sunucuda kareye kırpılıp (512 px JPEG) Firebase Storage'a yüklenir, eskisi silinir. Yeni alan
  `UyeModel.profil_fotografi_url` (0092); API'lerdeki `profil_fotografi` anahtarı artık bu adres. Antrenör öğrenci
  listesi, ofis/yönetici üye listeleri ve detayları, profil seç fotoğrafı gösterir. Cihazdaki profil kopyaları
  (`uye`, `uye_profil`, `kullanici_profiller`) yükleme sonrası güncellenir.
- **"Paketiniz bitmek üzere" kartı** Hesap Dökümü yerine Üyelik & Paketler'e gider (backend `action_route`).
- **Ofis ve yönetici üye listeleri sayfalı:** aşağı kaydırdıkça 20'şer (`SayfaliListe`), arama ve filtre sunucuda (çok
  kelimeli, Türkçe İ/ı duyarlı), ada göre sıralıyken baş harf grupları; sayfa sınırında tekrar/kayıp olmasın diye
  sıralamaya `id`. Borçlu/Güncel ve Aktif/Pasif grupları sayfalı listede tutarsız olduğu için kalktı (borç satırdaki
  kırmızı tutardan, pasif rozetten okunuyor). Yönetici listesinde filtre butonları da kalktı (2026-10-16): başlıktaki
  sayılı kartlar (Toplam · Aktif · Pasif · Borçlu · Yeni) filtrenin kendisi; "Borçlu" en borçlu, "Yeni" bu ay
  kaydolanlar önce.
- **Ofis Ana Sayfa + Dersler (web Ders Yönetimi'nin mobili):** sekmeler Ana Sayfa · Program · Dersler · Üyeler
  (Bildirimler zilde ve menüde). Ana Sayfa: bugünün özeti + bekleyen işler (son 60 günün onay bekleyen dersleri, plan
  dışı/misafir kararları, bugün-yarın katılım cevabı bekleyenler). Dersler: gün gezinmesi, süzgeçler (onay bekleyen /
  cevap bekleyen / iptal), derse dokununca Yapıldı/Yapılmadı (neden + not), kararı kaldır, hakediş Alır/Almaz (yardımcı
  dahil), katılımcı paket düşümü, "Katılacak" ve "Hatırlat"; antrenörün yapıldı dediği dersler için **"Hepsini onayla"**
  (web'de yok, kullanıcı "kullanışlı olsun" dedi; antrenörün yapılmadı dediği ya da bildirmediği derslere dokunmaz).
  Plan dışı kararlar ekranı: borç yaz (tutar) / paketten / ücretsiz, açıklama zorunlu. **Ofisin gördüğü tek para alanı
  plan dışı borç tutarı** (kullanıcı kararı). Kurallar web ile ortak servislerde: web görünümlerindeki mantık
  `ders_yonetimi_service` ve `plan_disi_karar_service`'e taşındı, web görünümleri onları çağırıyor.
- Ofis yardımına 5 soru (bekleyen işler, ders onayı, hakediş, plan dışı karar, katılım cevabı).
- **Uzman denetimi (3 ajan: backend/güvenlik, arayüz/tema, mobil akış) ve düzeltmeleri:** `getMyMembers` profil
  fotoğrafını döndürmüyordu; görüntü işleme Pillow 10.4 + yalnız JPEG/PNG + piksel sınırı + istek boyu sınırı, blob
  silme yalnız `profil/<üye_id>/` altında; hesap silinince (KVKK) fotoğraf da silinir. Ofis: plan dışı kararda ödeyen
  yalnız dersin aday üyeleri, iptal/yapılmadı derse karar yok (kuyruktan da düşer), "Hepsini onayla" ders başına atomik,
  hakediş/paket düşümü girdisi doğrulanıyor (paket düşümü artık istenen durumu gönderiyor, çift dokunuş geri almıyor),
  manuel teyit/hatırlatma yalnız derse kayıtlı üyeye, hatırlatmada 10 dk bekleme; arama 5 kelime / 64 karakter.
  Mobil: ofis sekmeye dönünce ve uygulama öne gelince sayılar sessizce tazelenir, geri tuşu önce Ana Sayfa'ya,
  "Katılım cevabı" bugün herkes cevapladıysa yarını açar; sayfalı listede yenileme sürerken sonraki sayfa istenmez,
  sayfa sınırında tekrar gelen kayıt atlanır, yenileme hatasında "Tekrar dene" baştan yükler; HTML hata sayfası
  (Heroku/413) ekrana basılmaz; fotoğraf kaldırma onay ister; bildirim diyaloglarında başlık yüklenirken de görünür;
  iOS'ta renkli başlıklı ana sayfalarda yukarı esneme boşluğu kalktı; ana hesap korumalı rotalar yalnız üye profilinde.
- Testler: mobil toplam 2505 (yeni: `sayfali_liste_test`, `profil_fotografi_test`, `ofis_ders_yonetimi_test`, taşma
  matrisine ofis/liste/fotoğraf görünümleri, tema kontrastına zemin/başlık/alt menü çiftleri, `api_client_test`); backend +75
  (`test_profil_fotografi`, `test_ofis_ders_yonetimi` — web görünümü dahil —, arama/sayfalama, paket kartı adresi).

### Renk temaları: takım renkleri + geçişli tasarım dili (2026-10-10)

Talep: Galatasaray, Fenerbahçe, Trabzonspor, Beşiktaş ve milli takım renkleriyle temalar; Binay Akademi beyaz-turuncu
kurumsal kalsın; her temada yazı okunur olsun; "renk geçişli, modern, sade, rengarenk olmasın"; tüm ekranlar temaya
göre. Üç tasarımcı ajanı (spor uygulamaları / fintech-taraftar ürünleri / modern tema kişiselleştirme) iki tur
tartışıp ortak tasarım çıkardı; kullanıcı HTML maketi onayladı.
- **Temalar** (`TakimTemasi`, `lib/common/tema.dart`): Binay Akademi (bugünkü açık/koyu palet **aynen**), Sarı-Kırmızı,
  Sarı-Lacivert, Bordo-Mavi, Siyah-Beyaz, Ay-Yıldız. Ana etiket renk adı, kulüp adı yalnız küçük alt yazıda; arma/logo
  yok. Seçim **cihaz bazlı** (`TemaKontrol.takim`, anahtar `tema_takim`, çıkışta korunur), mod (Sistem/Açık/Koyu) ondan
  bağımsız. Ayarlar > Görünüm'de önizlemeli karolar (`RenkTemasiSecici`).
- **Tasarım dili** (`TemaGecisleri` ThemeExtension): ekranda en fazla bir **kimlik yüzeyi** (`KimlikYuzeyi` /
  `KimlikBaslik`: üye ve antrenörde sonraki ders, Hareketler'de bakiye, yöneticide Bugünün Özeti, detay/profil
  başlıkları, giriş bandı, QR kartı, telafi özeti); her sayfanın üstünde zemine sönen **yıkama** (açıkta iki takım rengi
  arasında, koyuda tek ton); ikinci takım rengi yalnız 3 dp **şeritte** (kimlik alt kenarı, QR halkası, ödül çubuğu).
  Butonlar, seçili gün/sekme/çip, listeler, takvim, ızgara, grafikler düz; durum renkleri her temada aynı.
- **Altyapı:** yıkama sayfalarda yazılmaz — tema sayfa geçişini sarıp her rotanın altına `SayfaZemini` koyar; Scaffold
  şeffaf, AppBar üstte şeffaf ve içerik altına kayınca zemin rengi (`WidgetState.scrolledUnder`). Elle yazılmış
  `primary %6` yıkamalar (9 sayfa) kaldırıldı. Liste satırı şeffaf (kaydırma eylemleri açılan genişlik kadar çizilir).
- **Erişilebilirlik paketi:** iptal edilen ders üç takvimde de taramalı (`IptalTaramasi`) + üstü çizili + ikonlu;
  yıkıcı aksiyonlar kenarlıklı (`YikiciButon`, 8 yer); Ay-Yıldız'da butonlar antrasit (bayrak kırmızısı hata
  kırmızısından ayırt edilemiyor).
- **Bugünkü hatalar düzeldi:** `uzerineYazi` artık iki adayın kontrastını karşılaştırıyor (eski 0.45 eşiği açık
  turuncuda 2.2:1 veriyordu); profil seç ekranı sade düz listeye çevrildi (koyu modda kartların yarısı beyaz
  kalıyordu); koyu modda okunmayan "Bugün" rozeti, seçili çipler, alt bar QR ikonu, surface'ı yazı rengi yapan
  yerler, kod penceresindeki koyu kahve yazı, giriş logosunun koyu zemini, üye takvimindeki açık pembe iptal bloğu;
  butonlardaki sabit beyaz yükleniyor göstergeleri butonun yazı rengini alıyor (`ButonYukleniyorGostergesi`);
  günlük kokpit başlığı dar ekranda taşıyordu (yeni taşma testi yakaladı).
- **Rengarenkliğin kaynağı temizlendi:** gömülü hex 225 → 50; temaya ait olmayan eski palet (indigo, mor, QR
  turkuazı, telafi moru, pembe…) sıfır. Kalan hex'ler bilinçli: QR siyah-beyazı, top seviye renkleri, antrenör renkleri,
  fincandaki kahve. `HomeCardModel.color` → `ton` (`ListeTonu`, artık `tema.dart`'ta).
- **Testler (+681):** `tema_kontrast_test.dart` (6 tema × 2 mod, tüm yazı/zemin çiftleri; gradyanlarda 41 noktanın en
  kötüsü; ödül çubuğu görünürlüğü; tasarım kararları), `renk_temasi_test.dart` (tercih/saklama/çıkış, SayfaZemini,
  bileşenler), `gomulu_renk_mandal_test.dart` (gömülü renk sayısı artamaz, eski palet geri gelemez); taşma
  matrisindeki her bileşen ayrıca üç uç takım temasında çiziliyor.

### Yönetici/ofis: Duyurular ve kimlerin gördüğü (2026-10-09)

Talep: yönetici ve ofise "duyurular" ve "duyuruyu okuyanlar" menüsü. Geliştirici / ürün yöneticisi / tasarımcı /
son kullanıcı perspektifleriyle iki tur tartışılıp ortak tasarım çıktı (backend: `tenis/history.md` 2026-10-09).
- **Salt-okunur, tek ekran iki kabuk:** `lib/screens/1_common/duyurular/`; ☰ menüde "Duyurular" (yöneticide Panolar,
  ofiste Üyeler bölümü). Rotalar `yoneticiDuyurular` / `ofisDuyurular` aynı `DuyuruYonetimPage`'i açar; tek fark üye
  satırına dokununca açılan detay (yönetici `UyeDetayPage`, ofis `OfisUyeDetayPage`) — ekran role bakmaz, kabuk geri
  çağırım verir. Oluşturma/düzenleme/kaldırma web'de: okuma durumu sayfasının sağ üstünde "Web panelinde aç".
- **Liste:** Yayında / Planlanan / Geçmiş yapışkan grupları; satırda megafon (önemli → turuncu), alt satır
  "Herkes · 3–17 Eki · Popup · Önemli", sağda "%38" + "54/142"; planlıda başlangıç, ölçülmeyende "ölçülmüyor".
- **Okuma durumu:** özet kartı (oran + çubuk, "Ana sayfadan açan · Popup'ta gören · Detayı açan · N hesap uygulamayı
  kullanmıyor", "İçeriği gör"), isimle arama (Türkçe harf duyarsız), Gördü | Görmedi segmenti. Görmedi iki grup:
  uygulamayı kullananlar / kullanmayanlar (son 60 günde aktif cihaz). Satır başlığı hesabın **profil adları** (veli adı
  ofise gitmiyor); çok profilde hangi üyenin açılacağı sorulur. Segment/arama/kaydırma detaydan dönünce korunur.
- **Ölçüm dili "gördü":** ana sayfa şeridi kaydı yalnız detay açılınca yazıldığı için satırda "Ana sayfadan açtı";
  popupsuz duyurularda oran bu yüzden düşük görünür (prod: ~%1–18). Hesap bazında, payda bugünkü hedef kitle.
- `DuyuruDetaySheet(okunduIsaretle: false)`: yönetici/ofis içeriğe bakınca kendi okuma kaydı yazılmaz.
- Testler: mobil +74 (`duyuru_okuma_test.dart` + taşma matrisine 4 görünüm); backend `test_duyuru_okuma_durumu.py` (7).
- **v2 adayları** (tartışmada ertelendi): "bugün/yarın dersi olup görmeyenler" filtresi (son kullanıcının en çok
  istediği), yönetici dashboard kartı, görmeyenlere push hatırlatma, mobilde "yayından kaldır".

### Açılış popup'ları: doğum günü kutlaması + popup duyurusu (2026-10-09)

Talep: doğum gününde "patlayan konfeti"li kutlama; bazı duyurular açılışta popup, tamamı sığmazsa
"Detaylı bilgi". Son kullanıcı / ürün yöneticisi / sosyal medya uzmanı perspektifleriyle iki tur tartışıldı,
kullanıcı tam ekran tasarımı (seçenek C) seçti. Backend ayrıntısı `tenis/history.md` 2026-10-09.
- **Tek altyapı, tek kural:** `lib/screens/1_common/acilis_popup/` — `AcilisPopuplari.calistir` üye ve antrenör
  kabuğunun `initState`'inden çağrılır. Tetik profil seçimi değil **kabuk açılışı** (token geçerliyken profil
  seçimi atlanıyor). **Açılış başına en fazla bir popup**, doğum günü önce; duyuru bir sonraki açılışa kalır.
  Bildirim akışı sürerken ya da kullanıcı başka sayfaya geçtiyse araya girmez. Kurallar ve kayıtlar
  `lib/services/core/acilis_popup_service.dart`'ta (saf fonksiyonlar, testli).
- **Doğum günü:** yalnız aktif üye profili (antrenör/yöneticide doğum tarihi yok), profil + yıl başına bir kez,
  kayıt cihazda (iki telefonda ikisinde de birer kez — bilinçli). **1 Ocak kutlanmaz** (kullanıcı kararı: yer
  tutucu/sahte tarihler). 29 Şubat → artık olmayan yılda 28 Şubat. Metin kullanıcıdan: "İyi ki doğdun, iyi ki
  bizimlesin! / Tenis, sağlık ve neşe dolu bir sene dileriz." İmza işletme adı (iki işletme var). Konfeti paket
  değil, `KonfetiPatlamasi` (CustomPainter, ~2,4 sn, "hareketi azalt" açıksa yok).
- **Duyuru:** yalnız üye + antrenör (kullanıcı kararı), hesap başına bir kez (sunucu `DuyuruOkuma`; cihaz kaydı
  yalnız ağ hatasına yedek). Görsel ekranın ~2/3'ü, **kırpılmadan sığdırılır** (boşluk bulanık kopyayla dolar);
  görsel yoksa kodla çizilmiş turuncu "DUYURU" posteri. Özet alt başlık, boşsa içerik (4 satır). "Detaylı bilgi"
  yalnız gösterilecek fazlası varsa; `DuyuruDetaySheet`'i açar (sheet `1_common/widgets/`'a taşındı).
- "Gösterildi" kayıtları çıkışta silinmiyor (`StorageService.clearAll` koruma listesi).
- Testler: mobil 1281 → **1324** (`acilis_popup_test.dart` + taşma matrisine iki popup); backend
  `test_popup_duyuru.py` (10).
- **Cihaz testi sonrası (aynı gün):** duyuru detay sayfası koyu temada okunmuyordu (gömülü açık tema
  renkleri) → tema token'ları, resimsizde aynı varsayılan poster. Ana sayfa duyuru şeridi yeniden
  tasarlandı (kullanıcı seçimi A): başlık artık görselin **üstüne yazılmıyor** (beyaz afişte beyaz
  başlık okunmuyordu) — üstte kapak görseli (`DuyuruGorseli`, popup'la ortak: kırpmadan sığdır +
  bulanık dolgu, yoksa poster), altta düz zeminde başlık + özet + "Detaylar"; renk paletleri kalktı,
  şerit 180 → 210 px. Ofise profil değiştirme butonu (haftalık program başlığında) + yardım metni.

### Güvenlik turu + iptal geri alma + ders talep akışı kaldırıldı (2026-09-29)

Mobil + backend baştan sona gözden geçirildi. Ayrıntı `tenis/history.md` 2026-09-29.
- **Ders talep akışı tümüyle kaldırıldı** (kullanıcı kararı; yapılacaksa baştan tasarlanacak). Mobil:
  `DersTalepPage`, servisi, iki DTO, rota ve URL sabitleri. Backend: `setDersTalep`,
  `setGenelDersTalep`, talep listesi/silme, `getUrunListesiVeUyePaketleri`, `getAntrenorUygunSaatleri`,
  `getKortveAntrenorList`, web `ders-talepleri/` ekranı, ölü `uygun_saatler_view` ve modeller
  (migration `0089`). Antrenörün "Çalışma Saatlerim" ekranı **duruyor** (web'de yönetici görüyor).
- **Güvenlik (backend):** oturum istemeyen web uçları kapatıldı — `sms/send/` (herkes firma adına SMS
  atabiliyordu), `muhasebe/kaydet-odeme/`, muhasebe pencereleri, duyuru ajax'ları; `iptal-zorla` silindi.
  Tesis QR uçları oturumsuzdu ve kullanıcıyı gövdedeki `user_id`'den alıyordu (herkes herkes adına
  tesis giriş kodu üretebiliyordu) → token zorunlu, kullanıcı token'dan; event QR'da da aynı. Mobil
  **değişmedi**: `postParsed` zaten token gönderiyor, `user_id` hâlâ gönderiliyor ve yok sayılıyor.
  `getBildirimById` / `uyeKaydet` (oturumsuz, kullanılmıyordu) silindi.
- **Zorunlu güncelleme Android'de hâlâ geri tuşuyla atlanıyordu.** Kök neden: istemci düzeltmesi
  3.9.0'da, `force` ise tanım gereği eski sürümlere gidiyor. Sunucu artık 3.9.0 altı Android'e `blocked`
  gönderiyor (eski sürümler onu geri tuşunu yutan sayfayla gösteriyor — 3.6.0–3.8.1 kodunda doğrulandı).
  "Arka plandan dönüşte de kontrol" kullanıcı kararıyla **yapılmadı**.
  Mobil yan düzeltmeler: iOS zorunlu sayfasında boş "Mevcut: v" (yüklü sürüm artık okunuyor); bloklayan
  ve zorunlu sayfalar küçük ekran + büyük yazıda taşıyordu (kaydırılabilir oldu, taşma matrisine girdi);
  iki sayfanın geri tuşunu yuttuğu widget testiyle sabitlendi.
- **İptal geri alma:** iptalin otomatik onay satırı ve geç iptalin paket düşümü / tek ders borcu kalıyordu
  → geri almada siliniyor, ders yeniden onay bekliyor. İptal/geri alma tek transaction.
- **Paket kalan hakkı** "paket satın alanlar" ve plan dışı karar penceresinde satır sayısıyla
  hesaplanıyordu → düşüm toplamı (mobille aynı kural). İşlevsiz "Seriyi Sil" (web) kalktı, `etkinlik/sil`
  POST oldu.
- **Yardım metinleri onaylandı** (eski açık iş 1), üç düzeltmeyle: üye "Katılamayacağım" cevabı kuralı
  yanlış anlatıyordu (ders yalnız tek kişilikse / herkes hayır dediyse iptal olur; telafi yalnız aidat
  dersinde; geç iptal yapılmış sayılır), "Erişim kısıtlı" listesi eksikti, yönetim "İptali geri al"
  cevabı yeni davranışa göre güncellendi.
- Testler: backend 812 → **877** (`test_qr_ve_kaldirilan_uclar`, `test_web_uclari_yetki`,
  `test_mobil_konfig_direktif`, `test_iptal_geri_alma`, `test_paket_kalan_hak_tek_kural`, tutarlılık
  komutuna 1); mobil 1257 → **1281**. Güvenlik ve iptal düzeltmeleri mutasyonla doğrulandı (koruma
  kaldırılınca ilgili testler düşüyor).

### Yönetici ekranı veri denetimi ve düzeltmeleri (2026-09-25)

Backend uçlarıyla karşılaştırmalı denetim, bağımsız ikinci bir denetimle ve salt-okunur prod
ölçümüyle doğrulandı. Düzeltmeler (ciro hariç, bkz. açık iş 4):
- **Dersler sekmesi 20 derste kesiliyordu** (günde 50–67 ders var). `yoneticiDersler` artık günün
  tüm derslerini tek seferde döndürüyor; mobilde değişiklik gerekmedi. Ofisin Dersler sekmesi de düzeldi.
- **Antrenör performansı şişiyordu** (onay satırlarına JOIN: 2 ders 7 görünüyordu); "x/y ders"teki
  toplam artık iptalleri içermiyor.
- **Toplam Alacak kartı ≠ açtığı Borçlu Üyeler listesi** (kart yalnız aktifleri sayıyordu). Kart
  artık listenin sorgusundan hesaplanıyor.
- **"Ders (Yapılan/Planlanan)"** paydasından iptaller çıktı; Raporlar'daki "Toplam Ders" ile aynı.
- **Doluluk tek tanım:** kortta ders olan süre / kulüp günü (07–23, ofis program ızgarasıyla aynı).
  Önceden dashboard'daki "%doluluk" aslında onay oranıydı, kort raporundaki "dolu saat" ders
  sayısıydı ve kapasite sabit 12 saatti. Kortun `max_etkinlik_sayisi` alanı kullanılmıyor: prod'da
  "Tekli Kapalı" kortunda 5 olduğundan kapasiteyi beşe katlıyordu.
- **Bugünün Özeti:** doluluk seçili dönemden bağımsız olarak hep bugün; "Telafi Ders" etiketi
  **"Bekleyen Telafi"** oldu (değer, kullanılmamış telafi hakkı sayısı — bugünkü telafi dersi değil).
- **Kıyas yüzdeleri** aynı uzunlukta dönemle yapılıyor (bu ay 1→bugün ↔ geçen ay 1→aynı gün).
  Haftalık grafik takvim haftası (Pzt→Paz), toplamı "Bu Hafta" kartına eşit. "Bugün" sekmesinde
  tahsilat yüzdesi gösterilmiyor: ödemelerin %74'ü sisteme günler sonra toplu giriliyor, yarım gün
  ile tam gün kıyası da "aynı saate kadar" kıyası da yanıltıcıydı.
- **Reddedilen ders "Onay Bekliyor" görünüyordu** → "Yapılmadı" (web ile aynı kelime). Dersler
  listesi ve ofis programı aynı kuralı kullanıyor: `durum` geriye uyum için `onay_bekliyor`
  kalıyor, karar `onay_durumu = reddedildi` alanından okunuyor.
- **Isı haritası** 08:00'den önceki dersleri atıyordu; satırlar 07–22 ve dışına taşan saatler.
- Yan bulgu: `DailySummaryCard` başlığı 320px/1.3x'te taşıyordu (taşma matrisinde yoktu); düzeltildi.
- Testler: backend `tests/api/test_yonetici_ekran_dogrulugu.py`; mobil `test/ders_durumu_test.dart`,
  taşma matrisine `DailySummaryCard` ve "Yapılmadı" satırı.

### Rol'e göre yardım sayfaları + 3.9.0 hazırlığı (2026-09-08)

- **Yönetici ve ofis drawer'ındaki "Yardım" üye SSS'ine gidiyordu.** Antrenörde 2026-08-10'da
  düzeltilen hatanın aynısı bu iki kabukta duruyordu: ofis çalışanı "bakiyemi nasıl görürüm",
  "paketim nereden görünür" gibi kendisinde karşılığı olmayan 13 soru okuyordu. Yeni
  [yonetim_yardim_page.dart](lib/screens/1_common/yonetim_yardim_page.dart) **tek dosyada iki
  kapsam** taşıyor: sorular `_Kapsam` (ortak / ofis / yönetici) ile etiketli, sayfa role göre
  süzüyor. Ayrı iki dosya tutmak ortak soruları (QR, bildirim, tema) iki yerde güncellemek olurdu.
  7 bölüm, 30 soru (6 ortak); **ofis 21, yönetici 15** soru görüyor. Yeni rotalar
  `/yonetici_yardim` ve `/ofis_yardim`.
- **Cevaplar kural kaynaklarından türetildi**, ekran metninden değil: iptal modları ve ürün tipi
  kısıtı `etkinlik_iptal_service.py`, kalıcı silmenin etkisi `etkinlik_silme_service.py`, ofisin
  göremediği alanlar `api/ofis/metots.py` beyaz listesi, hakediş grupları `hakedis_servis.py`,
  QR sonuç kodları `qr_sonuc_gorunumu.dart`, bildirim türleri `notification.py`.
  Yazarken doğrulanan gerçek: **yönetici rolüne otomatik gönderilen bildirim türü yok** — bu bir
  soru olarak yazıldı, "gelmiyor" diye şikâyet gelmeden önce cevabı olsun diye.
- **Üye SSS'i ekrana göre yeniden yazıldı.** Taslak metin 3.8.x'ten geride kalmıştı: "Geçmiş" diye
  bir alt sekme yok (Geçmiş Dersler ☰ menüde), profil değiştirme üst köşede değil Ayarlar'da, kayıt
  ve şifre sıfırlama artık tarayıcıda değil uygulama içinde; koyu tema, ajanda görünümü, Ayarlar
  sayfası, misafir daveti ve "erişim kısıtlı" (ana hesap) hiç anlatılmıyordu. 13 düz soru → **7
  bölüm, 25 soru**.
- **Ayarlar'daki yardım bağlantısı dört rolü de doğru sayfaya götürüyor.** Eskiden yalnız
  `_antrenorMu` kontrol ediliyordu, yönetici ve ofis üye sayfasına düşüyordu.
- **Ortak gövde çıkarıldı:** [sss_gorunumu.dart](lib/screens/1_common/widgets/sss_gorunumu.dart)
  (`SssGorunumu`, `SssBolum`, `SssSoru`, `SssKarti`). Üç sayfa artık yalnız veri tutuyor. Yan
  kazanım: üye ve antrenör sayfalarındaki gömülü `Colors.white` / `Colors.blue` yüzünden **koyu
  temada beyaz kalan** soru kartları token'landı.
- **Çalışma saatleri bilgi notu** düzeltildi (ders talep akışı 2026-09-29'da tümüyle silindi).
- Testler: `test/yonetim_yardim_test.dart` (7), taşma matrisine 3 yardım sayfası.
  `flutter test` 1195 → **1232**.
- **Sürüm hazırlığı:** `pubspec` 3.9.0+42, `release_notes.json` 3.9.0 için yeniden yazıldı
  (454 karakter, Play sınırı 500), `SURUM_NOTLARI.md`'ye 3.9.0 bölümü eklendi,
  `api_urls.dart` local'den prod'a geri alındı.

### QR sonuç ekranı + iptal künyesi (2026-09-04)
- **QR doğrulama sonucu yeniden yazıldı.** Eski hâli ortada duran bir karttı ve her hata aynı gri
  "Bilgi" başlığına düşüyordu: backend'in hata KODU hiç kullanılmıyor, yalnız mesajı basılıyordu.
  Görevli "kayıt bulunamadı" ile "süresi dolmuş" arasındaki farkı, dolayısıyla ne yapacağını
  göremiyordu. Yeni ekran (`lib/screens/1_common/widgets/qr_sonuc_gorunumu.dart`) tüm gövdeyi
  kaplıyor — kapıda uzaktan okunsun diye durum rengi ekranın tamamında. Kod artık yedi duruma
  eşleniyor (başarılı / süresi dolmuş / bulunamadı / geçersiz / iptal edilmiş / etkinlik uygun
  değil / genel hata); her birinin kendi ikonu, rengi, başlığı ve **"şimdi ne yapmalı" satırı** var.
  Okutma saati ve tam genişlikte "Sonrakini tara" eklendi (kapıda sıra beklerken asıl iş o).
  Renkler `tema.dart` token'larından; eski ekranda gömülü hex vardı, koyu temada okunmuyordu.
- **İptal künyesi.** Izgarada ders "İptal" rozetiyle görünüyordu ama kimin, ne zaman, hangi sebeple
  iptal ettiği **hiç gönderilmiyordu** — veri backend'de duruyordu (`iptal_eden`, `iptal_tarihi`,
  sebep yöneticinin onay kaydında), yalnız haftalık program ucu taşımıyordu. `_blok()` üç alan daha
  döndürüyor, `iptal_eden` select_related'a eklendi (N+1 yok). Ders işlem sheet'inde kırmızı bir
  künye paneli: iptal eden, tarih, sebep (kod değil okunur etiket) ve iptal notu. Not, iptalde
  `aciklama` alanında tutuluyor — o yüzden iptalde ayrı "açıklama" satırı yerine künyenin içinde.
- Testler: `test/qr_sonuc_test.dart` (15), taşma matrisine 4 QR bileşeni, ders işlem sheet'ine
  4 künye testi; backend `test_yonetici_etkinlik_api.py`'ye 3 test.

### Zorunlu güncelleme Android'de geri tuşuyla atlanabiliyordu (2026-09-04)
- **Sorun:** `force` direktifinde Android'de Play'in tam ekran (immediate) güncelleme akışı
  açılıyor; kullanıcı orada **geri tuşuna basınca** uygulama eski sürümle çalışmaya devam
  ediyordu. Zorunlu güncelleme fiilen isteğe bağlıydı.
- **Sebep:** `in_app_update` eklentisi kullanıcı vazgeçtiğinde `AppUpdateResult.userDeniedUpdate`
  **döndürüyor** (istisna atmıyor). `InAppUpdateAndroid.immediate()` bu dönüşü yok sayıp koşulsuz
  `true` dönüyordu; koordinatör "güncellendi" sanıp bloklayan ekranı hiç açmıyordu. Bloklayan
  ekranın kendisinde `PopScope(canPop: false)` zaten vardı — sorun oraya hiç gelinmemesiydi.
- **Düzeltme:** dönen sonuç artık okunuyor, yalnız `AppUpdateResult.success` başarı sayılıyor.
  Aynı hata `flexible()`'da da vardı: indirme reddedilse bile kurulum tamamlanmaya çalışılıyordu.
  Sarmalayıcıya test için enjeksiyon eklendi (platform + üç Play çağrısı).
- **Kapsam notu:** `immediate`/`flex` direktifleri bloklamak için değil, "yeni sürüm var" dürtmesi
  için; oradaki davranış kasıtlı olarak değişmedi. Bloklayan tek direktifler `force`, `blocked`,
  `maintenance`.
- **Bilinçli olarak açık:** güncelleme kontrolü yalnız `login_page` açılışında koşuyor; uygulama
  arka plandayken `force` yayınlanırsa bir sonraki soğuk açılışa kadar zorlanmıyor (kullanıcı kararı
  2026-09-29: gerek yok).
- **Güncelleme (2026-09-29):** bu düzeltme 3.9.0'da, ama `force` eski sürümlere gittiği için açık
  sürüyordu; sunucu artık 3.9.0 altı Android'e `blocked` gönderiyor (bkz. 09-29 turu).
- Testler: `test/zorunlu_guncelleme_test.dart` (10).

### Ofis (ön büro) profili — aksiyonlar yöneticiden ayrıldı (2026-09-04)
- **İstek:** Ofis çalışanı mobilde yönetici ekranlarını kullanıyordu (QR doğrulama, ders iptali).
  Aksiyonlar ofise taşınsın, yönetici raporlama + genel görünümde kalsın, ofis gizli bilgi
  görmesin. Rol'e göre buton aç/kapa değil, **ayrı kabuk**.
- **Rol:** Backend'de `RolEnum.OFIS` zaten vardı (web yetkisi + plan dışı katılım bildirimi
  alıcısı); tıkanan yer mobildi. `Roller` enum'una `ofis` eklendi, `AuthService` rol eşlemesi,
  `NavigationHelper` yönlendirmesi ve `profil_sec` rol teması/sırası tamamlandı. **Ön koşul:**
  ofis profilinin `SistemKullaniciModel.isletme` alanı dolu olmalı — `token_user` tenant'ı
  oradan çözüyor, boşsa 403 `TENANT_REQUIRED`.
- **Ofise geçen ekranlar:** haftalık program (yeni ders / düzenle / iptal / iptal geri al /
  kalıcı sil — ders formu **antrenör katsayısı ve ekstra ücret dahil** tam hâliyle), günlük ders
  listesi (yöneticiyle ortak), kırpılmış üye listesi + detayı, bildirimler (ofise düşen kararlar
  zaten `rol=ofis`'e gidiyordu, artık mobilde de görünüyor), merkez QR butonunda oluştur+doğrula.
- **Yöneticide kalanlar:** dashboard, raporlar, üyeler (bakiyeli), antrenörler, hakediş, borçlu
  üyeler, QR oluştur. Yönetici kabuğunda **aksiyon ekranı kalmadı**; program ızgarası ve QR
  doğrula çıktı, gün gün ne olduğu Dersler sekmesinden okunuyor.
- **Gizli bilgi sınırı sunucuda:** yeni `ofisUyeler` / `ofisUyeDetay` uçları (`api/ofis/`) beyaz
  liste ile çalışıyor — bakiye, para hareketleri, aylık özet, adres, meslek, veli, acil durum ve
  okul alanları hiç gönderilmiyor. `siralama="bakiye"` ve `filtre="borclu"` de reddediliyor;
  sıralamanın kendisi borç bilgisi sızdırır. `lib/models/10_ofis/` modellerinde o alanlar tanımlı
  bile değil, yani ekran yanlışlıkla gösteremez. Ders yönetimi uçları ortak
  (`@rol_gerekli("yonetici", "ofis")`, 8 uç).
- **Klasör düzeni:** `7_yonetici/program/` → `8_ofis/program/`, `7_yonetici/dersler/` →
  `1_common/ders_listesi/` (iki kabukta da kullanılıyor), QR sheet ve görünen-ad yardımcısı
  `1_common/widgets/` altına alındı. `NotificationPage`'e `gomulu` bayrağı eklendi — sekme
  içindeyken geri oku kabuğu pop etmesin diye.
- Testler: `tests/api/test_ofis_uclari.py` (38), `test/ofis_uye_model_test.dart` (9), taşma
  testine 7 bileşen. `flutter test` 1018 → **1126**, backend 664 → **702**.

### İzin raporlaması düzeltildi — iOS körlüğü (2026-09-04)

Panelde **iOS cihazların %100'ü "bildirim izni verildi"** görünüyordu; aynı sürümde Android'in
red oranı ~%17 olduğu için bu istatistiksel olarak imkânsızdı. Prod ölçümü: iOS 3.8.x'te 189
cihazın 189'u `izinli`, tek bir red yok.

- **Kök neden:** `fcm_service.dart` iOS'ta izin reddedilince cihaz kaydını POST etmeden
  `return` ediyordu. Sonuç: izin vermeyen iOS cihazı panelde **hiç görünmüyor**; bir kere izin
  verip sonra Ayarlar'dan kapatan kullanıcı ise her girişte aynı `return`'e takıldığı için
  sonsuza kadar `izinli` kalıyor. Alan "izin verdi"yi değil "bir zamanlar izin vermişti"yi
  gösteriyordu.
- **Çözüm:** yeni `cihazIzinGuncelle` ucu (token istemiyor). İzin reddinde ve APNs token
  alınamadığında yalnız izin durumu bildiriliyor. Uç `active`/`fcm_token` alanlarına
  **dokunmuyor** — push gönderimi `active=True` filtresine dayanıyor, izin bildirimi hedefi
  değiştirmemeli. Kaydı olmayan cihaz için satır `active=False` açılıyor.
- **İkinci hata — "sorulmadı" ile "reddedildi" karışması:** permission_handler iOS'ta ikisine de
  `denied` diyor, Android'de de ilk sorudan önceki durum `denied`. Bu yüzden 189 iOS cihazın
  hepsinde kamera ve takvim `reddedildi` görünüyordu; oysa çoğu hiç sorulmamıştı. Artık izni
  tetikleyen ekran (`qr_kod_dogrula_page`, `cihaz_takvimi`, `notification_page`) damga bırakıyor
  (`lib/services/core/izin_durumu.dart`), damgasız `denied` → `sorulmadi`. Damgalar oturum
  verisi değil: `StorageService.clearAll` tema gibi onları da koruyor.
  **Not:** mevcut kurulumlarda damga yok, yani gerçekten reddetmiş bir kullanıcı da bir süre
  `sorulmadi` görünür; ilgili ekran bir kez açılınca kendini düzeltir.
- **Üçüncü hata (ilgisiz, aynı turda):** `login_page._acilisAkisi` güncelleme kontrolünü
  try/catch'siz çağırıyordu. Konfig ucu hata verirse (ağ yok, 404) istisna postFrame callback'ten
  sızıyor, `_tryAutoLoginFromApi` hiç çalışmıyor ve "beni hatırla" açıkken form da çizilmediği
  için uygulama açılış ekranında asılı kalıyordu.
- Testler: `test/izin_durumu_test.dart` (10 test, eşleme saf fonksiyona çıkarıldı),
  `tests/api/test_cihaz_kaydi_izinler.py::TestIzinUcu` (5 test).

**Deploy sırası: önce backend, sonra mobil.** Ters sırada mobil `cihazIzinGuncelle`'i 404 alır
(akış bozulmaz, izin bildirimi sessizce düşer).

### Kayıt ve şifremi unuttum native oldu (2026-08-18)

**Sorun.** İki ekran da ara duraktı: `RegisterPage` / `ForgotPasswordPage` ilk kareden sonra web
sayfasını (`/auths/register`, `/auths/forgot-password`) tarayıcıda açıp kendini kapatıyordu.
Kullanıcı uygulamadan çıkmış oluyor, mobil tarih seçici/klavye davranışını kaybediyor, dönüşte ne
olduğunu anlamıyordu.

**Kayıt — 4 adımlı sihirbaz** ([kayit_sihirbazi.dart](lib/screens/4_auth/widgets/kayit_sihirbazi.dart)).
Web formundaki alanların **tamamı** duruyor (kullanıcı kararı), yalnız adımlara bölündü:

| Adım | İçerik |
|---|---|
| 1 | Kulüp, ad, soyad, doğum tarihi (takvim), cinsiyet |
| 2 | Cep telefonu, e-posta, adres, acil durum kişisi |
| 3 | **Doğum tarihine göre değişir:** 18 yaş altı → anne/baba + okul; üstü → meslek |
| 4 | Tenis geçmişi, program tercihi, KVKK onayı |

Üstte ilerleme çubuğu + "2 / 4"; her adımda kendi `Form`'u doğrulanır, adım değişince sayfa başa
kayar. Doğrulama **iki katmanlı**: mobil anında geri bildirim verir, son söz sunucudaki
`UyeMobilKayitForm`'undur — mobil kuralın kopyasını değil özetini taşır.

**Şifremi unuttum.** Kullanıcı adı ya da 10 haneli telefon → sıfırlama bağlantısı e-postaya. Bir
numara birden çok hesaba bağlıysa (veli kendi numarasını çocuğunun kaydına yazmış) **hesap seçim
adımı** çıkar; ad ve e-posta maskeli listelenir, çünkü ekran kimlik doğrulamasından önce geliyor.
Şifrenin kendisi yine e-postadaki tek kullanımlık bağlantıda değiştirilir (mevcut yapı korundu).

**Yan kazanım — Material Türkçesi.** `MaterialApp`'te `localizationsDelegates` hiç tanımlı değildi:
tarih seçici "Select date" / `mm/dd/yyyy`, metin seçim menüsü "Paste" diyordu. `flutter_localizations`
eklendi, uygulama `tr-TR`'ye sabitlendi.

**Backend** (`C:\Django\tenis`): `api/auth/kayit_metots.py` — dört kimlik doğrulamasız uç
(`kayitFormVerileri`, `uyeBasvuru`, `sifremiUnuttum`, `sifreSifirlamaGonder`), IP başına sayaçla
sınırlı. Şifre sıfırlamanın kimlik tespiti `auths/sifre_sifirlama_service.py`'ye taşındı; web
ekranı da artık oradan okuyor (kural iki yerde yaşamıyor). Aynı kişinin ikinci başvurusu hata değil,
"başvurunuz zaten sırada" bilgisi.

**Test:** `test/kayit_sihirbazi_test.dart` (7 akış testi: eksik alan, veli adımı, telefon biçimi,
KVKK zorunluluğu, gönderilen gövde, takvimin iki cihaz ölçeğinde açılması), taşma matrisine
`KayitSihirbazi` (2 varyant) ve `HesapSecimListesi`. Backend
`tests/api/test_mobil_kayit_ve_sifre.py` (15 test).

**Düzeltme — doğum tarihi takvimi açılmıyordu (2026-08-18).** Cihazda "Takvimden seçin"e basınca
seçici yerine kırmızı hata kutusu çıkıyordu: `'maxScale > minScale': is not true`. Sebep bizim yazı
ölçeği clamp'imiz ([ui_scale.dart](lib/common/ui_scale.dart)) ile Material tarih seçicisinin kendi
başlık clamp'inin çakışması — seçici başlığı `min(mevcut ölçek, 1.4)` istiyor, cihaz ölçeği 1.0 (ya
da altı) iken bu bizim 1.0 alt sınırımızla aynı noktaya düşüyor ve `TextScaler.clamp`'in döndürdüğü
tip sıfır genişlikli aralığı kabul etmiyor. Hazır `clamp` yerine aynı işi yapan kendi `TextScaler`
sınıfımızı yazdık; `TextScaler`'ın taban `clamp`'i bu durumu güvenle sabit ölçeğe indiriyor, cihazın
doğrusal olmayan ölçek eğrisi de korunuyor. Hata yalnız debug build'de patlıyordu (release'de
`assert` eleniyor), ama sihirbaz testleri de uygulamanın `MaterialApp.builder`'ını kurmadığı için
görmüyordu — test kurulumu gerçek uygulamayla eşitlendi.

### Test turu düzeltmeleri (2026-08-17)

3.8.0'ın cihazda denenmesinden gelen 11 madde. Sürüm bump'ı **yok** — yayın ayrı kararla yapılacak.

| # | Sorun | Çözüm |
|---|---|---|
| 1 | Üyede "Hareketler" sekmesinde geri oku **siyah ekran** bırakıyordu | `MuhasebePage` geri okunu `Navigator.canPop()` ile çiziyor (profil sayfasının kalıbı). Kabuk sekmesi olarak açılınca ok yok. Aynı hata `AntrenorOgrencilerPage`'de de vardı, o da düzeltildi. |
| 2 | Koyu temada QR kodu okunmuyordu | Yeni ortak `qr_kod_gorseli.dart`: zemin her temada **beyaz**, modüller siyah. Tesis girişi ve etkinlik daveti sayfaları bu widget'ı kullanıyor. |
| 3 | Antrenör ajandasında satırın altında **antrenörün kendi adı** yazıyordu | `TakvimAjanda.altSatir` geri çağrımı eklendi; antrenör katılımcı adlarını, üye eskisi gibi antrenör adını görüyor. |
| 4 | Yoklama popup'ında "x kişi katıldı sayılır" | Sayı yerine **isim rozetleri** ("Katıldı sayılacaklar" başlığıyla). |
| 5 | Ayarlar'daki "Yazı boyutu" yalnız sistem ayarını açıyordu | Satır kaldırıldı. |
| 6 | İptal edilen dersler hakediş **"Bekliyor"** grubunda çıkıyordu | Kural (`hakedis_servis.hakedis_durumu`) artık iptali kendisi görüyor: bayrak yoksa iptal → `disi`. Yönetici "hakediş alır" işaretlerse ders yine `hakedis` grubunda. Sebep: iptal onay satırı her iptalde yazılmıyor (ürünsüz ders, sinyal kapalıyken yapılan iptal). |
| 7 | "Hakediş dışı" satırının sebebi görünmüyordu | Backend `hakedis_bayragi` alanını da döndürüyor; kart her `disi` satırında sebep paneli çiziyor: iptal künyesi / "yönetici ders yapılmadı dedi" / "yönetici hakediş almaz dedi". İptal paneli artık alanlar boş gelse de çıkıyor. |
| 8 | "Yapılacaklar" başlığı | **"Bekleyen İşlemler"** (yardım metni de güncellendi). |
| 9 | Sonraki ders kartında "Takvime git" | **"Takvime ekle"** — dersi telefonun takvimine ekliyor (üye + antrenör). Ortak yardımcı: `lib/common/cihaz_takvimi.dart`. |
| 10 | Değerlendirme kartı takvime götürüyordu | Backend kartın rotası `/dersler` → `/uyeGecmisDersler`. |
| 11 | Takvimdeki "bugüne dön" butonu anlaşılmıyordu | Başlıktaki ikon kaldırıldı; hafta şeridine **yazılı "Bugün" butonu** eklendi (iki rol de aynı şeridi kullanıyor). |

**Backend değişiklikleri** (`C:\Django\tenis`): `api/yonetici/hakedis_servis.py` (kural + `hakedis_bayragi`),
`api/uye/uye_home_ozet.py` (kart rotası). Süit 595 yeşil; `tests/api/test_hakedis.py`'ye iptal
kural tablosu ve onay kaydı yazılmamış iptal senaryoları eklendi.

**Taşma testine eklenenler:** `QrKodGorseli`, `TakvimAjanda (katılımcı adlı alt satır)`,
`HakedisDersKarti (hakediş dışı, yönetici almaz dedi)`.

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
iskelet matrise eklendi.

#### Aynı gün gelen düzeltmeler (test geri bildirimi)

- **Yönetici üye listesi bomboş açılıyordu.** Sebep: `ListeGrupBasligiDelegate` bildirdiği
  yükseklikten kısa çiziliyordu; yapışkan başlıkta `paintExtent < layoutExtent` olunca viewport
  `SliverGeometry is not valid` atıyor ve **tüm sayfa** boş kalıyor. Delegate artık çocuğu
  `SizedBox(height: yukseklik)` ile sarıyor. Sayfanın gövdesi `UyelerGorunumu`'na ayrıldı
  (CLAUDE.md kuralı) ve beş varyantı taşma testine girdi — regresyon bir daha sessiz geçmez.
- **Antrenör satırında puan yoksa "—" yazıyordu.** Tire bir durum değil, boşluk işareti. Rozet
  aynı biçimde kalıp ton değiştiriyor: dolu yıldız + puan, ya da içi boş yıldız + "Puan yok".
  `ListeSatiri.sonEk` esnek yapıldı (dar ekran + 1.3x yazıda satırı taşırıyordu).
- **Grup başlığı belirginleşti:** 11 px gri etiket → 14 px kalın, ana metin renginde, altında
  hairline; sayaç sağda ayrı. Kaydırırken fark edilmiyordu.
- **Bildirim satırı sosyal uygulama kalıbına yaklaştırıldı:** zaman ayrı satır yerine gövdenin
  devamında (Instagram/X), okunmamış dolgusu %35'ten %18'e indi (kart gibi görünüyordu),
  okunmamış noktası marka rengine geçti, satırlar arasına `ListeAyraci`, boş durum ortak
  `BosDurum`'a taşındı, kalan gömülü kırmızılar token'landı.

`flutter test` 939 yeşil.

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
  çalışma saatlerini okuyan canlı akış yok (ders talep akışı 2026-09-29'da silindi).
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
- **Not (güncellendi 2026-09-04):** o tarihte `Roller` enum'unda `ofis` yoktu, bildirim yalnız web
  zilinde görülüyordu. Ofis profili mobile açıldı; bildirim artık ofis kabuğunun kendi sekmesinde.
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
- **Sizden Gelenler — üye paylaşımları** (kullanıcı notu 2026-10-12, "şimdilik dursun"): üyelerin ders/turnuva
  fotoğrafı-videosu gönderip uygulamada yayınlandığı bölüm. Tasarlanırken: onay (moderasyon) akışı, çocuk üyelerin
  görüntüsü için veli izni / KVKK, depolama (Firebase) ve kimin göreceği netleşmeli.
- **(6)** Gelişim/istatistik ekranı — aylık ders sayısı, katılım %, seviye ilerlemesi, rozet
- **(7)** Antrenör karnesi — ders sonrası not/puanın üyeye "karne" akışıyla açılması (`GorusmeNotu` + `EtkinlikDegerlendirme` altyapısı hazır)
- **(8)** Ders talep sihirbazı — antrenör kartları + uygun saat ısı haritası. Eski yarım akış (`DersTalepPage`,
  `setDersTalep`, `getAntrenorUygunSaatleri`, tablolar) 2026-09-29'da **tümüyle silindi**; yapılırsa baştan tasarlanacak
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

### Etkileşim / oyunlaştırma — araştırma notu (2026-08-21)

**(42) Servis Düellosu — asenkron 1v1 zihin oyunu.** *Fikir aşamasında, kodlanmadı.*
Amaç uygulamayı oyuna kaydırmak değil; üyenin gün içinde 2-3 kez uygulamaya uğramasını
sağlayan hafif bir etkileşim katmanı kurmak.

**Neden bu format:** gerçek zamanlı PvP (Tennis Clash modeli) saniyelik eşleştirme havuzu
ister — akademi ölçeğinde salı 14:00'te rakip bulunamaz. Asenkron sıra tabanlı düello bu
sorunu kökten ortadan kaldırır ve mevcut REST + FCM altyapısına oturur, WebSocket gerekmez.

**Kanıt tabanı (2026-08-21 araştırması):** tam kombinasyon (tenis + asenkron düello) hit
olarak yok, ama parçaları ayrı ayrı kanıtlı:
- *Line Clipper: Tennis Tactics* (Steam, Kas 2025) — sıra tabanlı tenis; el yapısı
  nişan al → toparlan → **rakibin vuruşunu tahmin et ve karşılığını hazırla** → topa git.
  Tasarım kanıtı var, ticari kanıt yok (2 inceleme).
- *Penalty Challenge Multiplayer* — mekanik birebir aynısı, futbol hali; "aynı köşeye çok
  atarsan okunursun".
- *Trivia Crack* — 800M indirme; yapısal şablon: asenkron sıra + "rakibin oynadı" push'u.
- *Yomi* (Sirlin) — ağırlıklı taş-kağıt-makas'ın şans değil beceri olduğunun tasarım kanıtı.
- Tavan: Top Eleven 300M kayıtlı kullanıcı, Golf Clash 1,2 milyar $ hasılat.
- Teorik dayanak: teniste servis yönü seçimi literatürde karma strateji dengesi olarak
  incelenen gerçek bir tahmin düellosu (Walker-Wooders).

**Kurallar (taslak):**
- Maç = tek oyun (game), 4 sayı alan kazanır; ~10-16 el, 2-3 güne yayılır.
- El = **eşzamanlı gizli seçim**. Servis atan yön (T / gövde / dışarı) + tip
  (düz / kick / slice); karşılayan yalnız yön tahmin eder. Sunucu ancak iki taraf da
  girdiğinde açar — kimse diğerinin seçimini önce göremez.
- Çözüm ağırlıklı, saf taş-kağıt-makas değil: tahmin tutarsa karşılayan baskın,
  tutmazsa ace; "gövde" orta risk (tutmasa da tam kaybettirmez, tutunca az kazandırır).
  Tip katmanı: düz hızlı ama okununca ölür, kick güvenli ama az kazandırır, slice saptırır.
- Rakibin son 10 seçiminin dağılımı gösterilir (beceriyi bu görünürlük yaratıyor) —
  **gürültülü ve gecikmeli** gösterilmeli, yoksa sömürülür.
- Rakip yoksa **hayalet rakip**: gerçek oyuncuların geçmiş seçim dağılımından üretilen bot.
- **Günlük el hakkı sınırlı** (Wordle mantığı). El hakkı derse katılımdan / kort
  rezervasyonundan / skor girmekten kazanılır → oyun akademiye trafik pompalar, ondan çalmaz.
  Oyun puanı gerçek ödüle döner (ücretsiz kort saati, ip/grip, ders indirimi).

**Teknik kapsam (tahmin):** iki tablo (`duello`, `duello_el`), 5-6 endpoint, iki ekran
(aktif düellolar listesi + el ekranı), bir FCM tetikleyicisi. Kritik nokta: gizli seçimlerin
sunucu tarafında iki taraf da girene kadar açılmaması.

**Bilinen risk:** mekaniğin derinliği sınırlı, 2-3 hafta sonra düzenli oynayanlar birbirini
okur. Çözüm: sezon rotasyonu + oyuncu stili kartları (agresif vuruşçu / duvar / servis-vole,
aralarında gerçek tenisteki üstünlük ilişkisi). Line Clipper'ın çok fazlı ral yapısı derinlik
eklemenin diğer yolu ama **ilk sürüme koyulmamalı** — önce tek elin tutup tutmadığı
20-30 kişilik kapalı testle ölçülmeli.

**Alternatif / tamamlayıcı fikirler (aynı araştırmadan):**
- **(43) Kulüp merdiveni (ladder)** — üye üstündeki 3 kişiden birine meydan okur, kortu
  uygulamadan ayırır, skoru girer, sıralama oynar. Oyun değil, gerçek maçın oyunlaştırılması;
  kort doluluğunu ve ders satışını doğrudan artırır. Playtomic (ELO seviye + güvenilirlik
  yüzdesi) ve Global Tennis Network (~198bin oyuncu, 17 yıl) bu modeli kanıtlamış.
  Golfte 18Birdies ödül programından sonra uygulamaya geri dönüş %100 artmış.
- **(44) Turnuva tahmini (pick'em)** — kulüp içi turnuvalarda ve Grand Slam'lerde braket
  doldurma + kulüp lider tablosu. Geliştirmesi en ucuzu (birkaç gün), ama sezonluk çalışır,
  sürekli döngü sağlamaz. (42) veya (43) yanında ek olarak iyi.

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

**Kilitli derste "Ders Yapılmadı" yanlış görünüyor (2026-08-15 çözüldü).**
Antrenör, yönetici onaylı bir dersi açtığında kırmızı "Ders Yapılmadı" + kilit notu görüyordu;
oysa ne antrenör ne yönetici böyle bir şey işaretlemişti. `EtkinlikOnayModel`'de yönetici ve
antrenör **ayrı satırlar**; yönetici onayı antrenör satırını yazmaz. `getDersKatilimlari` yanıtı
başlığı antrenör satırından (`antrenor_onayi`), kilidi yönetici satırından (`kilitli_mi`) besliyor;
dialog `ao?.tamamlandi == true` yazdığı için **satır yok (null)** hali `false` ile aynı kovaya
düşüyordu. Prod'da 3.960 ders bu durumdaydı. Düzeltme mobil tarafta: üç durum ayrıldı
(`yoklamaDurumu` — yapıldı / yapılmadı / **yoklama alınmadı**), backend değişmedi. Takvim bloğu ve
üye geçmiş listesi zaten üç durumu ayırıyordu. Kural: `bool?` onay alanlarında **null'ı asla
`== true`/`?? false` ile ikiye indirme** — kayıt yokluğu bir karar değildir.

**Takvimde hiç ders gelmiyor / "Dersler yüklenirken timeout" (2026-07-28 çözüldü).**
Uzun süre `TenantManager` filtresi ve backend commit `9d8f554` suçlandı — **ikisi de yanlıştı**
(o commit hiç deploy edilmemişti, veri de temizdi). Gerçek sebep: `getUyeDersProgrami` mobilin
gönderdiği `start`/`end` aralığını yok sayıp üyenin **tüm** derslerini dönüyordu, ağır N+1
serializer'la birlikte endpoint 220sn sürüyordu; `ApiClient`'ın 20sn timeout'u `_loadWeek` içinde
sessizce yutuluyordu → boş takvim. Semptomu asıl büyüten kurulum: **lokal Django + uzak prod DB**
(sorgu başına ~150ms internet gecikmesi). Düzeltme: aralık filtresi (`api/etkinlik/metots.py`),
220sn → 7,6sn. Benzer bir "boş liste / timeout" şikâyetinde **önce endpoint süresine bak, tenant'a
değil.**
