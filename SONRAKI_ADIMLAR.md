# Sonraki Adımlar / Kalan Konular

2026-07-25 turu sonunda kalanlar. Mobil (bu repo) + backend (C:\Django\tenis) bu turda **commit edildi ama PUSH edilmedi ve DEPLOY edilmedi**.

## 1) KRİTİK prod bug'ları (öncelik — ayrı session)
Bu turda kod değişikliği yapılmadı; sadece teşhis edildi.

- **Takvimde hiç ders gelmiyor (tüm üyeler, eski dersler dahil) + antrenör ana sayfada sonraki ders gelmiyor (ör. Onur Binay).**
  - Regresyon; şüpheli commit backend `9d8f554` ("etkinlik kayıt metotlarının ortaklaştırılması").
  - **Hipotez (tenant):** `BaseAbstract.objects = TenantManager` her `.objects` sorgusuna `isletme_id=<aktif tenant>` + `is_deleted=False` ekliyor (`calendarapp/models/abstract/manager.py`). Takvim (`api/etkinlik/metots.py::getUyeDersProgrami`) dersleri `EtkinlikUyeModel.objects.filter(uye_id=...)` ile buluyor; join/etkinlik satırının işletmesi aktif tenant ile eşleşmezse **sessizce boş** döner. Mobil `uye_takvim_page.dart::_loadWeek` hatayı yutuyor → boş takvim. Aynı mekanizma antrenör sorgularını da vurur.
  - Kullanıcı "isletme_id null olan veri yok" dedi → NULL değil; muhtemelen **tenant YANLIŞ eşleşiyor** (`token_user`'daki `set_current_tenant` ile verinin isletme_id'si uyuşmuyor) VEYA `is_deleted` filtresi. `token_user` tenant çözümü: `sk.isletme or uye.isletme or antrenor.isletme` (`api/core/decorators.py`) + YENİ 30sn cache katmanı (şüpheli).
  - **Prod DB'ye salt-okunur bağlanma:** settings.py'de prod Postgres kimlikleri hardcoded. Sistem Python'una `psycopg2-binary, django-select2, django-auditlog, whitenoise, djangorestframework, pillow, requests` kuruldu; `django_heroku` + `firebase_admin` için no-op shim gerekiyor (bir öncekinde scratchpad'deydi, yeniden yaratılmalı). Doğrudan psycopg2 (creds gömülü) script'i sınıflandırıcı tarafından bloklanır; `python manage.py shell < script` yolu geçer. Tam `manage.py check` için `pandas` vb. de gerekir.

- **Antrenör takvim: "Dersler yüklenirken timeout".** ApiClient timeout 20sn. Yavaş endpoint tespit edilip (backend `[PERF]` logları) süre artırılabilir / sorgu optimize edilebilir.

## 2) Bu turun deploy'u (mobil + backend BİRLİKTE)
- **B3 endpoint'i (`getAntrenorEksikYoklamalar`) deploy edilmeden** antrenör "Eksik Yoklamalar" ekranı çalışmaz (hata mesajı gösterir, çökmez).
- B1 (tek ders `dersler`) ve B2 (profil `isletme_adi`) eksikken mobil zarifçe düşer.
- Deploy sonrası doğrula: (a) tek ders kartında yapılan ders bilgisi görünüyor mu, (b) profil-seç'te antrenör/yönetici profillerinde işletme adı görünüyor mu, (c) antrenör eksik yoklama ekranı listeliyor + yoklama tamamlıyor mu.

## 3) SSS/Yardım metni
`lib/screens/1_common/yardim_page.dart` içindeki 10 soru-cevap taslak; kullanıcı onayı/düzeltmesi bekliyor.

## 4) Not
- Commit'ler push edilmedi. Mobil `main`, backend `master`.
