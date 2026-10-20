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

