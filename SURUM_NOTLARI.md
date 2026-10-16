# Sürüm Notları

> Mağaza vitrinine girilecek "Yenilikler" metni ve teknik özet.
> Yeni sürüm en üste eklenir.
>
> **Yalnızca tr-TR yazılır.** İngilizce metin eklenmez: mağazaya bir en-US
> yerelleştirmesi girildiği anda Apple o dil için ekran görüntüsü, açıklama ve
> gizlilik metni de istiyor — çıkmak istemediğimiz bir bakım yükü.
> (3.6.0 ve öncesindeki en-US bölümleri tarihsel kayıt olarak duruyor.)

## Sürüm notu popup'ı — her sürümde yapılacaklar

3.12.0'dan itibaren sürüm notları mağaza vitrininde kalmıyor: yeni sürümü kuran
kullanıcı ilk açılışta **kendi profiline** ait yenilikleri açılır liste olarak
görüyor (tam ekran popup; kalıcı erişim Ayarlar › "Neler yeni").

İçeriğin tek doğruluk kaynağı **backend deposundaki `surum_notlari.json`**
(`C:\Django	enis`). Mağaza metni (`release_notes.json`) ve bu dosyanın
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

## 3.12.0 — 2026-10-16

### Mağaza metni (tr-TR)

`release_notes.json`'da `tr` ve `tr-TR` girdileri aynı (Play sınırı 500 karakter, metin 494).
Kullanıcı isteğiyle (2026-10-16) **3.9.0 dahil** sonraki bütün sürümlerin üye yeniliklerini anlatıyor
(3.10.0 ve 3.11.0 mağazaya çıkmadı). Kulüp adı geçmiyor, yalnız renk adları. Her zamanki gibi elle, son
kullanıcı için kısa maddelerle yazılır; "Neler yeni?" notlarından (`surum_notlari.json`) **bağımsızdır**,
ondan beslenmez ve onun metnini kopyalamaz (kullanıcı kararı 2026-10-16).

- Renk temaları: Sarı-Kırmızı, Sarı-Lacivert, Bordo-Mavi, Siyah-Beyaz ve Ay-Yıldız (Ayarlar › Görünüm).
- Ekranlar sadeleşti; koyu temada yazılar daha okunaklı.
- Profil fotoğrafı: kameradan çekin ya da galeriden seçin.
- Ödemeniz alınınca, paketiniz tanımlanınca ya da bitince bildirim gelir.
- Doğum gününüzde kutlama, önemli duyurular açılışta.
- Ödül sayacında "Nasıl kazanılır?" bilgisi.
- Yardım & SSS yenilendi.
- Yenilikleri artık uygulamada görebilirsiniz.
- Çeşitli hata düzeltmeleri.

### "Neler yeni?" popup'ı

İlk sürüm notu popup'ı bu sürümle çıkıyor. Notlar backend `surum_notlari.json`'da: **3.9.0'dan 3.12.0'a**
kadar her şey rol başına tek 3.12.0 bloğunda (üye 8, antrenör 6, ofis 10, yönetici 9 madde; popup ilk 4'ü
gösterir, gerisi "Tümünü gör"). Sıra önem sırası: her rolün ilk dört maddesi o profilin en büyük
yenilikleri. "Yol" satırları ekrandaki menü adlarıyla (yönetici: Dashboard / Raporlar / Üyeler).
Kullanıcı kararı (2026-10-16): güncelleyen kullanıcı popup'ı **otomatik görsün** — notlar mağaza onayını
beklemeden yayında (`yayinda_mi` açık). Popup yalnız 3.12.0 kurulu cihazda çıktığı için eski
sürümdekilere etkisi yok.

### Teknik

- **"Neler yeni?" (tüm profiller).** Tam ekran sürüm notu popup'ı ve Ayarlar › "Neler yeni" arşivi
  (`b807f8d`). Ofis ve yönetici kabukları da açılış popup sırasına girdi.
