# Codemagic Uçtan Uca Yayın Kurulumu

Amaç: `git tag v3.6.0 && git push origin v3.6.0` komutundan sonra hem Google Play
hem App Store'da yeni sürümün incelemeye gitmesi. Market konsollarında işlem yok.

Yapılandırma dosyası: [codemagic.yaml](codemagic.yaml)

---

## 1. Google Play servis hesabı (tek seferlik)

Şu an eksik olan tek büyük parça bu.

1. **Play Console** → *Setup* → *API access* → Google Cloud projesini bağla.
2. Google Cloud Console → *IAM & Admin* → *Service Accounts* → yeni servis hesabı
   oluştur → *Keys* → *Add key* → **JSON** indir.
3. Play Console → *Users and permissions* → *Invite new users* → servis hesabının
   e-postasını ekle → uygulama bazında şu yetkileri ver:
   - *View app information*
   - *Manage production releases*
   - *Manage testing track releases*
   - *Release to production, exclude devices, and use Play App Signing*
4. Yetkinin aktifleşmesi bazen birkaç saat sürebiliyor.

## 2. Codemagic ortam değişkeni

Codemagic → uygulama → *Environment variables*:

| Değişken | Değer | Grup | Secure |
|---|---|---|---|
| `GOOGLE_PLAY_SERVICE_ACCOUNT_CREDENTIALS` | indirilen JSON'un tamamı | `google_play` | ✅ |

İsimler birebir bu şekilde olmalı — `codemagic.yaml` bu adlara göre yazıldı.

## 3. Android keystore

Şu an AAB'yi local'de ürettiğin için keystore Codemagic'te yok.

Codemagic → *Teams* → *Code signing identities* → *Android keystores* → keystore
dosyasını, şifreleri ve alias'ı yükle. **Reference name: `binay_keystore`**
(başka bir isim verirsen `codemagic.yaml` içindeki `android_signing` değerini
güncelle).

> Play App Signing kullanıldığı için yüklenen keystore, mevcut sürümleri
> imzalayan **upload key** ile aynı olmak zorunda. `android/key.properties`
> içindeki dosya ve şifreler kullanılacak.

## 4. App Store Connect

- `codemagic.yaml` içindeki `integrations.app_store_connect` değerini, Codemagic
  → *Teams* → *Integrations* → *App Store Connect* altında **zaten ekli olan**
  API key'in adıyla değiştir.
- API key'in yetkisi **App Manager** (veya Admin) olmalı ve *Certificates,
  Identifiers & Profiles* erişimi bulunmalı — sertifika/profil build sırasında
  otomatik çekiliyor (`ios_signing.distribution_type: app_store`).
- `APP_STORE_APPLE_ID` değişkenine App Store Connect → uygulama →
  *App Information* → *Apple ID* alanındaki sayısal değeri yaz.

## 5. Codemagic'i yaml moduna al

`codemagic.yaml` repo kökünde olduğu için Codemagic onu otomatik algılar.
Uygulama sayfasında build başlatırken **workflow olarak `Yayin (Android + iOS)`**
seçilmeli. Bu andan sonra Workflow Editor ayarları devre dışı kalır.

## 6. Webhook

Repo GitHub App entegrasyonu ile bağlıysa webhook otomatik kurulur. SSH/HTTPS ile
eklendiyse Codemagic → uygulama → *Webhooks* bölümündeki URL'yi GitHub repo
ayarlarına elle eklemek gerekir. Webhook yoksa tag push'u build tetiklemez.

---

## Sürüm çıkarma akışı

1. `pubspec.yaml` içindeki `version:` satırında **sadece sürüm adını** güncelle
   (örn. `3.5.0+36` → `3.6.0+36`). Build numarası artık önemsiz; Codemagic her
   iki mağazadaki en yüksek değeri okuyup +1 veriyor.
2. `release_notes.txt` dosyasına bu sürümün notlarını yaz.
   > Apple `<` ve `>` karakterlerini kabul etmiyor.
3. Commit + push.
4. Tag at:
   ```bash
   git tag v3.6.0 && git push origin v3.6.0
   ```
5. Codemagic: test → AAB + IPA → Play production (inceleme) + App Store
   (inceleme, onay sonrası otomatik yayın). Sonuç e-posta ile gelir.

---

## İlk çalıştırmada kontrol edilecekler

- **Release notes dili:** Düz `release_notes.txt`, Google Play'e `en-US` olarak
  gönderiliyor. Play mağaza kaydında `en-US` yerelleştirmesi yoksa hata verir;
  bu durumda dosyayı `release_notes_tr-TR.txt` yap ya da `release_notes.json`
  ile çok dilli tanımla.
- **Android versionCode:** Build log'unda "Android: 3.6.0+37" satırının doğru
  olduğunu doğrula.
- **Flutter sürümü:** `flutter: stable` kullanılıyor. Flutter'ın yeni bir
  sürümünün build'i bozma ihtimaline karşı, ilk başarılı build'in log'undaki
  sürümü `codemagic.yaml`'a sabitlemek (`flutter: 3.x.y`) daha güvenli.
- **İlk deneme:** Riski azaltmak için ilk tag'de `GOOGLE_PLAY_TRACK` değerini
  `internal` yapıp, App Store tarafında `submit_to_app_store: false` ile
  deneyip, her şey yolundaysa `production` / `true` yapmak mantıklı.

## Hâlâ elle yapılması gerekenler

- Ekran görüntüsü, açıklama, kategori, gizlilik bilgileri değişecekse mağaza
  konsolları.
- Apple/Google inceleme reddi gelirse cevaplamak.
- iOS export compliance sorusu `Info.plist` içindeki
  `ITSAppUsesNonExemptEncryption = false` sayesinde otomatik geçiliyor.
