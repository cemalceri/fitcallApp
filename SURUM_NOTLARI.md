# Sürüm Notları

Mağaza "Yenilikler" metni ve teknik özet; yeni sürüm en üste eklenir. Yalnız son iki sürüm burada
tutulur, öncekiler git geçmişinde ve `C:\Django\tenis\history.md`'de.

**Yalnızca tr-TR yazılır.** Mağazaya bir en-US yerelleştirmesi girildiği anda Apple o dil için ekran
görüntüsü, açıklama ve gizlilik metni de istiyor.

## Sürüm notu popup'ı — her sürümde yapılacaklar

3.12.0'dan itibaren sürüm notları mağaza vitrininde kalmıyor: yeni sürümü kuran
kullanıcı ilk açılışta **kendi profiline** ait yenilikleri açılır liste olarak
görüyor (tam ekran popup; kalıcı erişim Ayarlar › "Neler yeni").

İçeriğin tek doğruluk kaynağı **backend deposundaki `surum_notlari.json`**
(`C:\Django\tenis`). Mağaza metni (`release_notes.json`) ve bu dosyanın
"Mağaza metni" bloğu hâlâ elle yazılıyor; popup bunlardan bağımsızdır.

1. `surum_notlari.json`'a yeni sürüm bloğunu yaz: `surum`, `yayin_tarihi`,
   `rol_basliklari` ve `maddeler`. Her madde `roller` listesiyle hangi
   profilleri ilgilendirdiğini söyler (ortak madde bir kez yazılır, yükleyici
   her role çoğaltır).
2. Madde yazarken üç soru: kullanıcı ekranda bir **fark** görecek mi; "hangi
   menüden" cümlesini (`yol`) yazabiliyor muyum; bu rol o ekrana **girebiliyor**
   mu? Bir rol için madde yoksa o rolü **hiç yazma** — "çeşitli iyileştirmeler"
   dolgusu yerine o profil popup görmez.
3. Sınırlar: başlık ≤ 42, açıklama ≤ 180 karakter (yükleyici aşarsa hata
   verir), rol başına en çok 4 madde popup'ta görünür — fazlası "Tümünü gör"
   ile arşiv sayfasına düşer.
4. `python manage.py surum_notlari_yukle` (dry-run) ile doğrula. Heroku
   `release` fazı `--uygula` ile kendisi koşuyor, elle yüklemek gerekmez.
5. Backend'i deploy et (sıra değişmedi: **önce backend**). Notlar
   `yayinda_mi=False` gelir, yani henüz kimseye çıkmaz.
6. `pubspec.yaml` sürümünü bump'la, `release_notes.json`'ı yeniden yaz, tag'i
   pushla, Codemagic'i bekle.
7. **Mağazada canlı görülünce** Django admin › Sürüm Notları'ndan
   `yayinda_mi`'yı aç ve kendi hesabında bir açılış dene. Popup yalnız
   istemcinin kurduğu sürümle birebir eşleşen notu gösterdiği için, aşamalı
   yayında güncellemeyen kullanıcı hiçbir şey görmez.
8. Benimseme: Django admin › Sürüm Notu Görülmeleri — `kaynak` ve
   `acilan_maddeler`. En az bir madde açan / gören oranı **%25'in altındaysa**
   popup işe yaramıyor demektir; kararı tek sürüme değil birkaç sürüme bakarak
   ver.

## 3.15.0 — 2026-11-05

### Mağaza metni (tr-TR)

`release_notes.json`'da `tr` ve `tr-TR` girdileri aynı (478 karakter). 3.14.0 iki mağazada yayında ama
güncelleme uyarısı açılmadı, üyelerin çoğu 3.13.1'de; bu yüzden metin 3.14.0 maddelerini de taşır.

- Ders talebi ve kort kiralama: menüden uygun saati seçip talep açın; ofisin cevabı Taleplerim'de.
- Rehber: başlıktaki ? simgesi ekranı adım adım tanıtır. Çıkış Ayarlar'a taşındı.
- Başka işletmeye üyelik: Ayarlar'dan diğer işletmelerimize mevcut hesabınızla başvurun.
- Menü her sayfada; ekranın sol kenarından kaydırarak da açılır.
- Geçmiş Dersler: dersin durumu ve yoklamanız ayrı etiketlerle gösteriliyor.
- Daha hızlı açılış, güçlendirilmiş güvenlik ve hata düzeltmeleri.

### "Neler yeni?" popup'ı

Backend `surum_notlari.json`'da 3.15.0 bloğu 3.14.0 maddelerini de taşır; `yayinda`'sı hiç açılmayan 3.14.0
bloğu dosyadan çıkarıldı (DB kaydı kapalı kalır). Üye: ders talebi, "?" rehberi, başka işletmeye
üyelik, Geçmiş Dersler (menü maddesi "Tümünü gör"de). Antrenör: rehber, Ofis Soruyor, menü. Ofis:
Talepler, plan dışı Telafi, rehber, bildirim listesi (ders silme uyarısı ve menü "Tümünü gör"de).
Yönetici: Ana Sayfa adı, rehber, menü. Yeni ikon yok.

### Yayın sırası (bu sürüme özel)

1. Backend push + deploy (önce backend): 0104 hoca katsayısı, 0105 kullanılmayan modeller, 0106 işletme
   başvurusu, 0107 plan dışı telafi. Hepsi eklemeli; 3.13.1/3.14.0 istemcileri etkilenmez.
2. Mobil `perf/mobil-acilis` → `main`, tag `v3.15.0` → doğrudan üretim.
3. Mağazada canlı görülünce admin'den 3.15.0 sürüm notunun `yayinda`'sını aç.