- **Antrenör değerlendirmeleri (yönetici).** Antrenörler satırı iki dokunma alanı: sol taraf (ad, ok)
  hakediş saatlerine, sağdaki puan hücresi ("★ 4.8 (23)" / "Yorumlar ›") değerlendirmeler listesine
  gider. Önceki iki seçenekli alt sayfa kaldırıldı. Liste ve detay `lib/screens/1_common/degerlendirmeler/`;
  uç `degerlendirmeListesi` yalnız yönetici. Yorum sayısı `degerlendirme_sayisi` alanından; alanı
  göndermeyen sunucuda yalnız ortalama görünür.
- **Başlık bantları (yönetici).** Raporlar / Antrenörler / Üyeler başlığında dönem seçimi tam genişlik,
  seçili dönemin tarih aralığı sağda (`DonemFiltresi.aralik`, sunucudaki `get_tarih_araligi` ile aynı).
- **Pano dönem kutusu (yönetici, kullanıcı kararı "A").** Bugün / Bu Hafta / Bu Ay seçimi başlıktan
  içeriğe, yalnız ona bağlı kartlarla (ciro, tahsilat, ders, iptal) aynı çerçeveye taşındı (`DonemKutusu`);
  aktif üye ve toplam alacak "Şu an", haftalık grafik "Bu haftanın günleri", hızlı erişim "Bugün" altında.
  Dönem değişince yalnız kutu iskelete döner; yenilemede pano yerinde kalır. **Bugünün özeti en üstte**
  ve "Yeni Üye · Ders · Doluluk" (eski "Yeni Kayıt" bugün açılan üye kaydıydı, adı netleşti; "Bekleyen
  Telafi" yerine bugünün iptal edilmemiş ders sayısı — hızlı erişimdeki `toplam_ders`, backend değişmedi).
- **Raporlar (yönetici).** Seçici panodaki gibi içerikte; iki kutu, **ikisinin de kendi seçicisi var**:
  "Ciro ve tahsilat" (özet kartlar + ciro + tahsilat) ve "Kort ve antrenör" (kort doluluğu + antrenörler)
  ([rapor_gruplari.dart](lib/screens/7_yonetici/raporlar/widgets/rapor_gruplari.dart)). Her kutu
  `yoneticiRaporlar`'ı kendi `bolum`'üyle ister (`donem` / `kort_antrenor`), ciro günleri iki kez
  hesaplanmaz; alanı tanımayan eski sunucu hepsini döndürür. **Isı haritası en altta, seçiciden bağımsız**:
  ızgara hep haftanın günleri olduğu için bu haftanın tamamı (Pzt–Paz, planlı dersler dahil, sunucuda
  `bu_hafta_tamami`; eski sunucu bu değeri tanımaz, yalnız bugünü döndürür). Uzun listeler (aylık günler, kortlar, antrenörler) kartın içinde kayıyor (`RaporKaydirmaliListe`, 186 px).
  Aktif üye kartı Raporlar'dan kaldırıldı (dönemden bağımsız; panoda "Şu an"). Özet kartlar ve bölüm
  başlıkları dar ekranda / büyük yazıda taşıyordu; bölümler taşma matrisine eklendi.
- **Üyeler (yönetici).** Tümü / Aktif / Pasif / Borçlular butonları kalktı; filtre başlıktaki sayılı
  kartlar (Toplam · Aktif · Pasif · Borçlu · Yeni, `UyeIstatistikKartlar`), seçili kart vurgulu, liste
  boşken de seçilebilir. "Borçlu" en borçlu önce, "Yeni" bu ay kaydolanlar en yeni üye önce. Borçlu
  sayısı yalnız yönetici ucunda (`borclu_uye`); alanı göndermeyen sunucuda "–". "Yeni" filtresi backend
  `f2b4872` ister — eski sunucu filtreyi yok sayıp tüm üyeleri listeler (sıra yine önce backend).
- **Ofis.** Ana Sayfa başlığına çıkış düğmesi; ofis ekranlarındaki başlık görünümü düzeltildi.
- **Üye.** Sonraki ders kartı kort adını önekle yazıyordu ("Kort Merkez Kort"); bildirim satırı
  `RichText` yerine `Text.rich` (temanın yazı ailesi ve yazı boyutu ayarı).
- **Yardım (yönetim).** Dashboard, Raporlar ve Üyeler cevapları yeni düzene göre yeniden yazıldı.
- **Backend (önce deploy edildi, Heroku v317–v318):** `setDersDegerlendirme` / `getDersDegerlendirme`
  değerlendireni ve rolü token'dan alıyor (istekteki `user_id` yok sayılıyor);
  `getDersTumDegerlendirmeler` yalnız yönetici.
- **Backend (bu sürümden önce deploy):** yönetici üye listesi `yeni` filtresi + `borclu_uye`; raporlar
  `bolum`; ısı haritası `bu_hafta_tamami`; iptal talebi / ders onay / `getDersKatilimlari` uçlarında
  kimlik token'dan ve ders sahipliği kontrolü.
- **Mağaza görselleri.** App Store 2.3.3 reddi (eski ekran görüntüleri) için `tool/magaza_gorselleri/`:
  gerçek sayfalar iOS modunda, SF Pro ve sahte API ile 4 boyutta çiziliyor (bkz. oradaki README).

## 3.11.0 — 2026-10-13

### Mağaza metni (tr-TR)

`release_notes.json`'da `tr` ve `tr-TR` girdileri aynı (Play sınırı 500 karakter, metin 349).
Metin yalnız son kullanıcıyı (üye) ilgilendiren maddeleri taşır; ofis/yönetici yenilikleri teknik bölümde.

- Profil fotoğrafı: Profilim ekranında fotoğrafınıza dokunup kameradan çekebilir ya da galeriden seçebilirsiniz; dilediğiniz zaman kaldırabilirsiniz. Fotoğrafınız antrenörünüzün ve kulübün ekranlarında görünür.
- Günlük ders özetindeki sayılar açık ve koyu temada daha okunaklı.
- Giriş, profil seçimi, ödeme ve hesap ekranlarında hata düzeltmeleri.

### Teknik

- **Profil fotoğrafı (üye).** Profilim ekranındaki avatar dokunulabilir: kamera / galeri / kaldır.
  İstemci yalnız küçültüyor (en uzun kenar 1200 px, JPEG %85); kareye kırpma sunucuda, ortadan
  ([profil_fotografi_secici.dart](lib/screens/2_uye/profil/widgets/profil_fotografi_secici.dart)).
  Dosya Firebase Storage'a gidiyor (`profil/<uye_id>/<uuid>.jpg`) — duyuru görselleriyle aynı hat;
  Heroku dyno diskine yazan eski `ImageField` terk edildi, **web formu da aynı servise bağlandı**, yani
  web'den yüklenen fotoğraf mobilde, mobilden yüklenen web'de görünüyor. Çıktı 512 px JPEG, üst sınır
  200 KB. Fotoğraf; giriş, ders katılımcı listeleri, yönetici/ofis üye listeleri ve detaylarında avatar
  olarak çiziliyor. Üye ya da hesap silinince Firebase'deki dosya da siliniyor (KVKK).
- **Ofis profili.** Ana Sayfa'da bekleyen işler (onay bekleyen dersler, plan dışı kararlar, cevapsız
  yoklamalar) ve Dersler ekranı: yönetici onayı, "antrenörün yapıldı dediklerini onayla", hakediş, paket
  düşümü, manuel teyit ve hatırlatma, plan dışı/misafir kararı. Kurallar web ile ortak serviste.
