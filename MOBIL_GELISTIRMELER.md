# Mobil Geliştirme Yol Haritası — Üye & Antrenör

Bu doküman, üye/antrenör deneyim geliştirmelerinin durumunu izler.
Backend değişiklikleri `C:\Django\tenis` reposundadır (branch: `feature/mobil-faz1-uye-antrenor`).

---

## ✅ FAZ 1 — Tamamlandı (2026-07-02)

### Üye tarafı

| # | Özellik | Mobil | Backend |
|---|---------|-------|---------|
| 1 | **Yapılacaklar kartları** — bekleyen teyit, borç, değerlendirilmemiş ders, paket bitiyor, telafi süresi | `uye_home_page.dart` + `InfoCardsCarousel` (başlık parametresiyle yeniden kullanım), 5 yeni kart tipi `home_card_model.dart` | `getUyeHomeOzet` — kartlar canlı hesaplanır (`api/uye/uye_home_ozet.py`) |
| 2 | **Özet şeridi** — Bakiye / Kalan Hak / Telafi | `widgets/uye_ozet_serit.dart` | aynı endpoint (`ozet` alanı) |
| 3 | **Paket bitiş uyarısı + CTA** | Yapılacaklar kartı → muhasebe | `paket_bitis_bildirim` komutu (günlük; kalan ≤ 2 **ve** son 45 günde kullanım şartı — bayat paketlere gitmez) |
| 4 | **Takvime ekle + ders öncesi hatırlatma** | `add_2_calendar` + ders detay popup'ında "Telefon Takvimine Ekle" | `ders_bildirimleri` komutu → `DERS_HATIRLATMA` push (~1 saat önce) |
| 5 | **Geçmiş Dersler sayfası** — katılım rozeti, antrenör notu, puan/değerlendir | `gecmis_dersler/gecmis_dersler_page.dart` + rota `/uyeGecmisDersler` + menü grid 6. öğe | `getUyeGecmisDersler` (`api/etkinlik/gecmis_dersler.py`) |

### Antrenör tarafı

| # | Özellik | Mobil | Backend |
|---|---------|-------|---------|
| 15 | **Günlük kokpit** — ders/öğrenci sayısı, ilk-son ders, eksik yoklama uyarısı | `home/widgets/gunluk_kokpit_card.dart` | `getAntrenorGunlukOzet` (`api/antrenor/gunluk_ozet.py`) |
| 16 | **Yoklama push'u** — ders sonrası; tıklayınca takvim + yoklama dialogu otomatik açılır | `notification_router.dart` `antrenor_yoklama` case'i + `antrenor_takvim_page.dart` argüman desteği | `ders_bildirimleri` komutu → `YOKLAMA_HATIRLATMA` push |
| 17 | **Öğrenci detay sayfası** — istatistik, paket/telafi, katılımlar, görüşme notları, tel/WhatsApp | `ogrenci_detay/antrenor_ogrenci_detay_page.dart` (eski statik sheet kaldırıldı) | `getAntrenorOgrenciDetay` (`api/antrenor/ogrenci_detay.py`; yetki: sorumlu hoca veya son 90 günde ders) |
| 18 | **Çalışma Saatlerim** — gün bazlı aç/kapa + saat aralığı | `calisma_saatleri/calisma_saatleri_page.dart` (profil menüsünden) | `getAntrenorCalismaGunleri` / `setAntrenorCalismaGunleri` |

### Veri doğruluğu ilkeleri (uygulandı)
- Tüm hesaplar backend'de tek kaynaktan; Flutter hesap yapmaz.
- Veri alınamazsa ilgili bölüm **gizlenir** (yanlış sayı göstermek yerine).
- Katılım yüzdesi yalnızca yoklaması girilmiş dersler üzerinden; yoklama yoksa `null`/"—".
- Paket-bitiyor uyarısı yalnızca aktif kullanılan paketlere (45 gün filtresi; gerçek veride aday 30→12).

### Test durumu
- `flutter analyze` temiz; `flutter test` 20/20 (16 yeni model parse testi + rota tutarlılık testleri — eski şablon sayaç testi kaldırıldı).
- Django: `manage.py check` temiz; gerçek veride read-only smoke doğrulaması yapıldı; komutlar `--dry-run` ile test edildi. Pytest testleri `tests/api/test_mobil_faz1.py` (lokalde koşamaz — CI için).

### Dağıtım (bekleyen adımlar)
1. Backend deploy (migration `0071` release'de otomatik) → sonra mobil sürüm (pubspec version bump + Codemagic).
2. **Heroku Scheduler'a eklenecek:** `python manage.py ders_bildirimleri` (10 dk'da bir) ve `python manage.py paket_bitis_bildirim` (günlük).
3. Yeni bildirim tipleri eski uygulama sürümlerinde varsayılan detay sheet'ine düşer — geriye uyumlu.

---

## 📋 BEKLEYEN ÖNERİLER — Sonraki fazlar

