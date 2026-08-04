# Mobil Geliştirme — Durum ve Yol Haritası

Bu dosya mobil tarafın **tek durum dosyasıdır**: ne bitti, ne açık, ne sırada.
(2026-08-04'te `SONRAKI_ADIMLAR.md` buraya eritildi — iki ayrı "bekleyen iş" listesi tutulmuyor.)

Backend `C:\Django\tenis` (branch `master`). Kronolojik değişiklik kaydı orada `history.md`'de;
burada sadece **durum** tutulur, geçmiş anlatılmaz.

---

## 📌 Şu anki durum (2026-08-04)

| | |
|---|---|
| Mobil | `main` = `origin/main` (push edilmiş), `pubspec` sürümü **3.6.0+39** |
| Testler | `flutter test` **523 geçiyor**, `flutter analyze` temiz |
| Backend | `master` = `origin/master` = `heroku/master` (`6a0f6fd`) → **canlıda** |
| Mağaza | Son yayınlanan sürüm **3.6.0**; sonrasındaki 4 commit henüz yayınlanmadı |

Codemagic sürüm adını `pubspec.yaml`'daki `version:` alanından, build numarasını mağazadaki
son build'den otomatik alır (`codemagic.yaml`). Yani yayın için **sadece `version:` bump'lanır**.

---

## 🔴 Açık işler

### 1. Sürüm çıkarma — plan dışı katılımcı / misafir özelliği
`b660f7d` (3.6.0) sonrası 4 commit yayınlanmadı: plan dışı katılımcı mobil tarafı, antrenör ana
sayfa düzeni, profil değiştirme butonu, ekran parlaklığı. **Backend tarafı canlıda** (`6a0f6fd`),
mobil taraf mağazada değil — yani özellik şu an kullanıcıda yok.
→ `pubspec.yaml` `version:` bump + Codemagic. Mağaza metni için `SURUM_NOTLARI.md`'ye yeni bölüm.

### 2. SSS/Yardım metni onayı
`lib/screens/1_common/yardim_page.dart` içindeki soru-cevap içeriği **taslak**; kullanıcı onayı /
düzeltmesi bekliyor. Son dokunuş `f5d1d62`.

### 3. Heroku Scheduler doğrulaması
Faz 1'in bildirim komutları Scheduler'a eklendi mi, teyit edilmedi (bu repodan doğrulanamaz):
- `python manage.py ders_bildirimleri` — 10 dakikada bir
- `python manage.py paket_bitis_bildirim` — günlük

### 4. Deploy sonrası gözlem (backend canlıya çıktı, izlenmeli)
- **İptal signal'ları:** `etkinlik_signals/` paketine `__init__.py` eklenmesiyle ~5,5 aydır işlemeyen
  telafi/paket iadesi/borç mantığı devreye girdi. İlk iptallerin finansal kayıtları gözle kontrol
  edilmeli. Geçmiş 5,5 ay geriye dönük işlenmiyor.
- **Tenant düzeltmesi:** 8 yönetici API ucu kimlik doğrulamasız ve tenant'sızdı (iki işletmenin
  verisi karışıyordu). Düzeltildikten sonra dashboard/rapor rakamlarının düşmesi **beklenen**
  davranıştır, hata değil.

---

## ✅ Tamamlanan turlar

### Faz 1 — üye & antrenör (2026-07-02)

**Üye**

| # | Özellik | Mobil | Backend |
|---|---------|-------|---------|
| 1 | **Yapılacaklar kartları** — bekleyen teyit, borç, değerlendirilmemiş ders, paket bitiyor, telafi süresi | `uye_home_page.dart` + `InfoCardsCarousel`, 5 kart tipi `home_card_model.dart` | `getUyeHomeOzet` (`api/uye/uye_home_ozet.py`) |
| 2 | **Özet şeridi** — Bakiye / Kalan Hak / Telafi | `widgets/uye_ozet_serit.dart` | aynı endpoint (`ozet` alanı) |
| 3 | **Paket bitiş uyarısı + CTA** | Yapılacaklar kartı → muhasebe | `paket_bitis_bildirim` komutu (kalan ≤ 2 **ve** son 45 günde kullanım) |
| 4 | **Takvime ekle + ders hatırlatma** | `add_2_calendar` + ders detay popup'ı | `ders_bildirimleri` → `DERS_HATIRLATMA` push (~1 saat önce) |
| 5 | **Geçmiş Dersler sayfası** | `gecmis_dersler/gecmis_dersler_page.dart`, rota `/uyeGecmisDersler` | `getUyeGecmisDersler` |