2026-11-06: iki mağazada yayında; sürüm notu açıldı, konfig `onerilen`/`en_son` 3.15.0+49 (yumuşak uyarı,
`min_destekli` 3.13.1+47).

### Teknik

- **Üye ders / kort kiralama talebi.** Menü › Ders Talebi ve Kort Kiralama → Taleplerim; ofiste
  Menü › Talepler, antrenörde Menü › Ofis Soruyor. Backend Heroku v351'den beri canlı.
- **"?" öğrenme rehberi.** 148 rehber dört profilde; açıkken yazma istekleri ağa çıkmaz
  (`OgrenmeKapisi`). Ana sayfa başlıklarındaki çıkış butonu Ayarlar'a taşındı; yönetici ders kartı
  "Yapılan" → "Onaylanan". Üye ve antrenörde ders iptal talebi ekranları kalktı (iptal yalnız ofiste).
- **Başka işletmeye üyelik.** Ayarlar'dan başvuru (yalnız ana hesap), onay hedef işletmenin web
  "Üye onayla"sında; onayda profil mevcut hesaba bağlanır.
- **Plan dışı Telafi kararı.** Üyenin kendi hakkından, süresi en erken dolan düşülür; geri alma ve
  sıfırlamada hak iade edilir. Web ve mobil ofis.
- **Ofis bildirimleri.** Ofis tipleri ofis profilinin listesinde ve sayacında; ders teyidinin antrenör
  kopyası antrenörde. Dekont bildirimi etkin role göre doğru üye sayfasını açar.
- **Ders silme uyarısı.** Silinen dersten doğan ve başka derste kullanılmış telafi hakları kişi ve saatle
  listelenir (`telafi_kullanilmis`).
- **Açılış hızı.** FCM kaydı beklenmez, profil isteği konfigle paralel, sekmeler tembel yüklenir;
  backend'de antrenör/duyuru N+1'leri giderildi.
- **Android.** Gömülü Kotlin'e geçiş, KGP uygulayan eklentiler güncellendi.

## 3.14.0 — 2026-10-30

### Mağaza metni (tr-TR)

`release_notes.json`'da `tr` ve `tr-TR` girdileri aynı (377 karakter). 3.13.1 iki mağazada da yayında,
yani yalnız ondan sonraki üye yenilikleri.

- Menü artık her sayfada: sol üstteki menü simgesi alt bardaki tüm sekmelerde; ekranın sol kenarından kaydırarak da açabilirsiniz.
- Geçmiş Dersler: dersin durumu ve sizin yoklamanız ayrı etiketlerle gösteriliyor; iptal edilen ya da yapılmayan dersler artık katılmadığınız ders gibi görünmüyor.
- Uygulama güvenliği güçlendirildi.
- Çeşitli iyileştirmeler ve hata düzeltmeleri.

### "Neler yeni?" popup'ı

Backend `surum_notlari.json`'da 3.14.0 bloğu, `yayinda` kapalı: dört profilde ortak "Menü artık her
sekmede"; üyede Geçmiş Dersler'de Ders / Yoklama etiketleri; yöneticide Dashboard'un adı Ana Sayfa.
Antrenör ve ofis yalnız menü maddesini görür. Yeni ikonlar (`menu_rounded`, `home_rounded`) beyaz
listede.

### Yayın sırası (bu sürüme özel)

1. Backend deploy (yapıldı 2026-10-30, Heroku v350): App Check ara katmanı "log" modunda
   (`auths.0014`), hiçbir isteği reddetmez; eski sürümler etkilenmez. Sürüm notu `yayinda=False`.
2. Tag → doğrudan üretim (kullanıcı kararı: dahili test yok, zorunlu güncelleme yok). Android AGP 9 +
   edge-to-edge (`FlutterFragmentActivity`) bu sürümde ilk kez çıkıyor; güncelleme sonrası oturum
   düşerse ilk işaret kullanıcıların yeniden giriş yapması olur.
3. Mağazada canlı görülünce admin'den 3.14.0 sürüm notunun `yayinda`'sını aç.

### Teknik

- **Sol menü her sekmede.** Drawer kabukta (`UyeKabuk`, `AntrenorKabuk`, yönetici/ofis kabukları);
  `KabukMenusu` menü açma işlevini sekmelere indirir, sekme başlıklarında `KabukMenuButonu` /
  `kabukMenuLeading`. İtilen sayfalarda geri oku kalır. Yöneticide "Dashboard" → "Ana Sayfa".
- **Geçmiş dersler.** "Ders" ve "Yoklama" etiketleri ayrı; katılım yalnız antrenör yoklamasından,
  yapılmamış/iptal derste otomatik `katildi=False` "Katılmadı" gösterilmez.
- **Firebase App Check.** Her isteğe `X-Firebase-AppCheck` (Play Integrity / App Attest), `X-Platform`,
  `X-Uygulama-Surumu`. Sunucu `APP_CHECK_MODU=log`: doğrular ve sayar (admin › App Check Sayaçları).
  Konsol ayarları yapıldı (2026-10-30); zorunlu moda geçiş [MOBIL_GELISTIRMELER.md](MOBIL_GELISTIRMELER.md)'de.
- **Android.** AGP 9.1, Gradle 9.3.1, Kotlin 2.4.0, `add_2_calendar` 3.1.1; edge-to-edge. En az
  Flutter 3.44.
- **Diğer.** Devir bildiriminde "Reddet" çerçeveli; antrenör SSS'ine iki soru.