### Üye
- **(6)** Gelişim/istatistik ekranı — aylık ders sayısı, katılım %, seviye ilerlemesi, rozet/başarı (gamification)
- **(7)** Antrenör karnesi — antrenörün ders sonrası not/puanının üyeye "karne" akışıyla açılması (`GorusmeNotu` + `EtkinlikDegerlendirme` altyapısı hazır)
- **(8)** Ders talep sihirbazı — antrenör kartları + uygun saat ısı haritası (`getAntrenorUygunSaatleri` mevcut)
- **(9)** Self-servis telafi — telafi hakkını boş slotlardan üyenin kendisinin planlaması
- **(10)** Veli görünümü — ana hesabın birden çok çocuğun dersini/borcunu tek ekranda görmesi
- **(11)** Kayıtlı kart / tek tık ödeme + PDF makbuz
- **(12)** Açık kort dersinde hava durumu göstergesi
- **(13)** "Hitting partner" eşleştirme — seviyeye göre üyeler arası antrenman partneri
- **(14)** Boş kort kiralama — self-servis rezervasyon + online ödeme (yeni gelir kanalı)

### Antrenör
- **(19)** Öğrenci gelişim defteri — etiketli hızlı notlar (servis, forehand...), zaman içinde gelişim görünümü
- **(20)** Hakediş/kazanç ekranı — aylık yapılan/onaylanan dersler (`EtkinlikOnayModel.antrenor_hakedis_alacak_mi` mevcut)
- **(21)** Haftalık takvim görünümü — doluluk/boşluk genel bakışı
- **(22)** Video/foto geri bildirim — ders videosu yükleyip öğrenciyle paylaşma (galeri-medya altyapısı mevcut)

### Platform / Ortak
- **(23)** Bottom navigation bar (Ana sayfa · Takvim · Bildirimler · Profil)
- **(24)** Skeleton (shimmer) loading — spinner yerine iskelet kartlar
- **(25)** Offline cache — stale-while-revalidate ile hızlı açılış
- **(26)** Karanlık tema (Material 3 hazır)
- **(27)** Bildirim tercihleri — kullanıcı hangi bildirim türlerini alacağını seçsin
- **(28)** Üye ↔ antrenör ↔ yönetim iletişim kısayolu (mesaj/WhatsApp deep-link)

---

## 🔧 Yönetici ders yönetimi + altyapı (2026-07-24) — KOD HAZIR, COMMIT/DEPLOY BEKLİYOR

Tamamlandı ama **henüz commit edilmedi**. Deploy sırası: **önce mobil yayına, o çıkınca backend Heroku'ya** (aşağıdaki tarih-saat değişikliği eski mobil sürümü kırar).

- **Yönetici mobilden ders yönetimi:** `lib/screens/7_yonetici/program/` — gün seçici + kort×saat ızgarası, oluştur/düzenle/iptal(4 mod)/sil. Backend'de web ile **ortak servis** (`calendarapp/services/etkinlik_kaydet_service.py` + `etkinlik_iptal_service.py`); web view'ları da bunları çağırıyor. Yeni uçlar `yoneticiHaftalikProgram` / `yoneticiEtkinlik*`.
- **Güvenlik:** 8 yönetici API ucu kimlik doğrulamasız ve tenant'sızdı (iki işletme verisi karışıyordu) → `@token_user` + `@rol_gerekli("yonetici")`. **Deploy sonrası dashboard/rapor rakamları düşecek** (artık tek işletme) — beklenen.
- **Tarih-saat sözleşmesi:** tek standart (`lib/common/tarih_util.dart` ↔ `calendarapp/utils/tarih_util.py`). `EtkinlikModelSerializer`'daki gizli `+3 saat` hack'i kaldırıldı → **eski mobil sürüm 3 saat kayar**, o yüzden deploy sırası önemli.
- **Ölü signal düzeltmesi (backend):** `etkinlik_signals/` paketine `__init__.py` eklendi. ~5,5 aydır iptallerde telafi/paket iadesi/borç işlenmiyordu (sadece bildirim gidiyordu). **Deploy sonrası iptaller gerçek finansal kayıt üretmeye başlayacak** — ilk iptalleri gözle takip et. Geçmiş 5,5 ay geriye dönük işlenmez.
- **Taşma altyapısı:** app geneli yazı ölçeği clamp'i (`lib/common/ui_scale.dart`), `test/support/tasma_yardimcisi.dart` + `test/tasma_ekranlar_test.dart` (boyut×ölçek matrisi). Düzeltilen taşmalar: üye/antrenör hafta şeridi, üye "sonraki ders" kartı, yönetici ders liste öğesi.
- **Profil seçimi:** işletme adı gösteriliyor (`isletme_adi` serializer'a eklendi). Aynı kullanıcının iki işletme yönetici profili artık ayırt edilebiliyor.
- **Test durumu:** mobil `flutter test` 274 geçiyor; backend `pytest --ds=eventcalendar.test_settings --nomigrations` 162 geçiyor / 19 kalıyor (19 = muhasebe refactor'ü öncesi eski testler, bu işle ilgisiz baseline).

## 🔍 Test geri bildirimi bekleyenler

Faz 1 kullanıcı testi sonrası tespit edilen hata/düzeltmeler buraya işlenecek.

| Tarih | Ekran/Özellik | Sorun | Durum |
|-------|---------------|-------|-------|
| — | — | — | — |
