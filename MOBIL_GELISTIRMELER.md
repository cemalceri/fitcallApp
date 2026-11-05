# Mobil Geliştirme — Durum ve Yol Haritası

Mobil tarafın **tek durum dosyası**: şu anki durum, açık işler, sıradaki fikirler. Geçmiş burada
anlatılmaz; biten turların ayrıntısı backend deposundaki `C:\Django\tenis\history.md`'de (iki repo için
de, tarihli). Bir iş bitince buradan silinir, history.md'ye girer.

---

## 📌 Şu anki durum (2026-11-05)

| | |
|---|---|
| Mobil | **3.14.0+48** iki mağazada yayında (güncelleme uyarısı açılmadı, üyelerin çoğu 3.13.1'de). **3.15.0+49 hazır, tag'lenmedi** (2026-11-05; ders talebi, rehber, başka işletme, plan dışı telafi + 3.14.0): sıra [SURUM_NOTLARI.md](SURUM_NOTLARI.md)'de, önce backend. |
| Testler | `flutter test` **4549 geçiyor** (2026-11-05), `flutter analyze` temiz; backend **1729 geçiyor** (yerel Postgres, 2026-11-05). |
| Backend | Heroku v351 (`040ebb7`). Bekleyen deploy: 0104–0107 (hoca katsayısı, kullanılmayan modeller, işletme başvurusu, plan dışı telafi). |
| Mağaza | 3.13.0 mağaza metni yalnız 3.12.0'dan sonraki üye yenilikleri. Mağaza görselleri yenilenmedi (kullanıcı kararı 2026-10-20, turuncu tonu değişti — 2.3.3 riski kabul). |

### Her sürümde

1. `lib/common/api_urls.dart`'ta `baseUrl = baseUrlProd` olmalı (2026-10-13'te local adresle commit
   edilmişti; o hâlde çıkan sürüm hiçbir API'ye ulaşamaz).
2. Backend'de `surum_notlari.json`'a "Neler yeni?" bloğu → **önce backend deploy**.
3. `pubspec.yaml` `version:` bump (build numarasını Codemagic mağazadan alır) + `release_notes.json`'ı
   o sürüm için yeniden yaz + `SURUM_NOTLARI.md`'ye bölüm → tag. Ayrıntı: [SURUM_NOTLARI.md](SURUM_NOTLARI.md),
   [CODEMAGIC_KURULUM.md](CODEMAGIC_KURULUM.md).
4. Mağazada canlı görülünce: admin'de sürüm notunun `yayinda_mi`'sı ve `mobil_uygulama_konfig`
   (kullanıcı yönetiyor, prod DB'ye yazılmaz).

---

## 🔴 Açık işler

### Başka işletmeye üyelik (Pilates ayrı işletme, 2026-11-05; iki repoda commit'li, push/deploy yok)
- Kod tamam: üye Ayarlar > "Başka işletmeye üyelik" (`2_uye/isletme_basvuru/`, yalnız ana hesap) →
  hedef işletmede onay bekleyen kopya üye; onay web "Üye onayla"da, onayda profil mevcut hesaba bağlanır
  (yeni kullanıcı/şifre SMS'i yok), bildirim `isletme_basvurulari`. Backend migration `0106`.
  Rehber "Başka işletmeye nasıl üye olurum?" (Ayarlar), üye SSS'i.
- Kalan (kullanıcı): backend deploy, prod'da Pilates `IsletmeModel` + kort/hoca + hocalara yönetici ve ofis
  profili. Mobil ofiste üye onay ekranı yok (onay web'de); istenirse ayrı iş.
- Test ajanı düzeltmeleri commit'li (hesapla eşleştirme, kilit, onay geri alınınca profil kapanır). Aynı
  turda: ofis bildirim listesi, dekont bildirimi role göre, plan dışı "Telafi" kararı (migration `0107`).

### Üye ders / kort kiralama talebi (2026-10-31; backend CANLI Heroku v351, mobil 2026-11-05'te main'e alındı ve push edildi)
- Kod tamam: üye sihirbazı + Taleplerim (`2_uye/talep/`; giriş yan menüde "Ders Talebi ve Kort Kiralama", ana sayfada yok), ofis sekmeli Talepler + detay/öneri
  (`8_ofis/ders_kayit_talepleri/`), hoca "Ofis Soruyor" (`3_antrenor/talep_sorulari/`), web aynı sayfada.
  Kurallar backend `parametre` tablosunda (`uye_talep_*`). Kullanım kılavuzu: `kilavuz/` (PDF, commit'siz).
- Hoca katsayısı antrenör kaydında (`ozel_ders_katsayisi`, backend 0104, master `75e77da`, push/deploy yok):
  yalnız talepte kullanılır; ilk değer geçmiş paket/tek ders derslerinden (Onur Binay 2, diğerleri 1).
- Tek seferlik ders ürünü şimdilik her üyede "Yetişkin-tekders-tekli" (seviyeye göre seçim istenmedi);
  kort kiralama "KortKira-1Saat".
- Mobil main'e birleşti ve push edildi (2026-11-05, ab3d70e) (`kilavuz/` PDF'i commit'siz). Backend telafi bildirimi düzeltmesi
  (talepten gelen telafili derste ayrı "Telafi kullanıldı" gitmez) master `0b08a70`, GitHub'da, Heroku'da
  DEĞİL; kullanıcı: sonraki kurulumla gider.
- Yayından önce (kullanıcı): prod admin'de `uye_talep_hoca_idleri`, `uye_talep_kort_idleri` ve
  `uye_talep_tek_ders_urun_idleri` doldurulmalı (boş = tümü; salonlar, branş hocaları, pilates ürünleri de
  çıkar), `uye_talep_ofis_calisma_saatleri` kontrol, Heroku Scheduler'a 10 dakikada bir
  `python manage.py uye_talep_zamanlayici`. Prod parametre değerleri doğrulanmadı (`heroku run` bu
  makineden zaman aşımı).
- 2026-10-31 üye/ofis/antrenör rol ajanlarıyla prod kopyasında denendi; bulunan hatalar düzeltildi.
  Bilinçli kararlar: öneri saati hocaya uygulamadan sorulmaz (ofis "hocayla konuştum" işaretler), talep
  detayında zaman çizgisi yok, profile bağlı tüm kullanıcılara bildirim gider.

### Güvenlik (2026-10-22 incelemesi)
- **Repodaki sırlar — anahtar yenileme (yapılacak):** 2026-10-28'de `SECRET_KEY`, VatanSMS ve Firebase
  servis hesabı anahtarı Heroku config var'ına taşındı, `settings.py` yedekleri silindi, anahtar dosyası
  repodan çıktı. Değerler AYNI kaldı ve git geçmişinde duruyor: repoyu gören biri hâlâ JWT üretebilir.
  Kalan: `SECRET_KEY` ve Firebase anahtarını yenile → config var'ları güncelle. `SECRET_KEY` değişince
  tüm oturumlar düşer ve kart QR'ları (`signing`, aynı anahtar) geçersizleşir: kartlar yeniden üretilmeli.
  Eski Firebase anahtarıyla geçerli App Check token'ı da basılabildiği için App Check zorunlu moda bundan
  önce geçmez.
- **Firebase App Check (kod hazır 2026-10-28, "log" modunda; branch `app-check` iki repoda, 2026-10-30'da
  main/master'ın üstüne alındı, AGP 9 ile Android debug derlemesi geçti):** mobil her isteğe `X-Firebase-AppCheck`
  (Android Play Integrity, iOS App Attest; debug derlemede debug sağlayıcı) + `X-Platform` +
  `X-Uygulama-Surumu` ekler (`app_check_service.dart`). Backend `api/core/app_check.py`: `APP_CHECK_MODU`
  `log` (varsayılan, reddetmez) / `zorunlu` / `kapali`; sonuçlar admin → "App Check Sayaçları"nda gün ×
  sonuç × platform × sürüm. `gate` (turnike) ve `getMobilConfigs` muaf. Kalan sıra:
  1. ~~Elle~~ **yapıldı (2026-10-30):** Firebase App Check'te Android Play Integrity (uygulama imzalama
     SHA-256'sı) ve iOS App Attest kayıtlı, zorunlu kılma KAPALI; Play Console'da Play Integrity API
     `fitcallapp` Cloud projesine bağlı (günlük 10.000); Apple Developer'da App ID'de **App Attest** açık.
     Emülatörde denerken logdaki debug token'ı konsola eklemek gerekir.
  2. Backend deploy (`auths.0014` göçü) → App Check'li sürüm yayını.
  3. Sayaçlarda güncel sürümde `yok`/`gecersiz` kalmadığında (GMS'siz Huawei, Play Integrity günlük
     10.000 kotası burada görünür) zorunlu güncelleme aç, sonra (anahtar yenileme bittiyse) Heroku'da
     `APP_CHECK_MODU=zorunlu`.
  root/Frida tespiti için ücretsiz freeRASP sonra eklenebilir.

### Doğrulanacaklar
- **İptal signal'ları:** 2026-09-29'dan beri çalışıyor; veri kontrolü için
  `heroku run python manage.py veri_tutarlilik_kontrol --ders-basi 2026-07-23 --kategori paket,tekders,telafi,onay,ekstra`.

- **"?" öğrenme rehberi (2026-11-05, main'de, push edildi ab3d70e):** 148 rehber dört profilde. Sahip telefonda
  gözden geçiriyor, hata gördükçe ekran adını söyler; kontrol kuralı CLAUDE.md'de. Ders talebi rehberleri
  eklendi (üye Taleplerim, ofis talepler).

### Küçük işler
- 3.10.0 ekran denetiminden ertelenenler (hâlâ geçerli mi bakılmalı): yönetici rapor bölümleri çok renkli,
  açık modda bazı ikon/yazılar düşük kontrastlı; antrenör profil başlığı kısa içerikte tam kapanmıyor;
  takvim bloğu 1.3 yazı ölçeğinde bir saatlik dersi kompakt moda düşürüyor; ders iptal sayfasında ikinci
  tutamaç (`showDragHandle`).
- **Ders iptal talebi kaldırıldı (2026-11-04):** mobilde üye/antrenör ekranları silindi. Backend tarafı sonra
  silinecek: `EtkinlikIptalTalebiModel` (`etkinlik_iptal_talebi`, prod'da 63 eski kayıt), `etkinlik_iptal_service`,
  `api/urls.py` iptal uçları (`etkinlikIptalTalebiOlustur` … `iptalTalebiGeriCek`), admin kaydı, enum'lar.

---

## 📋 Sonraki fazlar — öneriler

### Üye
- **Sizden Gelenler** (2026-10-12, "şimdilik dursun"): üyelerin ders/turnuva fotoğrafı-videosu paylaşımı.
  Tasarlanırken moderasyon, çocuk üyeler için veli izni / KVKK, depolama ve görünürlük netleşmeli.
- Gelişim/istatistik ekranı — aylık ders sayısı, katılım %, seviye ilerlemesi, rozet.
- Antrenör karnesi — ders sonrası not/puanın üyeye açılması (değerlendirmeler 2026-10-16'dan beri yalnız
  yöneticiye açık; görüşme notu 2026-08-10'da kaldırıldı).
- Ders talep sihirbazı — eski yarım akış 2026-09-29'da tümüyle silindi; yapılırsa baştan tasarlanacak.
- Self-servis telafi — telafi hakkını boş slotlardan üyenin planlaması.
- Veli görünümü — ana hesabın birden çok çocuğun dersini/borcunu tek ekranda görmesi.
- Kredi kartıyla ödeme (Param POS kodu var, bağlı değil; buton şimdilik EFT/Havale'ye yönlendiriyor),
  kayıtlı kart, PDF makbuz.
- Açık kort dersinde hava durumu; seviyeye göre antrenman partneri eşleştirme; boş kort kiralama
  (self-servis rezervasyon + online ödeme).

### Antrenör
- Öğrenci gelişim defteri — etiketli hızlı notlar (servis, forehand...).
- Video/foto geri bildirim — ders videosu yükleyip öğrenciyle paylaşma.

### Yönetici / ofis
- Duyurular v2: "bugün/yarın dersi olup görmeyenler" filtresi, dashboard kartı, görmeyenlere push, mobilde
  "yayından kaldır".
- Web muhasebe ana listesine (`muhasebe/index`) kesinleşme ve son kontrol sütunları / filtreleri.

### Platform
- Offline cache (stale-while-revalidate ile hızlı açılış).
- Bildirim tercihleri — kullanıcı hangi bildirim türlerini alacağını seçsin.
- Üye ↔ antrenör ↔ yönetim iletişim kısayolu (mesaj / WhatsApp deep-link).
- Ana sayfa kart yerleşimi ve görsel tasarımı (üye + antrenör) — tasarım turlarında kullanıcı kararıyla
  kapsam dışı bırakıldı.

### Etkileşim / oyunlaştırma (fikir, 2026-08-21 araştırması)
Amaç üyenin gün içinde uygulamaya uğraması; oyun akademiye trafik getirmeli (el hakkı derse katılımdan /
kort rezervasyonundan kazanılır, puan gerçek ödüle döner).
- **Servis Düellosu:** asenkron 1v1 tahmin düellosu. Servis atan yön + tip, karşılayan yön tahmini gizli ve
  eşzamanlı seçer; sunucu iki taraf da girince açar. Tek oyun (4 sayı), 2-3 güne yayılır; rakip yoksa
  geçmiş seçimlerden üretilen hayalet rakip; günlük el hakkı sınırlı. Kapsam: iki tablo, 5-6 uç, iki ekran,
  bir FCM tetikleyicisi. Risk: derinlik sınırlı → önce 20-30 kişilik kapalı test. Gerçek zamanlı PvP
  akademi ölçeğinde rakip bulamaz.
- **Kulüp merdiveni (ladder):** üstündeki 3 kişiden birine meydan okuma, kortu uygulamadan ayırma, skor
  girme. Kort doluluğunu doğrudan artırır.
- **Turnuva tahmini (pick'em):** braket doldurma + kulüp lider tablosu; en ucuzu ama sezonluk.

---

## 🗄️ Arşiv — çözülmüş kritik bug'ların dersleri

- **`bool?` onay alanlarında null'ı asla `== true` / `?? false` ile ikiye indirme** — kayıt yokluğu bir
  karar değildir. (2026-08-15: yönetici onaylı derste antrenör satırı yokken "Ders Yapılmadı" görünüyordu;
  prod'da 3.960 ders. Çözüm üç durum: yapıldı / yapılmadı / yoklama alınmadı.)
- **"Boş liste / timeout" şikâyetinde önce endpoint süresine bak, tenant'a değil.** (2026-07-28:
  `getUyeDersProgrami` tarih aralığını yok sayıp tüm dersleri dönüyordu, 220 sn; `ApiClient`'ın 20 sn
  timeout'u sessizce yutuluyordu → boş takvim. Lokal Django + uzak prod DB semptomu büyütür.)