**Antrenör**

| # | Özellik | Mobil | Backend |
|---|---------|-------|---------|
| 15 | **Günlük kokpit** — ders/öğrenci sayısı, ilk-son ders, eksik yoklama | `home/widgets/gunluk_kokpit_card.dart` | `getAntrenorGunlukOzet` |
| 16 | **Yoklama push'u** — tıklayınca takvim + yoklama dialogu açılır | `notification_router.dart` `antrenor_yoklama` case'i | `ders_bildirimleri` → `YOKLAMA_HATIRLATMA` push |
| 17 | **Öğrenci detay sayfası** | `ogrenci_detay/antrenor_ogrenci_detay_page.dart` | `getAntrenorOgrenciDetay` (yetki: sorumlu hoca veya son 90 günde ders) |
| 18 | **Çalışma Saatlerim** | `calisma_saatleri/calisma_saatleri_page.dart` | `getAntrenorCalismaGunleri` / `setAntrenorCalismaGunleri` |

**Veri doğruluğu ilkeleri (kalıcı — yeni ekranlarda da geçerli)**
- Tüm hesaplar backend'de tek kaynaktan; Flutter hesap yapmaz.
- Veri alınamazsa ilgili bölüm **gizlenir** (yanlış sayı göstermek yerine).
- Katılım yüzdesi yalnızca yoklaması girilmiş dersler üzerinden; yoklama yoksa `null`/"—".
- Paket-bitiyor uyarısı yalnızca aktif kullanılan paketlere (45 gün filtresi).

### Yönetici ders yönetimi + altyapı (2026-07-24)

- **Yönetici mobilden ders yönetimi:** `lib/screens/7_yonetici/program/` — gün seçici + kort×saat
  ızgarası, oluştur/düzenle/iptal(4 mod)/sil. Backend'de web ile **ortak servis**
  (`etkinlik_kaydet_service.py` + `etkinlik_iptal_service.py`); kural değişiklikleri orada yapılır.
- **Tarih-saat sözleşmesi:** tek standart (`lib/common/tarih_util.dart` ↔ `utils/tarih_util.py`).
  `EtkinlikModelSerializer`'daki gizli `+3 saat` hack'i kaldırıldı.
- **Taşma altyapısı:** app geneli yazı ölçeği clamp'i (`lib/common/ui_scale.dart`),
  `test/support/tasma_yardimcisi.dart` + `test/tasma_ekranlar_test.dart` (boyut×ölçek matrisi).
  **Her yeni sunum widget'ı buraya eklenir.**
- **Profil seçimi:** işletme adı gösteriliyor; aynı kullanıcının iki işletme profili ayırt ediliyor.

### Üye/antrenör geri bildirim turu (2026-07-25 → 07-29)

- Özet şerit etiketleri + yeni rotalar (`uyelikPaket`, `telafiHaklari`, ikisi de `anaHesapOnly`).
- Üyelik/Paket sayfası Paket / Aidat / Tek Ders gruplu ve açılır-kapanır.
- Geçmiş ders etiket-renk düzeni (kulüp onayında / iptal / yönetici-yapılmadı / katılmadı).
- Teyit Bekleyen Dersler sayfası (`teyit_bekleyenler_page.dart` + `getUyeTeyitBekleyenler`).
- Antrenör Eksik Yoklamalar ekranı (`antrenor_eksik_yoklama_page.dart` + `getAntrenorEksikYoklamalar`).
- Alt bar (Takvim · Geçmiş · QR · Hareketler · Hesabım) + drawer; eski menü grid'i silindi.
- Login "beni hatırla" tam ekran overlay'i; profil sıralaması Yönetici > Antrenör > Üye.

