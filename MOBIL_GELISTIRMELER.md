# Mobil Geliştirme — Durum ve Yol Haritası

Mobil tarafın **tek durum dosyası**: şu anki durum, açık işler, sıradaki fikirler. Geçmiş burada
anlatılmaz; biten turların ayrıntısı backend deposundaki `C:\Django\tenis\history.md`'de (iki repo için
de, tarihli). Bir iş bitince buradan silinir, history.md'ye girer.

---

## 📌 Şu anki durum (2026-11-13)

| | |
|---|---|
| Mobil | **3.15.0+49** iki mağazada yayında (2026-11-06; yumuşak uyarı, `min_destekli` 3.13.1+47). **3.16.0+50** tag'lendi (2026-11-13; yönetici yeniden tasarım, bildirim tercihleri, kullanıcı adı, geri tuşu, Çivit). |
| Testler | `flutter test` **5096 geçiyor** (2026-11-13), `flutter analyze` temiz; backend **1729 geçiyor** (yerel Postgres, 2026-11-05). |
| Backend | Heroku `master` ile aynı (v358 `a36578d`, 2026-11-13; göçler 0110'a kadar canlı). |
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

### 3.16.0 yayın sonrası
- Mağazada canlı görülünce admin'de 3.16.0 sürüm notunun `yayinda`'sı ve konfig (kullanıcı).
- Telefonda göz kontrolü: yönetici ekranları; PDF dekont indirme gerçek cihazda denenmedi.
- App Check tanılama logu bu sürümle geliyor (aşağıda Güvenlik 3).

### Prod ayarları (kullanıcı, doğrulanmadı)
- Üye ders talebi: prod admin'de `uye_talep_hoca_idleri`, `uye_talep_kort_idleri`,
  `uye_talep_tek_ders_urun_idleri` (boş = tümü; salonlar, branş hocaları, pilates ürünleri de çıkar) ve
  `uye_talep_ofis_calisma_saatleri`. Scheduler'da `uye_talep_zamanlayici` 2026-11-02'den beri var.
  Bilinçli kararlar: öneri saati hocaya uygulamadan sorulmaz, talep detayında zaman çizgisi yok.
- Başka işletmeye üyelik: Pilates işletmesi id 3 (2026-11-08); kort/hoca ve hocalara yönetici/ofis
  profili kurulumu doğrulanmadı. Mobil ofiste üye onay ekranı yok (onay web'de); istenirse ayrı iş.

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
  2. ~~Backend deploy (`auths.0014` göçü) → App Check'li sürüm yayını~~ yapıldı.
  3. Sayaçlarda güncel sürümde `yok`/`gecersiz` kalmadığında (GMS'siz Huawei, Play Integrity günlük
     10.000 kotası burada görünür) zorunlu güncelleme aç, sonra (anahtar yenileme bittiyse) Heroku'da
     `APP_CHECK_MODU=zorunlu`.
     **2026-11-08 durumu:** iOS isteklerinin ~%25'i token'sız (Android ~%7), geçersiz neredeyse yok; izin
     ve kayıt doğru. Şüphe: token 2 sn beklemeyi aşıyor. 3.16.0 token alınamayınca/geç gelince
     sebebi mobil loga yazar (`[MOBİL] ... Sayfa=AppCheckServisi`, olay `hata`/`bos`/`gec`, açılış başına
     bir kez). Yayından sonra log tablosundan oku, sonra karar ver.
  root/Frida tespiti için ücretsiz freeRASP sonra eklenebilir.

### Doğrulanacaklar
- **İptal signal'ları:** 2026-09-29'dan beri çalışıyor; veri kontrolü için
  `heroku run python manage.py veri_tutarlilik_kontrol --ders-basi 2026-07-23 --kategori paket,tekders,telafi,onay,ekstra`.

- **"?" öğrenme rehberi (2026-11-05, main'de, push edildi ab3d70e):** 148 rehber dört profilde. Sahip telefonda
  gözden geçiriyor, hata gördükçe ekran adını söyler; kontrol kuralı CLAUDE.md'de. Ders talebi rehberleri
  eklendi (üye Taleplerim, ofis talepler).

### Küçük işler
- **Ders iptal talebi backend temizliği** (mobil ekranlar 2026-11-04'te silindi, 3.15.0): `EtkinlikIptalTalebiModel`
  (`etkinlik_iptal_talebi`, prod'da 63 eski kayıt), `etkinlik_iptal_service`, `api/urls.py` iptal uçları
  (`etkinlikIptalTalebiOlustur` … `iptalTalebiGeriCek`), admin kaydı, enum'lar. **`min_destekli` 3.15.0'a
  çıkmadan silinmez:** 3.13.1 ve 3.14.0 bu uçları çağırıyor.

---

## 📋 Sonraki fazlar — öneriler

### Üye
- **Sizden Gelenler** (2026-10-12, "şimdilik dursun"): üyelerin ders/turnuva fotoğrafı-videosu paylaşımı.
  Tasarlanırken moderasyon, çocuk üyeler için veli izni / KVKK, depolama ve görünürlük netleşmeli.
- Gelişim/istatistik ekranı — aylık ders sayısı, katılım %, seviye ilerlemesi, rozet.
- Antrenör karnesi — ders sonrası not/puanın üyeye açılması (değerlendirmeler 2026-10-16'dan beri yalnız
  yöneticiye açık; görüşme notu 2026-08-10'da kaldırıldı).
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
