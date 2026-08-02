# Sürüm Notları

> Mağaza vitrinine girilecek "Yenilikler / What's New" metinleri ve teknik özet.
> Yeni sürüm en üste eklenir.

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