### Saat dilimi bağımsızlığı (2026-08-02, sürüm 3.6.0)

Ders saatleri artık cihazın saat diliminden bağımsız, kulüp duvar saatiyle gösteriliyor.
Detay `SURUM_NOTLARI.md` → 3.6.0.

---

## 📋 Bekleyen öneriler — sonraki fazlar

### Üye
- **(6)** Gelişim/istatistik ekranı — aylık ders sayısı, katılım %, seviye ilerlemesi, rozet
- **(7)** Antrenör karnesi — ders sonrası not/puanın üyeye "karne" akışıyla açılması (`GorusmeNotu` + `EtkinlikDegerlendirme` altyapısı hazır)
- **(8)** Ders talep sihirbazı — antrenör kartları + uygun saat ısı haritası (`getAntrenorUygunSaatleri` mevcut)
- **(9)** Self-servis telafi — telafi hakkını boş slotlardan üyenin planlaması
- **(10)** Veli görünümü — ana hesabın birden çok çocuğun dersini/borcunu tek ekranda görmesi
- **(11)** Kayıtlı kart / tek tık ödeme + PDF makbuz
- **(12)** Açık kort dersinde hava durumu göstergesi
- **(13)** "Hitting partner" eşleştirme — seviyeye göre antrenman partneri
- **(14)** Boş kort kiralama — self-servis rezervasyon + online ödeme (yeni gelir kanalı)

### Antrenör
- **(19)** Öğrenci gelişim defteri — etiketli hızlı notlar (servis, forehand...), zaman içinde gelişim
- **(20)** Hakediş/kazanç ekranı — aylık yapılan/onaylanan dersler (`EtkinlikOnayModel.antrenor_hakedis_alacak_mi` mevcut)
- **(21)** Haftalık takvim görünümü — doluluk/boşluk genel bakışı
- **(22)** Video/foto geri bildirim — ders videosu yükleyip öğrenciyle paylaşma

### Platform / Ortak
- **(24)** Skeleton (shimmer) loading — spinner yerine iskelet kartlar
- **(25)** Offline cache — stale-while-revalidate ile hızlı açılış
- **(26)** Karanlık tema (Material 3 hazır)
- **(27)** Bildirim tercihleri — kullanıcı hangi bildirim türlerini alacağını seçsin
- **(28)** Üye ↔ antrenör ↔ yönetim iletişim kısayolu (mesaj/WhatsApp deep-link)

> (23) Bottom navigation bar 2026-07-29 turunda yapıldı — listeden çıkarıldı.

---

## 🔍 Test geri bildirimi

Kullanıcı testi sonrası tespit edilen hata/düzeltmeler.

| Tarih | Ekran/Özellik | Sorun | Durum |
|-------|---------------|-------|-------|
| — | — | — | — |

---

## 🗄️ Arşiv — çözülmüş kritik bug'lar

**Takvimde hiç ders gelmiyor / "Dersler yüklenirken timeout" (2026-07-28 çözüldü).**
Uzun süre `TenantManager` filtresi ve backend commit `9d8f554` suçlandı — **ikisi de yanlıştı**
(o commit hiç deploy edilmemişti, veri de temizdi). Gerçek sebep: `getUyeDersProgrami` mobilin
gönderdiği `start`/`end` aralığını yok sayıp üyenin **tüm** derslerini dönüyordu, ağır N+1
serializer'la birlikte endpoint 220sn sürüyordu; `ApiClient`'ın 20sn timeout'u `_loadWeek` içinde
sessizce yutuluyordu → boş takvim. Semptomu asıl büyüten kurulum: **lokal Django + uzak prod DB**
(sorgu başına ~150ms internet gecikmesi). Düzeltme: aralık filtresi (`api/etkinlik/metots.py`),
220sn → 7,6sn. Benzer bir "boş liste / timeout" şikâyetinde **önce endpoint süresine bak, tenant'a
değil.**
