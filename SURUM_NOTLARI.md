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

## 3.16.0 — 2026-11-13

### Mağaza metni (tr-TR)

`release_notes.json`'da `tr` ve `tr-TR` girdileri aynı (371 karakter); yalnız üye maddeleri.

- Bildirim tercihleri: Ayarlar'dan hangi bildirimleri alacağınızı seçin; kapattıklarınız Bildirimlerim'de yine durur.
- Kullanıcı adınızı artık Ayarlar'dan değiştirebilirsiniz.
- Android'de geri tuşu uygulamayı kapatmak yerine bir önceki sekmeye döner.
- Yeni renk teması: Çivit (Ayarlar › Görünüm).
- Rehber iyileştirmeleri, güçlendirilmiş güvenlik ve hata düzeltmeleri.

### "Neler yeni?" popup'ı

Backend `surum_notlari.json`'da 3.16.0 bloğu. Üye: bildirim tercihleri, kullanıcı adı, geri tuşu, Çivit.
Antrenör: kullanıcı adı, geri tuşu, Çivit. Ofis: ders notları + aynı üç ortak madde. Yönetici: Ana Sayfa,
Ekip, Raporlar, Ödeme onay bekliyor (ders notları ve ortak üç madde "Tümünü gör"de). Yeni ikon yok.

### Yayın sırası (bu sürüme özel)

1. Backend push + deploy (önce backend): yalnız `surum_notlari.json`; kod ve göçler (0108 dahil) zaten
   canlı.
2. Tag `v3.16.0` → doğrudan üretim.
3. Mağazada canlı görülünce admin'den 3.16.0 sürüm notunun `yayinda`'sını aç (konfig kullanıcıda).
4. Backend'deki ders iptal talebi uçları `min_destekli` 3.15.0'a çıkmadan silinmez: 3.13.1 ve 3.14.0
   istemcileri bu uçları hâlâ çağırıyor.

### Teknik

- **Yönetici yeniden tasarım ve Ekip.** Ana Sayfa bugün bloğu + "Dikkat isteyenler", Raporlar dönem
  özeti, Ekip (`7_yonetici/ekip/`), salt okunur "Ödeme onay bekliyor" (`7_yonetici/dekont/`; PDF
  Android'de İndirilenler'e iner: `IndirmeService`, `fitcall/indirme` kanalı). Ciro → "Ders bedeli",
  Tahsilat → "Tahsil edilen". Sunucu eskiyse ekranlar önceki görünüme düşer.
- **Üye bildirim tercihleri.** Ayarlar › Bildirim tercihleri (yalnız üye ana hesabı); dört grup,
  kapatılan grubun push'u gitmez (backend 0108, durum `ATLANDI`).
- **Kullanıcı adı değiştirme** (tüm roller); "Beni hatırla" adı da güncellenir.
- **Geri tuşu** (`SekmeGecmisi`): tüm kabuklarda bir önceki sekmeye döner, yoksa uygulama kapanır.
- **Çivit teması** (`TakimTemasi.civit`).
- **Ofis ders notları.** Ders yönetim sayfasında antrenör, yardımcı ve yönetici notları.
- **Güvenlik/teknik.** Release derlemeleri `--obfuscate` (semboller Codemagic artifact'ında); App Check
  token alınamayınca sebebi mobil loga yazılır (`Sayfa=AppCheckServisi`); FCM token yenilemesi oturum
  yokken gönderilmez; KVKK metnine işlem güvenliği kategorisi.
- **Rehber.** «Anladım» sonraki hedef yokken ilerlemez; ~20 rehber hedefi düzeltildi.
- **Küçük işler.** Ders iptal ve üye borç alt sayfalarında çift tutamaç giderildi; profil başlıkları kısa
  içerikte de tam kapanır (`KapanmaPayi`); antrenör takvim bloğu 1.3 yazı ölçeğinde bir saatlik dersi üç
  satırla gösterir ("+N kişi daha" yer yoksa düşer).

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
