# CLAUDE.md

"fitcall": Binay Akademi spor akademisinin Flutter mobil uygulaması. Roller üye, antrenör, ofis (ön büro), yönetici; backend REST `https://www.binay.fit/api`. Kod, yorum ve arayüz metni **Türkçe**; yeni kod da öyle. Baş kurallar kullanıcı düzeyindeki `~/.claude/CLAUDE.md`'de.

## Dokümanlar (gerektiğinde oku, hepsini birden değil)

| Dosya | Ne zaman |
|---|---|
| [MIMARI.md](MIMARI.md) | Koda dokunmadan önce ilgili bölümü: API katmanı, auth/rota, bildirim, tarih, ofis/yönetici ayrımı, renk/tema, taşma, ekran kalıpları. |
| [MOBIL_GELISTIRMELER.md](MOBIL_GELISTIRMELER.md) | Özellik/planlama başında. Tek durum dosyası: sürüm, her sürümde yapılacaklar, açık işler, backlog. Biten iş oradan silinir, backend `history.md`'ye yazılır; ikinci "bekleyen iş" dosyası açma. |
| [SURUM_NOTLARI.md](SURUM_NOTLARI.md) | Sürüm çıkarırken. Yalnız tr-TR; her `version:` bump'ında bölüm ekle ve `release_notes.json`'ı baştan yaz (Play `tr-TR` ≤500 karakter, App Store `tr`, `<`/`>` yok). |
| [CODEMAGIC_KURULUM.md](CODEMAGIC_KURULUM.md) | `codemagic.yaml` / yayın hattı. |

Backend: `C:\Django\tenis` (branch `master`, Heroku). `history.md` iki repoyu kapsayan tarihli kayıt (önemli değişiklikten sonra kısa girdi ekle); `MODEL_ILISKILERI.md` model/FK/akışlar. `AGENTS.md` yalnız buraya yönlendirir.

## Komutlar

```powershell
flutter pub get; flutter analyze; flutter test   # test/<dosya>_test.dart ile tek dosya
```

Yayın Codemagic'te, tag ile. `lib/common/api_urls.dart`'ta `baseUrl` **her zaman `baseUrlProd`** commit edilir (local `10.0.2.2:8000` yalnız denerken).

## Değişmez kurallar (ayrıntı MIMARI.md'de)

- **API:** yeni kod `ApiClient.postParsed/getParsed<T>` + `auth: true`; uçlar `api_urls.dart`'ta; modeller elle `fromJson`.
- **Rota:** ekran ekle = `SayfaAdi` + route string + builder (+ gerekirse `anaHesapOnly` politikası), `lib/common/routes.dart`.
- **Tarih:** okurken `parseApiTarih`, yazarken `formatApiTarih` (`lib/common/tarih_util.dart`); asla `DateTime.parse` / `.toUtc()`.
- **Ofis para ve özel üye verisi görmez** (tek istisna plan-dışı "borç yaz" tutarı). Sınır sunucudaki beyaz listede; eksik alanı listeyi genişleterek "düzeltme", sor. Aksiyonlar ofiste (`8_ofis/`), yönetici (`7_yonetici/`) yalnız raporlama.
- **Renk:** ekranda sabit renk yazma; `context.cs` / `context.renkler` / `context.gecis`. Başlıklar `gecis.baslik`, elle çizilen başlık `BaslikBandi`. `tema_kontrast_test` ve `gomulu_renk_mandal_test` geçmeli.
- **Taşma:** yazı ölçeği 1.0–1.3; her yeni görsel widget `test/tasma_ekranlar_test.dart`'a (`tasmaTesti`). API çağıran sayfanın görünümünü veriyle beslenen ayrı widget'a çıkar.
- **Listeler** `ListeSatiri` (kart yok), uzun listeler `SayfaliListe` (20'şer). **Yükleme** `Iskelet*`; `CircularProgressIndicator` yalnız buton içi / auth akışı.
- Takvim çizelgesi ortak (`1_common/takvim/`), ders bloğu (`lesson_block`, `position_calculator`) üye ve antrenörde ayrı; birindeki değişiklik çoğu zaman ötekinde de gerekir.
