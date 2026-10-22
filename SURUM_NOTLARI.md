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

## 3.13.0 — 2026-10-20

### Mağaza metni (tr-TR)

`release_notes.json`'da `tr` ve `tr-TR` girdileri aynı (349 karakter). 3.12.0 iki mağazada da yayında,
yani yalnız ondan sonraki üye yenilikleri.

- Havale / EFT: kulübün IBAN'ı ve karekodu Muhasebe sekmesinde. IBAN'ı kopyalayın, karekodu indirip banka uygulamanızla okutun.
- Havale dekontunuzu fotoğraf ya da PDF olarak uygulamadan gönderin; durumunu Dekontlarım'da izleyin.
- Yeni renk temaları: Turuncu, Mavi, Yeşil ve Siyah (Ayarlar › Görünüm).
- Çeşitli iyileştirmeler ve hata düzeltmeleri.

### "Neler yeni?" popup'ı

Backend `surum_notlari.json`'da 3.13.0 bloğu: üye 3, antrenör 2, ofis 3, yönetici 3 madde (kurumsal
renk temaları dört profilde ortak). 3.12.0'daki karar gibi `yayinda` açık; popup yalnız 3.13.0 kurulu
cihazda çıkar. Mağaza görselleri yenilenmedi (kullanıcı kararı 2026-10-20; turuncu tonu değişti).

### Teknik

- **Havale / EFT (üye, #13).** Hesap Özeti'nde **EFT / Havale** + **Kredi kartı ile öde** (kart henüz
  yok, EFT / Havale'ye yönlendirir). `6_muhasebe/havale/`: banka hesapları (gruplu IBAN, kopyala,
  karekod — indirilip cihazda saklanır, İndir + Paylaş), tam ekran Dekont yükle (Kamera / Galeri / PDF,
  5 MB), Dekontlarım (durum, ret gerekçesi, bekleyeni geri çekme). Borç yokken "Borcunuz yok.
  Teşekkürler!". Ofise `OFIS_DEKONT_YUKLENDI` bildirimi, ofis üye detayını açar. Backend `0098_dekont`.
- **Ders kayıt talebi (antrenör + ofis).** Antrenör Takvim başlığından salt-okunur Tüm Program
  (`antrenorHaftalikProgram`), tek eylem "+ Ders kayıt talebi". Ofis Ana Sayfa'da "Ders kayıt
  talepleri (n)", kayıt `EtkinlikFormSheet` ile `talepId`'li. Izgara `1_common/program/`'a taşındı.
  Backend `0097_ders_kayit_talebi`.
- **Yönetici Üyeler (#12).** Birlikte çalışan filtre + 12 seçenekli sıralama (sunucuda, `filtreler` +
  `yon`), etkin filtre çipleri, "Kesin" rozeti; ayrı Borçlu Üyeler sayfası kalktı, Dashboard kartı ve
  menü Üyeler'i borçlu ön ayarıyla açar. Backend `0099_uye_borc_kontrol`.
- **Kurumsal temalar (#14).** Takım temaları kalktı; Turuncu `FE5000` (varsayılan, kod `binay`), Mavi
  `00A9E0`, Yeşil `43B02A`, Siyah. Kaldırılan kodlar varsayılana, `siyah_beyaz` Siyah'a düşer.