- **Sayfalı üye listesi.** Yönetici ve ofis üye listeleri 20'şer geliyor, arama ve filtre sunucuda
  ([sayfali_liste.dart](lib/common/sayfali_liste.dart)); arama çok kelimeli ve Türkçe İ/ı varyantlı.
- **Takım rengi her sayfada.** Sayfa zemini temanın açık tonu, başlık bandı ve alt menü düz tema rengi
  (`BaslikBandi`, `TemaGecisleri`); kimlik yüzeyi sayfa başına bir tane.
- **Denetim turu (iki bağımsız ajan + iki doğrulama ajanı).** Yayın engeli olan iki hata yakalandı:
  `baseUrl` yanlışlıkla yerel sunucuya commit edilmişti ve ofis hakediş düğmesi dersi sessizce
  "yapılmadı" yapıyordu. Ayrıca: üye listesi istatistiklerinde yarış durumu, ofis Ana Sayfa'da sonsuz
  iskelet, üye kabuğunda fail-open erişim varsayılanı, profil seçiminde fazladan `pop()`, satır ile
  işlem sayfası arasında ayrışan "ders bitti" ölçütü, ders özeti kartlarında eşik altı kontrast
  (turuncu 2,16:1) ve ders onay dialoğunda 6 px taşma düzeltildi.
