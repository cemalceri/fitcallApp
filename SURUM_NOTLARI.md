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

## 3.13.1 — 2026-10-23 (güvenlik güncellemesi)

### Mağaza metni (tr-TR)

`release_notes.json`'da `tr` ve `tr-TR` girdileri aynı (393 karakter). Yalnız 3.13.0'dan sonraki üye
değişiklikleri; 3.13.0 bir mağazada henüz yayında değilse o mağazanın metnine 3.13.0 maddeleri eklenmeli.

- Hesap güvenliği güçlendirildi: hatalı şifre girişinde kalan deneme hakkınız gösteriliyor, çok sayıda hatalı denemede giriş 15 dakika kilitleniyor.
- Şifremi unuttum: sıfırlama bağlantısı, kullanıcı adınıza ya da telefonunuza bağlı hesapların e-posta adresine gönderiliyor.
- Oturumunuz sona erdiğinde uygulama sizi giriş ekranına yönlendiriyor.
- Çeşitli iyileştirmeler ve hata düzeltmeleri.

### "Neler yeni?" popup'ı

Yazılmadı: güvenlik sürümü, ekranda madde olacak kadar fark yok; hiçbir profil popup görmez.

### Yayın sırası (bu sürüme özel)

Backend değişikliği eski sürümlerle uyumsuz (`createToken` kanıt istiyor, eski token'lar düşüyor).
Mobil önce iki mağazada onaylanır (elle yayın), sonra backend `guvenlik-guncellemeleri` yayına alınır,
hemen ardından mobil yayınlanır ve admin'den 3.13.1 için zorunlu güncelleme açılır. Ayrıntı:
[MOBIL_GELISTIRMELER.md](MOBIL_GELISTIRMELER.md) › Güvenlik.

### Teknik

- **Token alma.** `getMyMembers` parolayı doğrulayınca 10 dk'lık imzalı `giris_bileti` döner;
  `createToken` bileti ya da aynı kullanıcının geçerli token'ını (profil değiştirme) ister. Mobil bileti
  bellekte tutar, `createToken`'ı `auth: true` ile çağırır.
- **Oturum düşmesi.** Token'da parola izi (`pv`): parola değişince ya da hesap kapanınca token düşer.
  Mobil 401 + `AUTH_ERROR`/`AUTH_REQUIRED` alınca token'ı siler ve girişe döner ("beni hatırla"
  varsa sessizce yeniden girer); geç dönen eski istek yeni token'ı silmez.
- **Hız sınırı + hesap gizleme.** Giriş: hesaba 15 dk'da 10, IP'ye 100 hatalı deneme, mesajda kalan
  hak; kayıtlı olmayan adda aynı yanıt. Şifre sıfırlama tek tip yanıt, hesap seçimi kalktı (eşleşen her
  hesaba bağlantı gider). Sayaç veritabanında (`auths.0013`), IP `X-Forwarded-For`'un son değeri.
- **Yetki.** Teyit/onay/değerlendirme yalnız kendi (veli: çocuklarının) ve kayıtlı olunan ders için;
  iptal talebi yalnız antrenör, kendi dersi; `getAktifUyeListesi` yalnız antrenör; antrenöre öğrenci
  için yalnız ad, doğum yılı, fotoğraf, seviye; ana hesap olmayan profile muhasebe/ödeme/dekont ve
  ana sayfada bakiye yok; üye ders programında başkasının iletişim bilgisi, ücret, katsayı yok.
- **Diğer.** Duyuru kitlesi rolden; aynı cihaza yeni giriş öncekinin bildirim kaydını kapatır; ödeme
  sonuç sayfasında XSS kaçışı, callback sonuçlanmış siparişi bozmaz; etkinlik misafir QR'ını yalnız
  oluşturan (ya da ofis/yönetici) siler; giriş yanıtında parola hash'i yok; teyit bildirimi bildirimin
  üyesine yazılır; antrenörün `ANTRENOR_IPTAL` talebi artık reddedilmiyor.

