# Mobil Geliştirme — Durum ve Yol Haritası

Mobil tarafın **tek durum dosyası**: şu anki durum, açık işler, sıradaki fikirler. Geçmiş burada
anlatılmaz; biten turların ayrıntısı backend deposundaki `C:\Django\tenis\history.md`'de (iki repo için
de, tarihli). Bir iş bitince buradan silinir, history.md'ye girer.

---

## 📌 Şu anki durum (2026-10-23)

| | |
|---|---|
| Mobil | **3.13.1+47** güvenlik güncellemesi branch `guvenlik-guncellemeleri`'nde hazır, tag'lenmedi (2026-10-23). 3.13.0 (2026-10-20) Play production + App Store incelemesine gitmişti. |
| Testler | `flutter test` **3634 geçiyor**, `flutter analyze` temiz; backend `guvenlik-guncellemeleri` **1565 geçiyor** (yerel Postgres, 2026-10-23). |
| Backend | Canlı, GitHub master canlıyla eşit. Son migration'lar `0097_ders_kayit_talebi`, `0098_dekont`, `0099_uye_borc_kontrol`. Canlıda bir banka hesabı girili (işletme 1). |
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

### Kullanıcı kararı bekleyenler
- **Ciro hesabı (2026-09-25'ten beri bilinçli olarak dokunulmadı):** ciro yalnız yönetici onaylı dersleri
  sayıyor ve `urun.toplam_ucret` üzerinden hesaplanıyor; borç ise `ucret` + fiyat geçmişi + katılımcı
  sayısıyla yazılıyor. Onaylar biriktiği için ciro kartı gerçeğin çok altında; geç iptal edilip "yapıldı"
  sayılan dersler de ciroya girmiyor. Onay birikimi tek seferlik derslerin borcunu da bekletiyor (borç
  onayda yazılıyor) — faturalama konusu.
- **`UyeModel.profil_fotografi` (ImageField) düşürülsün mü:** 2026-10-13'ten beri kimse yazmıyor, fotoğraf
  `profil_fotografi_url` üzerinden. Düşürmek geri dönüşü olmayan veri kaybı.

### Güvenlik (2026-10-22 incelemesi)
- **Güvenlik güncellemesi yayını (3.13.1, yapılacak):** kod iki repoda `guvenlik-guncellemeleri`
  branch'inde (backend: `C:\Django\tenis-guvenlik` worktree'si; master'da başka oturum çalışıyor,
  birleştirirken `auths` göç numarası çakışmasına bak). İki ajan doğruladı. Backend eski sürümlerle
  UYUMSUZ: kanıtsız `createToken` reddediliyor, `pv`'siz token'lar düşüyor. Sıra:
  1. Mobil 3.13.1 iki mağazaya, **elle yayın** seçeneğiyle; ikisi de onaylanınca
  2. backend'i yayına al (`auths.0013` göçü release'te koşar),
  3. hemen mobili yayınla ve `mobil_uygulama_konfig`'ten 3.13.1 için zorunlu güncelleme aç,
  4. aynı gün anahtar yenileme (aşağıda) — herkes zaten bir kez yeniden giriş yapacak.
  Kapsam dışı bırakılanlar: web'in kendi şifre sıfırlama/giriş sayfaları hesabın varlığını hâlâ ele
  veriyor; Django sürüm yükseltmesinde parola yeniden hash'lenince diğer cihazlardaki oturumlar bir
  kez düşer (`pv` hash'ten türüyor).
- **Repodaki sırlar — anahtar yenileme (yapılacak):** prod'da `SECRET_KEY` config var'ı yok; JWT imzası
  git'teki yedek değerle atılıyor, yani repoyu gören biri istediği kullanıcı adına token üretebilir.
  `settings.py`'de ayrıca Gmail, VatanSMS, Param yedek değerleri; git'te
  `eventcalendar/keys/serviceAccountKey.json`. Sıra: anahtarları yenile → Heroku config var'a koy → yedek
  değerleri sil (env yoksa uygulama açılmasın) → anahtar dosyasını git'ten çıkar. `SECRET_KEY` değişince
  tüm oturumlar düşer ve kart QR'ları (`signing`, aynı anahtar) geçersizleşir: kartlar yeniden üretilmeli.

### Doğrulanacaklar
- **Karekod indirme gerçek telefonda:** emülatörde Dart HTTP isteği storage.googleapis.com'a 20 sn'de zaman
  aşımına düşüyordu (aynı adres emülatör Chrome'unda açılıyor).
- **İptal signal'ları:** 2026-09-29'dan beri çalışıyor; veri kontrolü için
  `heroku run python manage.py veri_tutarlilik_kontrol --ders-basi 2026-07-23 --kategori paket,tekders,telafi,onay,ekstra`.

### Küçük işler
- Antrenör SSS'ine yoklama hatırlatma bildirimi ve bilgi kartları hakkında soru (Scheduler çalışıyor,
  özellik canlı; soru "çalışmıyor" sanıldığı için konmamıştı).
- 3.10.0 ekran denetiminden ertelenenler (hâlâ geçerli mi bakılmalı): yönetici rapor bölümleri çok renkli,
  açık modda bazı ikon/yazılar düşük kontrastlı; antrenör profil başlığı kısa içerikte tam kapanmıyor;
  takvim bloğu 1.3 yazı ölçeğinde bir saatlik dersi kompakt moda düşürüyor; ders iptal sayfasında ikinci
  tutamaç (`showDragHandle`); devir bildirimindeki "Reddet" butonları dolu kırmızı.
- Akademiye not: popup duyurusu yalnız aksiyon gerektiren duyurular için, aynı anda tek popup, alt başlık
  popup'ta özet (~120 karakter), kare görsel önerilir.
- Canlı ortam: SayfaYetki'si kısıtlı web kullanıcılarına `calendarapp:dekontlar` ve
  `calendarapp:ders_kayit_talepleri` eklenince sayfalar görünür.

---

## 📋 Sonraki fazlar — öneriler

### Üye
- **Sizden Gelenler** (2026-10-12, "şimdilik dursun"): üyelerin ders/turnuva fotoğrafı-videosu paylaşımı.
  Tasarlanırken moderasyon, çocuk üyeler için veli izni / KVKK, depolama ve görünürlük netleşmeli.
- **Ders kayıt talebi üye ekranı:** `DersKayitTalebiModel` üye talebine hazır.
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