- **Testler:** `flutter test` 2730 (2505'ten), `flutter analyze` temiz; backend süiti 1090.
  Taşma matrisine `ProfileHeader`, `ErisimKisitli`, `GecisCubugu`, başlık bandı parçaları ve
  sarmalayıcısız `IskeletListe` varyantları; kontrast testine `ListeTonu` ön plan/zemin çiftleri;
  gömülü renk mandalının `Colors.x` tabanı 176 → 144.

### Yayın notu

**Backend bu sürümden ÖNCE deploy edilmeli** (`0091` + `0092` migration'ları, Pillow 10.4.0 ve
`uyeProfilFotografi` / `ofis*` uçları). Aksi halde profil fotoğrafı ve ofis ekranları canlıda çalışmaz.

## 3.10.0 — 2026-10-10

### Mağaza metni (tr-TR)

`release_notes.json`'da `tr` ve `tr-TR` girdileri aynı (Play sınırı 500 karakter, metin 487).
Mağaza metninde kulüp adı geçmiyor (yalnız renk adları); mağaza ekran görüntüleri Binay temasıyla.
Metin yalnız son kullanıcıyı (üye) ilgilendiren maddeleri taşır; yönetici/ön büro yenilikleri teknik bölümde.

- Renk temaları: Binay Akademi'nin yanında Sarı-Kırmızı, Sarı-Lacivert, Bordo-Mavi, Siyah-Beyaz ve Ay-Yıldız. Ayarlar'daki Görünüm bölümünden seçin.
- Ekranlar renk geçişli, sade bir tasarımla yenilendi; koyu temada okunmayan yazılar düzeltildi.
- Doğum gününüzde kutlama, önemli duyurular açılışta.
- Ödül sayacına "Nasıl kazanılır?" bilgisi eklendi.
- Ödemeniz alınınca, paketiniz tanımlanınca ya da bitince bildirim gelir.
- Profil seçme ekranı sadeleşti.
- Çeşitli hata düzeltmeleri.

### Teknik

- **Renk temaları** (`TakimTemasi`, [tema.dart](lib/common/tema.dart)): Binay Akademi (önceki açık/koyu
  palet aynen) + beş takım rengi teması. Seçim cihaz bazlı (`TemaKontrol.takim`, anahtar `tema_takim`,
  çıkışta korunur), açık/koyu moddan bağımsız; Ayarlar > Görünüm'de önizlemeli karolar.
- **Geçişli tasarım dili** (`TemaGecisleri` ThemeExtension): ekranda en fazla bir kimlik yüzeyi
  (`KimlikYuzeyi` / `KimlikBaslik`), her rotanın altında tema geçişinin çizdiği sayfa yıkaması
  (`SayfaZemini`; Scaffold şeffaf, AppBar içerik altına kayınca zemin rengi), ikinci takım rengi yalnız
  3 dp şeritte. Butonlar, listeler, takvim ve grafikler düz; durum renkleri her temada aynı.
- **Erişilebilirlik:** iptal edilen ders üç takvimde de taramalı (`IptalTaramasi`); yıkıcı aksiyonlar
  kenarlıklı `YikiciButon`; buton içi göstergeler butonun yazı rengini alıyor
  (`ButonYukleniyorGostergesi`); `uzerineYazi` iki adayın kontrastını karşılaştırıyor.
- **Düzeltmeler:** profil seç ekranı sade düz liste (koyu modda kartların yarısı beyaz kalıyordu); koyu
  modda okunmayan rozet/çip/ikonlar; günlük kokpit başlığı dar ekranda taşıyordu.
- **Bu sürüme giren önceki turlar:** açılış popup'ları (doğum günü kutlaması + popup duyurusu), yönetici
  ve ofis Duyurular ekranı (kimlerin gördüğü), ödül sayacı "nasıl kazanılır?" sayfası, duyuru şeridi
  kapak görseli, ofiste profil değiştirme butonu, yönetici ekranında "Yapılmadı" / "Bekleyen Telafi"
  etiketleri, ders talep kodunun kaldırılması.
- **Yayın öncesi ekran denetimi** (üç UI/UX ajanı: üye / antrenör-takvim / yönetici-ofis-ortak; 6 tema ×
  açık/koyu, gerçek fontla). Renk temalarından gelen engel çıkmadı; bulunanlar düzeltildi:
  - Önceden var olan kırık akış: antrenörün ders iptal talebinde "İptal Talebi Gönder" yazı girilince
    etkinleşmiyordu (alan yeniden çizim tetiklemiyordu).
  - Koyu modda okunmayan alanlar: "Katılamayacağım" açıklama kutusu ve kayıtlı değerlendirme yorumu
    beyaz zemindeydi; değerlendirme/ders detayı, devir, yoklama kilidi ve devir bildirimi kutularındaki
    sabit kırmızı/mavi/amber yazılar durum token'larına taşındı; QR doğrula açıklaması (1,05:1), ofis
    ızgarasında antrenör adı ve saat etiketleri, ısı haritası hücre yazısı, öğrenci istatistiklerinde
    sarı zemine beyaz sayı, takvim "İPTAL" rozeti, teyit ikonları.
  - Durum çubuğu şeffaf verildi (Android 14 ve altında yıkamanın üstünde gri bant kalıyordu); gezinme
    çubuğuna dokunulmuyor.
  - Tasarım kuralı: antrenörde "Dersi İptal Et" kenarlıklı `YikiciButon`, antrenör takviminde iptal adı
    üstü çizili, kendi zeminini çizen dört sayfa `SayfaZemini`'ne bırakıldı, giriş bandında logo
    ortalandı, alt bar QR halkasındaki boşluk görünür ve tüm sütun dokunulabilir, renk teması seçicisi
    alt etiketler kesilmesin diye telefonda iki sütun, hakedişte gri taban koyu modda pembeye dönmüyor.
  - Yönetici panosu istatistik kartları 360 dp'de taşıyordu: yükseklik artık içerikten, tutar
    sığmazsa küçülüyor (taşma testine eklendi).
- **Testler:** `flutter test` 2132 (1432'den); yeni `tema_kontrast_test.dart` (6 tema × 2 mod, tüm
  yazı/zemin çiftleri, gradyanlarda 41 noktanın en kötüsü), `renk_temasi_test.dart`,
  `gomulu_renk_mandal_test.dart` (gömülü renk sayısı artamaz: hex 42, `Colors.x` 176); taşma matrisi
  üç uç takım temasında da.

**Deploy sırası: önce backend, sonra Codemagic.** Yönetici/ofis Duyurular ekranı `yoneticiDuyurular`
ucunu kullanıyor; backend canlıda olmadan çıkarsa ekran 404 alır. Uyuldu: backend `1d527c5` Heroku
**v305** (2026-10-10, migration yok), uçlar 401 dönüyor (404 değil); ardından `v3.10.0` tag'i.

**Üye bildirimleri (ayrı oturumun işi, bu sürüme eklendi):** yeni `ODEME_ALINDI` bildirim tipi için ikon
ve renk. Bildirimleri üreten backend `6c269f5` (ödeme alındı, paket tanımlandı/bitti, antrenör değişikliği;
migration `0091`) Heroku **v306**'da canlı (2026-10-11); eski sürümler yeni tipi varsayılan ikonla gösterir.

**İlk build Testler adımında derlenmedi:** Flutter 3.44'te `CupertinoPageTransitionsBuilder` material'dan
cupertino kütüphanesine taşınmış; yerel Flutter 3.41.8'de görünmedi, Codemagic `flutter: stable` (3.47.7)
kullanıyor. iOS/macOS geçişi artık Flutter'ın varsayılan haritasından alınıyor (iki sürümde de derlenir).
Analiz ve testlerin tamamı Flutter 3.47.7 ile de çalıştırıldı: 2134 test geçti.

**Codemagic kuyruğu:** build `xcode: latest` ve ardından `26.6` ile saatlerce kuyrukta kaldı (durum
sayfasında kesinti yoktu). Codemagic 26.6 havuzundaki aşırı yükü GitHub tartışmasında doğruladı
(`codemagic-ci-cd/discussions/3570`); `codemagic.yaml`'da Xcode **26.5**'e sabitlendi ve `v3.10.0` tag'i
`3b6effa`'ya taşındı, build hemen başladı. Kuyruk normale dönünce sürüm yükseltilebilir.

## 3.9.0 — 2026-09-08

### Mağaza metni (tr-TR)

`release_notes.json`'da `tr` ve `tr-TR` girdileri aynı (Play sınırı 500 karakter, metin 454).

- Ön büro (ofis) profili eklendi: haftalık program, ders açma/düzenleme/iptal ve QR doğrulama tek yerde.
- QR doğrulama sonucu yenilendi: durum tüm ekranda görünüyor, ne yapılacağı yazıyor, "Sonrakini tara" ile hızlı devam.
- İptal edilen derste kimin, ne zaman ve neden iptal ettiği görünüyor.
- Yardım & SSS sayfaları role göre ayrıldı; üye soruları güncellendi.
- Zorunlu güncelleme ekranının atlanabildiği hata giderildi.
- Çeşitli hata düzeltmeleri.

### Teknik

- **Ofis (ön büro) kabuğu.** `Roller` enum'una `ofis` eklendi; aksiyon ekranları yöneticiden
  ayrılıp `lib/screens/8_ofis/` altına taşındı (haftalık program, günlük ders listesi, kırpılmış üye
  listesi, bildirimler, QR oluştur + doğrula). Yönetici kabuğunda aksiyon ekranı kalmadı.
  Gizli bilgi sınırı sunucuda beyaz listeyle: `ofisUyeler` / `ofisUyeDetay` bakiye, para hareketleri,
  adres, meslek, veli, acil durum ve okul alanlarını hiç göndermiyor; `siralama="bakiye"` ve
  `filtre="borclu"` de reddediliyor. **Ön koşul:** ofis profilinin `SistemKullaniciModel.isletme`
  alanı dolu olmalı, boşsa 403 `TENANT_REQUIRED`.
- **QR sonuç ekranı** ([qr_sonuc_gorunumu.dart](lib/screens/1_common/widgets/qr_sonuc_gorunumu.dart)):
  backend hata kodu yedi duruma eşleniyor, her birinin kendi rengi, ikonu ve "şimdi ne yapmalı"
  satırı var. Renkler `tema.dart` token'larından — eski ekranda gömülü hex vardı, koyu temada
  okunmuyordu.
- **İptal künyesi:** haftalık program ucu `iptal_eden`, `iptal_tarihi` ve sebebi de döndürüyor
  (`select_related`, N+1 yok); ders işlem sheet'inde künye paneli çiziliyor.
- **Zorunlu güncelleme:** `InAppUpdateAndroid.immediate()` `AppUpdateResult.userDeniedUpdate`
  dönüşünü yok sayıp koşulsuz `true` dönüyordu; kullanıcı Play'in tam ekran akışında geri tuşuna
  basınca eski sürümle devam edebiliyordu. Artık yalnız `success` başarı sayılıyor.
- **Yardım & SSS üç sayfaya çıktı.** Yönetici ve ofis drawer'larındaki "Yardım" üye SSS'ine
  gidiyordu — antrenörde 2026-08-10'da düzeltilen hatanın aynısı. Yeni
  [yonetim_yardim_page.dart](lib/screens/1_common/yonetim_yardim_page.dart) tek dosyada iki kapsam
  taşıyor (sorular `_Kapsam` etiketli, sayfa role göre süzüyor); üye sayfası ekrana göre yeniden
  yazıldı, Ayarlar'daki yardım bağlantısı dört rolü de doğru sayfaya götürüyor.
  Ekran gövdesi ortak [sss_gorunumu.dart](lib/screens/1_common/widgets/sss_gorunumu.dart)'ya
  çıkarıldı: üye ve antrenör sayfalarındaki gömülü `Colors.white` / `Colors.blue` yüzünden koyu
  temada beyaz kalan soru kartları da bu sayede token'landı.
- **İzin raporlaması:** yeni `cihazIzinGuncelle` ucu (token istemiyor) + "sorulmadı / reddedildi"
  ayrımı için izin damgaları (`lib/services/core/izin_durumu.dart`).
- **Çalışma saatleri bilgi notu** düzeltildi: "üyelerin ders talebi oluştururken gördüğü saatler"
  diyordu, öyle bir akış yok. Not artık gerçeği söylüyor (yöneticinin antrenör sayfasında görünür).

**Deploy sırası: önce backend, sonra Codemagic.** Ofis uçları ve iptal künyesi canlıda olmadan
mobil sürüm çıkarsa ofis kabuğu 404 alır.

## 3.8.1 — 2026-08-18

### Mağaza metni (tr-TR)

App Store'da yayındaki sürüm 3.7.0'da kaldığı için metin 3.8.0 + 3.8.1'i birlikte özetliyor;
`release_notes.json`'da `tr` ve `tr-TR` girdileri **aynı** (Play sınırı 500 karakter, metin 420).

- Koyu tema eklendi; Ayarlar'dan Sistem, Açık veya Koyu seçilebiliyor.
- Takvime liste (Ajanda) görünümü eklendi.
- Kayıt ol ve şifremi unuttum ekranları yenilendi, uygulama içinde açılıyor.
- Yeni Ayarlar sayfası: tema, bildirim, şifre ve hesap işlemleri tek yerde.
- Arayüz kulüp renklerine geçti, alt menü sabitlendi.
- Listeler sadeleşti, aynı ekranda daha fazla kayıt görünüyor.
- Çeşitli hata düzeltmeleri yapıldı.

Ayrıntılı 3.8.0 metni aşağıdaki 3.8.0 bölümünde duruyor; mağazaya kısa hâli gidiyor.

### Teknik

- **Kayıt/şifre sıfırlama native:** `RegisterPage` ve `ForgotPasswordPage` web view'dan çıkarıldı;
  yeni uçlar `kayitFormVerileri`, `uyeBasvuru`, `sifremiUnuttum`, `sifreSifirlamaGonder`
  ([api_urls.dart](lib/common/api_urls.dart)) — backend `master`'da canlıda. `MaterialApp`'e tr-TR
  yerelleştirme delegeleri eklendi.
- **Takvim açılmama hatası:** uygulama genelindeki yazı ölçeği clamp'i ile Material tarih
  seçicisinin kendi clamp'i çakışıp `maxScale > minScale` hatası veriyordu. Hazır `TextScaler.clamp`
  yerine aynı işi yapan kendi ölçekleyicimiz yazıldı ([ui_scale.dart](lib/common/ui_scale.dart));
  sihirbaz testi gerçek `MaterialApp.builder` kurulumuyla eşitlendi, 0.85/1.0 cihaz ölçeklerinde
  takvimin açıldığı iki test eklendi.
- **Release notes akışı:** `release_notes.json` bu sürümden itibaren her yayında yeniden yazılıyor.
  Codemagic dosyayı repo kökünde kendisi buluyor (yaml'da referansı yok); 3.7.0 ve 3.8.0'da dosya
  güncellenmediği için mağazalara kurulumdan kalma jenerik metin gitmişti.

## 3.8.0 — 2026-08-17

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
  dönülüyor. Şeritten bir güne dokununca liste o güne kayıyor, o gün ders yoksa bunu yazıyor.
- **Yeni liste tasarımı:** Üye, öğrenci, ders, geçmiş ders ve hesap hareketi listeleri kart yığını
  yerine düz satıra geçti — aynı ekranda yaklaşık %60 daha fazla kayıt görünüyor. Grup başlıkları
  (Borçlu/Güncel, aylar) kaydırırken tepede kalıyor, satırı yana kaydırınca Ara/WhatsApp gibi
  işlemler çıkıyor.
- **Yükleme göstergesi:** Dönen çark yerine gelecek içeriğin taslağı beliriyor; kısa yüklemelerde
  hiç gösterilmiyor, aşağı çekip yenilerken mevcut liste ekranda kalıyor.
- **Ders işlemleri:** Antrenörde onay, iptal, devir ve detay ekranları alttan açılıyor — tek elle
  ulaşılabiliyor. Ders kutusuna uzun basınca kısayol menüsü çıkıyor, ders onay ekranı yenilendi.
  Kilitli derste "yapıldı / yapılmadı / yoklama alınmadı" ayrı ayrı gösteriliyor.
- **Yardım & SSS:** Arama kutusu eklendi. Antrenöre özel, 10 bölüm 50 soruluk yeni bir yardım
  sayfası var; bölüm filtreleriyle taranıyor.
- **Bildirimler:** Bildirimi yana kaydırarak silebiliyorsunuz, yanlışlıkla sildiyseniz "Geri al".
  Liste sadeleşti, okunmamış işareti belirginleşti. Oturum açıkken **üç günden eski** teyit
  bildiriminden de derse katılım bildirilebiliyor; süresi geçen durumlar teknik hata metni yerine
  ne yapılacağını anlatan bir ekranla karşılanıyor.
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
- **Ortak liste kalıbı:** `lib/screens/1_common/widgets/liste_satiri.dart` — `ListeSatiri`,
  `ListeAvatari`, `ListeAyraci`, `ListeGrupBasligi` (+ yapışkan sliver delegate), `ListeTonu` ve
  `ListeEylemi`. Kaydırma `Dismissible` değil tek sürükleme denetleyicisi: satır listeden atılmıyor,
  yerinde kalıp eylem şeridini açıyor; aynı eylemler uzun basınca alt sayfada (kaydırma jesti ekran
  okuyucuyla kullanılamıyor). Yönetici üyeler/borçlular/dersler/antrenörler, antrenör öğrencilerim,
  üye geçmiş dersler ve hesap hareketleri bu kalıba geçti; `uye_liste_item.dart` ve `_StudentCard`
  silindi.
- **İskelet yükleme:** `lib/screens/1_common/widgets/iskelet.dart` (`Parilti` ShaderMask ile, harici
  paket yok) + `IskeletListe/Kart/Takvim/Dashboard`. 300 ms'den kısa yüklemede gösterilmiyor,
  aşağı çekip yenilemede çıkmıyor. Sayfa/bölüm seviyesinde `CircularProgressIndicator` kalmadı;
  kalan 36 kullanım buton içi / auth-rota / belirlenimli görsel ilerlemesi.
- **Ajanda seçili gün:** `TakvimAjanda.secilenGun` — sliver'lar görüş alanı dışında layout
  edilmediğinden `ensureVisible` çalışmıyor, kaydırma hedefi sabit satır yüksekliğiyle hesaplanıyor;
  gün başlıkları `SliverMainAxisGroup` altında (pinned başlıklar üst üste yığılmıyordu).
- **Teyit uç seçimi:** oturum açıkken teyit auth'lu `setDersTeyit` ucundan gidiyor; login'siz token
  ucu (72 saatlik pencere) yalnız oturum yokken yedek. Okundu işareti de aynı şekilde auth'lu uca
  alındı — eski bildirim açılışları sunucuda 410 + WARNING üretiyordu (30 günlük log'un %22'si).
- **Simge rozeti (Android):** `app_badge_plus` MIUI/HyperOS'ta rozeti N yapmak için **N adet sahte
  bildirim** gönderiyor (okunmamışı 15 olan cihazda bildirim gölgesine 15 satır düştü). Android'de
  plugin'e artık yalnız `0` yazılıyor; pozitif sayıyı gerçek bildirimin `number` alanı taşıyor.
  iOS etkilenmiyor (APNs payload'ı).
- **İzin durumu telemetrisi:** cihaz kaydına `bildirim_izni` / `kamera_izni` / `takvim_izni`
  ekleniyor (`izinDurumlari()`; yalnız sorgular, izin istemez). Backend `auths` migration `0009`.
- **Testler:** taşma matrisi uygulamanın gerçek temasıyla koşuyor ve her bileşen için bir de koyu
  tema koşusu yapıyor; toplam **942 test** geçiyor, `flutter analyze` temiz.

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
