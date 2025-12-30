# Binay Tenis Akademi - Proje Dokümantasyonu

## Proje Genel Bakış

Binay Tenis Akademi, tenis kulübü yönetimini kolaylaştıran kapsamlı bir yönetim sistemidir. Django 4.2 backend ve Flutter mobil uygulama ile geliştirilmiştir.

### Temel Özellikler
- Üye ve antrenör yönetimi
- Ders planlama ve rezervasyon sistemi
- Mali takip ve fatura yönetimi
- QR kod tabanlı tesis erişim kontrolü
- Push notification sistemi
- Çoklu profil desteği (bir kullanıcı hem üye hem antrenör olabilir)
- Etkinlik ve davet yönetimi
- Paket ve abonelik sistemi
- Telafi dersi yönetimi
- Antrenör katsayı bazlı ücretlendirme

---

## Django Backend Yapısı

### Proje Organizasyonu

```
cero/
├── settings.py          # Ana ayar dosyası
├── urls.py              # Ana URL yapılandırması
├── wsgi.py
└── asgi.py

calendarapp/             # Ana uygulama modülü
├── models.py            # Tüm veritabanı modelleri
├── views.py             # View'ler ve API endpoint'leri
├── signals.py           # Django signal işleyicileri
├── admin.py             # Django admin yapılandırması
├── urls.py              # App URL yapılandırması
├── managers.py          # Custom model manager'lar
├── middleware.py        # Custom middleware'ler
└── utils.py             # Yardımcı fonksiyonlar

api/                     # REST API modülü
├── views.py             # API view'leri
├── serializers.py       # DRF serializer'ları
└── urls.py              # API URL yapılandırması

auths/                   # Kimlik doğrulama modülü
├── views.py             # Login/logout view'leri
├── tokens.py            # Token yönetimi
└── urls.py              # Auth URL yapılandırması
```

---

## Veritabanı Modelleri

### 1. SistemKullaniciModel (Multi-Role Kullanıcı Sistemi)

**Amaç**: Tek bir kullanıcının birden fazla profile (üye, antrenör, admin) sahip olmasını sağlar.

**Önemli Alanlar**:
- `user`: Django User modeli ile OneToOne ilişki
- `uye`: UyeModel ile ForeignKey (null=True)
- `antrenor`: AntrenorModel ile ForeignKey (null=True)
- `rol`: 'UYE', 'ANTRENOR', 'ADMIN', 'PERSONEL' seçenekleri
- `varsayilan_profil`: Kullanıcının varsayılan profili

**Önemli Metodlar**:
- `get_profiles()`: Kullanıcının sahip olduğu tüm profilleri döner
- `switch_profile(profile_type, profile_id)`: Profil değiştirme

**Kullanım Senaryosu**:
```python
# Bir kullanıcı hem üye hem antrenör olabilir
sistem_kullanici = SistemKullaniciModel.objects.get(user=request.user)
profiles = sistem_kullanici.get_profiles()
# {'UYE': uye_obj, 'ANTRENOR': antrenor_obj}
```

---

### 2. UyeModel (Üye Modeli)

**Amaç**: Tenis kulübü üyelerini yönetir.

**Önemli Alanlar**:
- `ad`, `soyad`: İsim bilgileri
- `email`, `telefon`: İletişim
- `tc_no`: TC kimlik numarası
- `dogum_tarihi`: Doğum tarihi
- `cinsiyet`: 'E' veya 'K'
- `profil_resmi`: Profil fotoğrafı
- `kayit_tarihi`: Kayıt tarihi
- `durum`: 'aktif' veya 'pasif'
- `adres`: Adres bilgisi
- `tenant`: Multi-tenant desteği için

**İlişkiler**:
- `SistemKullaniciModel` ile ters ilişki
- `EtkinlikModel` ile ManyToMany (etkinlik katılımcıları)
- `SabitPlanModel` ile ters ilişki (üyenin sabit planları)

**Manager**:
- `TenantManager`: Multi-tenant filtreleme için custom manager

---

### 3. AntrenorModel (Antrenör Modeli)

**Amaç**: Tenis antrenörlerini yönetir.

**Önemli Alanlar**:
- `ad`, `soyad`: İsim bilgileri
- `email`, `telefon`: İletişim
- `uzmanlik`: Uzmanlık alanı
- `deneyim_yili`: Tecrübe süresi
- `biyografi`: Antrenör hakkında bilgi
- `profil_resmi`: Profil fotoğrafı
- `musaitlik_baslangic`, `musaitlik_bitis`: Çalışma saatleri
- `katsayi`: Ders ücreti hesaplaması için katsayı (Decimal)
- `durum`: 'aktif' veya 'pasif'
- `tenant`: Multi-tenant desteği

**İlişkiler**:
- `EtkinlikModel` ile ForeignKey (etkinlik antrenörü)
- `SabitPlanModel` ile ForeignKey (plan antrenörü)

**Katsayı Sistemi**:
Antrenör katsayısı, ders ücretinin hesaplanmasında kullanılır:
```
Ders Ücreti = Baz Ücret × Antrenör Katsayısı
```

---

### 4. EtkinlikModel (Ders/Etkinlik Modeli)

**Amaç**: Tenis dersleri ve etkinlikleri yönetir.

**Önemli Alanlar**:
- `baslik`: Etkinlik başlığı
- `aciklama`: Detaylı açıklama
- `baslangic_zamani`, `bitis_zamani`: Tarih/saat
- `antrenor`: AntrenorModel ile ForeignKey
- `katilimcilar`: UyeModel ile ManyToMany
- `tur`: 'DERS', 'ETKINLIK', 'TURNUVA'
- `durum`: 'BEKLEMEDE', 'ONAYLANDI', 'REDDEDILDI', 'IPTAL', 'TAMAMLANDI'
- `kort`: Kort numarası
- `kapasite`: Maksimum katılımcı sayısı
- `ucret`: Etkinlik ücreti
- `tekrar_turu`: 'TEK_SEFERLIK', 'HAFTALIK', 'AYLIK'
- `telafi_dersi_mi`: Boolean (telafi dersi kontrolü)
- `orijinal_etkinlik`: ForeignKey to self (telafi dersi için)
- `tenant`: Multi-tenant desteği

**İş Mantığı**:
1. **24 Saat Kuralı**: Ders iptali başlangıç zamanından en az 24 saat önce yapılmalı
2. **Telafi Dersi**: İptal edilen dersler için telafi dersi oluşturulabilir
3. **Kapasite Kontrolü**: Katılımcı sayısı kapasiteyi geçemez
4. **Antrenör Müsaitlik Kontrolü**: Etkinlik antrenörün çalışma saatleri içinde olmalı

**Signals**:
- `post_save`: Etkinlik onaylandığında bildirim gönderilir
- `pre_delete`: Etkinlik silinmeden önce ilgili kayıtlar temizlenir

---

### 5. SabitPlanModel (Sabit Ders Planı)

**Amaç**: Tekrarlayan ders planlarını ve abonelikleri yönetir.

**Önemli Alanlar**:
- `uye`: UyeModel ile ForeignKey
- `antrenor`: AntrenorModel ile ForeignKey
- `urun`: UrunModel ile ForeignKey
- `gun`: 0-6 arası (Pazartesi-Pazar)
- `saat`: Time field
- `baslangic_tarihi`: Plan başlangıcı
- `bitis_tarihi`: Plan bitişi (null=True)
- `aktif`: Boolean
- `kalan_ders_hakki`: Integer (paket için)
- `otomatik_faturalama`: Boolean
- `son_faturalama_tarihi`: Date field
- `tenant`: Multi-tenant desteği

**İş Mantığı (Signals)**:

#### `post_save` Signal (yeni kayıt):
```python
# calendarapp/signals.py - sabit_plan_post_save

1. Ürün tipine göre işlem:
   
   a) PAKET:
      - kalan_ders_hakki = urun.ders_sayisi
      - Paket ücreti için ParaHareketiModel oluştur
      - Tip: 'PAKET_ODEMESI'
   
   b) ABONELIK:
      - kalan_ders_hakki = None (sınırsız)
      - İlk ay ücreti için ParaHareketiModel oluştur
      - Tip: 'ABONELIK_ODEMESI'
      - son_faturalama_tarihi = bugün
   
   c) TEK_SEFERLIK:
      - kalan_ders_hakki = 1
      - Ders ücreti için ParaHareketiModel oluştur
      - Tip: 'DERS_UCRETI'

2. Gelecek 30 gün için EtkinlikModel kayıtları oluştur
   - Sadece plan günlerine denk gelen tarihler
   - Her etkinlik: tur='DERS', durum='ONAYLANDI'
```

#### Aylık Faturalama (Heroku Scheduler):
```python
# management/commands/monthly_billing.py

Her gün çalışır:
1. ABONELIK tipli aktif planları bul
2. son_faturalama_tarihi + 30 gün >= bugün olanları seç
3. Her plan için:
   - Yeni ParaHareketiModel (ABONELIK_ODEMESI)
   - son_faturalama_tarihi güncelle
   - Gelecek 30 gün için yeni EtkinlikModel'ler oluştur
```

**Kritik Noktalar**:
- Signal içinde `created` kontrolü ile sadece yeni kayıtlarda çalışır
- `get_or_create` ile duplicate önlenir
- Mevcut etkinliklerin üzerine yazılmaz

---

### 6. UrunModel (Ürün/Paket Modeli)

**Amaç**: Satılabilir ürünleri (paketler, abonelikler, dersler) tanımlar.

**Önemli Alanlar**:
- `ad`: Ürün adı
- `aciklama`: Detaylı açıklama
- `tip`: 'PAKET', 'ABONELIK', 'TEK_SEFERLIK'
- `fiyat`: Decimal field
- `ders_sayisi`: Integer (PAKET için)
- `gecerlilik_suresi`: Integer (gün cinsinden)
- `aktif`: Boolean
- `tenant`: Multi-tenant desteği

**Fiyatlandırma Mantığı**:
- PAKET: Toplam paket fiyatı (tüm dersler için)
- ABONELIK: Aylık ücret
- TEK_SEFERLIK: Tek ders ücreti × antrenör katsayısı

---

### 7. ParaHareketiModel (Mali Hareket)

**Amaç**: Tüm finansal işlemleri kaydeder.

**Önemli Alanlar**:
- `uye`: UyeModel ile ForeignKey (null=True)
- `antrenor`: AntrenorModel ile ForeignKey (null=True)
- `tip`: 'ODEME', 'DERS_UCRETI', 'PAKET_ODEMESI', 'ABONELIK_ODEMESI', 'IADE', 'DIGER'
- `tutar`: Decimal field
- `tarih`: DateTime field
- `aciklama`: Text field
- `odeme_yontemi`: 'NAKIT', 'KREDI_KARTI', 'BANKA_TRANSFERI', 'DIGER'
- `etkinlik`: EtkinlikModel ile ForeignKey (null=True)
- `sabit_plan`: SabitPlanModel ile ForeignKey (null=True)
- `urun`: UrunModel ile ForeignKey (null=True)
- `tenant`: Multi-tenant desteği

**Kullanım Senaryoları**:
1. Paket satışı → PAKET_ODEMESI
2. Abonelik yenilemesi → ABONELIK_ODEMESI
3. Tek ders → DERS_UCRETI
4. İade işlemi → IADE

---

### 8. GecisModel (QR Kod Erişim Kontrolü)

**Amaç**: Turnike geçişlerini ve tesis erişimlerini takip eder.

**Önemli Alanlar**:
- `uye`: UyeModel ile ForeignKey
- `qr_kod`: Unique CharField
- `giris_zamani`: DateTime field
- `cikis_zamani`: DateTime field (null=True)
- `durum`: 'GIRIS', 'CIKIS'
- `tenant`: Multi-tenant desteği

**QR Kod Sistemi**:
```python
# QR kod formatı
qr_data = f"BTENIS_{uye.id}_{timestamp}"

# QR kod doğrulama
gecis = GecisModel.objects.create(
    uye=uye,
    qr_kod=qr_data,
    durum='GIRIS'
)
```

**API Endpoint**:
```
POST /api/turnstile/validate/
Body: {"qr_code": "BTENIS_123_1234567890"}
Response: {"success": true, "message": "Giriş başarılı"}
```

---

### 9. NotificationModel (Bildirim Sistemi)

**Amaç**: Push notification ve sistem bildirimlerini yönetir.

**Önemli Alanlar**:
- `kullanici`: User ile ForeignKey (null=True, blank=True)
- `uye`: UyeModel ile ForeignKey (null=True, blank=True)
- `antrenor`: AntrenorModel ile ForeignKey (null=True, blank=True)
- `tip`: Notification tipi (enum-based, config-driven'a geçiliyor)
- `baslik`: Bildirim başlığı
- `mesaj`: Bildirim içeriği
- `okundu`: Boolean
- `olusturma_zamani`: DateTime field
- `fcm_token`: Firebase Cloud Messaging token
- `action_type`: 'ETKINLIK_DETAY', 'PROFIL', 'ODEME', vs.
- `action_data`: JSON field (etkinlik_id, url, vs.)
- `action_token`: Standalone notification için güvenlik token'ı
- `tenant`: Multi-tenant desteği

**Modernizasyon (Devam Eden)**:

#### Eski Sistem (Enum-based):
```python
# Hardcoded enum değerleri
tip = models.CharField(
    choices=[
        ('DERS_ONAY', 'Ders Onayı'),
        ('DERS_IPTAL', 'Ders İptali'),
        # ... 20+ farklı tip
    ]
)
```

#### Yeni Sistem (Config-driven):
```python
# utils/notification_config.py
NOTIFICATION_TYPES = {
    'LESSON_APPROVED': {
        'title_template': '{lesson_type} Onaylandı',
        'message_template': '{lesson_date} tarihli {lesson_type} onaylandı.',
        'action_type': 'ETKINLIK_DETAY',
        'priority': 'high',
        'category': 'lesson'
    },
    # ... diğer tipler
}

# utils/notification_factory.py
class NotificationFactory:
    @staticmethod
    def create_notification(notification_type, context, recipients):
        config = NOTIFICATION_TYPES[notification_type]
        # Template rendering ve notification oluşturma
```

**Standalone Notifications**:
Kullanıcı login olmadan bildirim üzerinden aksiyon alabilir:
```python
# action_token oluşturma
token = secrets.token_urlsafe(32)
notification.action_token = token
notification.save()

# URL örneği
action_url = f"/notification/action/{notification.id}/?token={token}"

# Token doğrulama (views.py)
if notification.action_token != provided_token:
    return HttpResponse("Geçersiz token", status=403)
```

---

### 10. EtkinlikDavetModel (Etkinlik Davet Sistemi)

**Amaç**: Üyelerin etkinliklere davet edilmesini ve katılım takibini sağlar.

**Önemli Alanlar**:
- `etkinlik`: EtkinlikModel ile ForeignKey
- `uye`: UyeModel ile ForeignKey
- `durum`: 'BEKLEMEDE', 'KABUL', 'RED'
- `davet_tarihi`: DateTime field
- `cevap_tarihi`: DateTime field (null=True)
- `not`: Text field (isteğe bağlı)
- `tenant`: Multi-tenant desteği

**İş Akışı**:
1. Admin/Antrenör etkinlik için davet gönderir
2. Üye notification alır
3. Üye kabul/red cevabı verir
4. KABUL → üye etkinliğin katılımcılarına eklenir

---

## Django Views ve API Endpoints

### URL Organizasyonu

```python
# cero/urls.py
urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('calendarapp.urls')),  # Ana view'ler
    path('api/', include('api.urls')),      # REST API
    path('auth/', include('auths.urls')),   # Authentication
]
```

### Ana View'ler (calendarapp/urls.py)

#### Üye View'leri (`/member/...`)
- `/member/list/` - Üye listesi
- `/member/create/` - Yeni üye oluştur
- `/member/edit/<id>/` - Üye düzenle
- `/member/delete/<id>/` - Üye sil
- `/member/detail/<id>/` - Üye detayı
- `/member/packages/<id>/` - Üye paketleri
- `/member/lessons/<id>/` - Üye dersleri
- `/member/payments/<id>/` - Üye ödemeleri

#### Antrenör View'leri (`/trainer/...`)
- `/trainer/list/` - Antrenör listesi
- `/trainer/create/` - Yeni antrenör oluştur
- `/trainer/edit/<id>/` - Antrenör düzenle
- `/trainer/delete/<id>/` - Antrenör sil
- `/trainer/detail/<id>/` - Antrenör detayı
- `/trainer/schedule/<id>/` - Antrenör programı

#### Etkinlik View'leri (`/event/...`)
- `/event/list/` - Etkinlik listesi
- `/event/create/` - Yeni etkinlik oluştur
- `/event/edit/<id>/` - Etkinlik düzenle
- `/event/delete/<id>/` - Etkinlik sil
- `/event/approve/<id>/` - Etkinlik onayla
- `/event/cancel/<id>/` - Etkinlik iptal et
- `/event/makeup/<id>/` - Telafi dersi oluştur

#### Bildirim View'leri (`/notification/...`)
- `/notification/list/` - Bildirim listesi
- `/notification/mark-read/<id>/` - Bildirimi okundu işaretle
- `/notification/action/<id>/` - Standalone notification action

---

### REST API Endpoints (api/urls.py)

#### Authentication
```
POST /api/auth/login/
POST /api/auth/logout/
POST /api/auth/register/
POST /api/auth/token/refresh/
POST /api/auth/profile/switch/
```

#### Member Endpoints
```
GET    /api/member/list/
GET    /api/member/<id>/
POST   /api/member/create/
PUT    /api/member/<id>/update/
DELETE /api/member/<id>/delete/
GET    /api/member/<id>/lessons/
GET    /api/member/<id>/packages/
GET    /api/member/<id>/payments/
POST   /api/member/<id>/qr-code/
```

#### Trainer Endpoints
```
GET    /api/trainer/list/
GET    /api/trainer/<id>/
POST   /api/trainer/create/
PUT    /api/trainer/<id>/update/
GET    /api/trainer/<id>/schedule/
GET    /api/trainer/<id>/earnings/
```

#### Event/Lesson Endpoints
```
GET    /api/event/list/
GET    /api/event/<id>/
POST   /api/event/create/
PUT    /api/event/<id>/update/
DELETE /api/event/<id>/delete/
POST   /api/event/<id>/approve/
POST   /api/event/<id>/cancel/
POST   /api/event/<id>/makeup/
GET    /api/event/calendar/
```

#### Notification Endpoints
```
GET    /api/notification/list/
POST   /api/notification/mark-read/<id>/
POST   /api/notification/mark-all-read/
DELETE /api/notification/delete/<id>/
POST   /api/notification/fcm-token/register/
POST   /api/notification/fcm-token/unregister/
```

#### Turnstile (QR) Endpoints
```
POST   /api/turnstile/validate/
GET    /api/turnstile/history/<uye_id>/
```

#### Product/Package Endpoints
```
GET    /api/product/list/
GET    /api/product/<id>/
POST   /api/product/create/
POST   /api/product/purchase/
```

---

## Django Signals (calendarapp/signals.py)

### 1. sabit_plan_post_save
**Tetiklenir**: SabitPlanModel kaydı oluşturulduğunda
**Görevler**:
- Ürün tipine göre mali hareket oluşturma
- Kalan ders hakkı ayarlama
- Gelecek 30 gün için etkinlik oluşturma

```python
@receiver(post_save, sender=SabitPlanModel)
def sabit_plan_post_save(sender, instance, created, **kwargs):
    if created:
        # Ürün tipine göre işlem
        if instance.urun.tip == 'PAKET':
            # Paket ödemesi kaydet
            ParaHareketiModel.objects.create(...)
            instance.kalan_ders_hakki = instance.urun.ders_sayisi
        
        elif instance.urun.tip == 'ABONELIK':
            # Abonelik ödemesi kaydet
            ParaHareketiModel.objects.create(...)
            instance.son_faturalama_tarihi = timezone.now().date()
        
        # Gelecek etkinlikleri oluştur
        create_future_events(instance)
```

### 2. etkinlik_post_save
**Tetiklenir**: EtkinlikModel durumu değiştiğinde
**Görevler**:
- Durum değişikliği bildirimleri
- Katılımcılara bilgilendirme

```python
@receiver(post_save, sender=EtkinlikModel)
def etkinlik_post_save(sender, instance, **kwargs):
    if instance.durum == 'ONAYLANDI':
        # Katılımcılara bildirim gönder
        for katilimci in instance.katilimcilar.all():
            NotificationModel.objects.create(...)
```

### 3. etkinlik_davet_post_save
**Tetiklenir**: EtkinlikDavetModel durumu değiştiğinde
**Görevler**:
- Davet kabul edildiğinde üyeyi etkinliğe ekle
- Bildirim gönder

---

## Middleware (calendarapp/middleware.py)

### 1. RequestLoggingMiddleware
**Amaç**: Tüm HTTP isteklerini loglar (bot istekleri hariç)

```python
class RequestLoggingMiddleware:
    def __call__(self, request):
        # Bot isteklerini filtrele
        user_agent = request.META.get('HTTP_USER_AGENT', '')
        if any(bot in user_agent.lower() for bot in ['bot', 'crawler', 'spider']):
            return self.get_response(request)
        
        # İsteği logla
        logger.info(f"{request.method} {request.path}")
```

### 2. TenantMiddleware
**Amaç**: Multi-tenant filtreleme için tenant bilgisini ayarlar

---

## Management Commands

### 1. monthly_billing.py
**Çalışma**: Günlük (Heroku Scheduler ile)
**Görev**: Abonelik planlarını faturalandırma

```bash
# Heroku Scheduler
python manage.py monthly_billing
```

```python
def handle(self):
    # 30 gün dolmuş abonelik planlarını bul
    plans = SabitPlanModel.objects.filter(
        urun__tip='ABONELIK',
        aktif=True,
        son_faturalama_tarihi__lte=today - timedelta(days=30)
    )
    
    for plan in plans:
        # Ödeme kaydı oluştur
        ParaHareketiModel.objects.create(...)
        
        # Son faturalama tarihini güncelle
        plan.son_faturalama_tarihi = today
        plan.save()
        
        # Gelecek etkinlikleri oluştur
        create_future_events(plan)
```

### 2. cleanup_old_events.py
**Çalışma**: Haftalık
**Görev**: Eski etkinlik kayıtlarını temizleme

---

## Django Admin Yapılandırması (admin.py)

### Özelleştirilmiş Admin Sınıfları:

```python
@admin.register(UyeModel)
class UyeAdmin(admin.ModelAdmin):
    list_display = ['ad', 'soyad', 'email', 'telefon', 'durum']
    list_filter = ['durum', 'cinsiyet', 'kayit_tarihi']
    search_fields = ['ad', 'soyad', 'email', 'tc_no']
    readonly_fields = ['kayit_tarihi']
    
    # Custom actions
    actions = ['activate_members', 'deactivate_members']

@admin.register(EtkinlikModel)
class EtkinlikAdmin(admin.ModelAdmin):
    list_display = ['baslik', 'antrenor', 'baslangic_zamani', 'durum']
    list_filter = ['durum', 'tur', 'baslangic_zamani']
    search_fields = ['baslik', 'antrenor__ad']
    
    # Inline katılımcı yönetimi
    filter_horizontal = ['katilimcilar']
```

### İndeks Optimizasyonları:
Veritabanı performansı için gerçek kod kullanımına dayalı indeksler:

```python
class Meta:
    indexes = [
        models.Index(fields=['tenant', 'durum']),
        models.Index(fields=['baslangic_zamani', 'bitis_zamani']),
        models.Index(fields=['antrenor', 'baslangic_zamani']),
    ]
```

---

## Timezone Yönetimi

**Sorun**: Flutter frontend ve Django backend arasında timezone farkı
**Çözüm**: Backend'de timezone dönüşümü

```python
# Django settings.py
USE_TZ = True
TIME_ZONE = 'Europe/Istanbul'

# views.py - tarih/saat işlemleri
from django.utils import timezone

# Aware datetime kullanımı
now = timezone.now()
local_time = timezone.localtime(now)

# API response'larda ISO format
date_str = event.baslangic_zamani.isoformat()
```

**Flutter Tarafı**:
```dart
// Backend'den gelen tarihler zaten doğru timezone'da
DateTime eventDate = DateTime.parse(jsonData['baslangic_zamani']);
```

---

## Firebase Cloud Messaging (FCM) Entegrasyonu

### Backend Yapılandırması:

```python
# settings.py
FIREBASE_CREDENTIALS = json.loads(os.environ.get('FIREBASE_CREDENTIALS', '{}'))

# Güvenlik uyarısı: Asla credentials'ı kod içine yazmayın!
# Ortam değişkenleri kullanın
```

### FCM Token Yönetimi:

```python
# models.py
class FCMDeviceToken(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    token = models.CharField(max_length=255, unique=True)
    device_type = models.CharField(max_length=50)  # 'android', 'ios'
    is_active = models.BooleanField(default=True)
    last_used = models.DateTimeField(auto_now=True)
```

### Push Notification Gönderimi:

```python
from firebase_admin import messaging

def send_push_notification(fcm_token, title, body, data=None):
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data=data or {},
        token=fcm_token,
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                sound='default',
                click_action='FLUTTER_NOTIFICATION_CLICK',
            ),
        ),
    )
    
    try:
        response = messaging.send(message)
        return True
    except Exception as e:
        logger.error(f"FCM error: {e}")
        return False
```

### Planlanan İyileştirme:
"Last login device only" yaklaşımı - kullanıcının son login olduğu cihaza push gönder

---

## Güvenlik ve Authentication

### Token-based Authentication:

```python
# settings.py
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}
```

### Standalone Notification Actions:

```python
# Güvenlik token'ı ile login gerektirmeden işlem
import secrets

notification.action_token = secrets.token_urlsafe(32)
notification.save()

# View'de doğrulama
def notification_action_view(request, notification_id):
    token = request.GET.get('token')
    notification = NotificationModel.objects.get(id=notification_id)
    
    if notification.action_token != token:
        return HttpResponse("Unauthorized", status=403)
    
    # İşlemi gerçekleştir
```

---

## Veritabanı Optimizasyonları

### N+1 Problem Çözümü:

```python
# ❌ Kötü: N+1 query problemi
events = EtkinlikModel.objects.all()
for event in events:
    print(event.antrenor.ad)  # Her iteration'da yeni query

# ✅ İyi: select_related kullanımı
events = EtkinlikModel.objects.select_related('antrenor').all()
for event in events:
    print(event.antrenor.ad)  # Tek query

# ✅ ManyToMany için prefetch_related
events = EtkinlikModel.objects.prefetch_related('katilimcilar').all()
```

### TenantManager:

```python
class TenantManager(models.Manager):
    def get_queryset(self):
        # Multi-tenant filtreleme
        tenant = get_current_tenant()
        return super().get_queryset().filter(tenant=tenant)
```

---

## Error Handling ve Logging

### Logging Yapılandırması:

```python
# settings.py
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': 'debug.log',
            'formatter': 'verbose',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': False,
        },
        'calendarapp': {
            'handlers': ['file', 'console'],
            'level': 'DEBUG',
            'propagate': False,
        },
    },
}
```

---

# Flutter Mobil Uygulama

## Proje Yapısı

```
lib/
├── main.dart                    # Ana giriş noktası
├── screens/                     # UI ekranları
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   ├── calendar_screen.dart    # Modernize edildi (table_calendar)
│   ├── lesson_list_screen.dart
│   ├── lesson_detail_screen.dart
│   ├── notification_screen.dart
│   ├── package_list_screen.dart
│   ├── qr_code_screen.dart
│   └── ... (diğer ekranlar)
├── services/                    # API ve servisler
│   ├── api_service.dart        # REST API client
│   ├── auth_service.dart       # Authentication
│   ├── notification_service.dart # FCM entegrasyonu
│   └── storage_service.dart    # Local storage
├── models/                      # Dart data modelleri
│   ├── user_model.dart
│   ├── member_model.dart
│   ├── trainer_model.dart
│   ├── event_model.dart
│   ├── notification_model.dart
│   └── ... (diğer modeller)
├── widgets/                     # Reusable widget'lar
│   ├── custom_app_bar.dart
│   ├── custom_button.dart
│   ├── event_card.dart
│   └── ... (diğer widget'lar)
├── utils/                       # Yardımcı fonksiyonlar
│   ├── constants.dart
│   ├── date_utils.dart
│   └── theme.dart
└── providers/                   # State management (opsiyonel)
    └── user_provider.dart
```

---

## Ana Dosya (main.dart)

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase başlatma
  await Firebase.initializeApp();
  
  // FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message: ${message.messageId}");
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Binay Tenis Akademi',
      theme: AppTheme.lightTheme,
      home: SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/calendar': (context) => CalendarScreen(),
        // ... diğer route'lar
      },
    );
  }
}
```

---

## API Service (services/api_service.dart)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = 'https://your-backend.herokuapp.com';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // HTTP client
  final http.Client _client = http.Client();
  
  // Authorization header
  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };
  }
  
  // GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Response handler
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 401) {
      // Token expired - redirect to login
      throw Exception('Unauthorized');
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }
  
  // Specific API calls
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await post('/api/auth/login/', {
      'email': email,
      'password': password,
    });
  }
  
  Future<List<dynamic>> getEvents() async {
    return await get('/api/event/list/');
  }
  
  Future<Map<String, dynamic>> getEventDetail(int eventId) async {
    return await get('/api/event/$eventId/');
  }
  
  Future<void> cancelEvent(int eventId) async {
    return await post('/api/event/$eventId/cancel/', {});
  }
  
  Future<List<dynamic>> getNotifications() async {
    return await get('/api/notification/list/');
  }
  
  Future<void> markNotificationRead(int notificationId) async {
    return await post('/api/notification/mark-read/$notificationId/', {});
  }
  
  Future<Map<String, dynamic>> getMemberProfile() async {
    return await get('/api/member/profile/');
  }
  
  Future<String> getQRCode() async {
    final response = await get('/api/member/qr-code/');
    return response['qr_code'];
  }
}
```

---

## Authentication Service (services/auth_service.dart)

```dart
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  
  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      
      // Token'ı kaydet
      await StorageService.saveToken(response['token']);
      
      // User bilgilerini kaydet
      await StorageService.saveUserData(response['user']);
      
      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
  
  Future<void> logout() async {
    await StorageService.clearAll();
  }
  
  Future<bool> isLoggedIn() async {
    final token = await StorageService.getToken();
    return token != null && token.isNotEmpty;
  }
  
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await StorageService.getUserData();
  }
  
  Future<void> switchProfile(String profileType, int profileId) async {
    await _apiService.post('/api/auth/profile/switch/', {
      'profile_type': profileType,
      'profile_id': profileId,
    });
    
    // Update local user data
    final userData = await StorageService.getUserData();
    userData['current_profile'] = {
      'type': profileType,
      'id': profileId,
    };
    await StorageService.saveUserData(userData);
  }
}
```

---

## Storage Service (services/storage_service.dart)

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _fcmTokenKey = 'fcm_token';
  
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, json.encode(userData));
  }
  
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString == null) return null;
    return json.decode(userDataString);
  }
  
  static Future<void> saveFCMToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }
  
  static Future<String?> getFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }
  
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
```

---

## Notification Service (services/notification_service.dart)

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'storage_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();
  
  Future<void> initialize() async {
    // Request permission (iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Get FCM token
    String? token = await _fcm.getToken();
    if (token != null) {
      await StorageService.saveFCMToken(token);
      await _registerTokenWithBackend(token);
    }
    
    // Token refresh listener
    _fcm.onTokenRefresh.listen((newToken) async {
      await StorageService.saveFCMToken(newToken);
      await _registerTokenWithBackend(newToken);
    });
    
    // Initialize local notifications
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Background message handler (opened app)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }
  
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      await _apiService.post('/api/notification/fcm-token/register/', {
        'token': token,
        'device_type': 'android', // or 'ios'
      });
    } catch (e) {
      print('FCM token registration error: $e');
    }
  }
  
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification when app is in foreground
    await _showLocalNotification(
      message.notification?.title ?? 'Bildirim',
      message.notification?.body ?? '',
      message.data,
    );
  }
  
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: json.encode(data),
    );
  }
  
  void _handleNotificationTap(RemoteMessage message) {
    _onNotificationTap(NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      payload: json.encode(message.data),
    ));
  }
  
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    
    final data = json.decode(response.payload!);
    final actionType = data['action_type'];
    
    // Navigate based on action type
    switch (actionType) {
      case 'ETKINLIK_DETAY':
        final eventId = data['event_id'];
        // Navigate to event detail
        navigatorKey.currentState?.pushNamed(
          '/event-detail',
          arguments: {'event_id': eventId},
        );
        break;
      case 'PROFIL':
        navigatorKey.currentState?.pushNamed('/profile');
        break;
      // ... other action types
    }
  }
}
```

---

## Calendar Screen (screens/calendar_screen.dart)

**Modern Versiyon** - table_calendar kullanarak yeniden yazıldı

```dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/event_model.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService _apiService = ApiService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  Map<DateTime, List<EventModel>> _events = {};
  List<EventModel> _selectedEvents = [];
  
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }
  
  Future<void> _loadEvents() async {
    try {
      final response = await _apiService.get('/api/event/calendar/');
      final events = (response as List)
          .map((e) => EventModel.fromJson(e))
          .toList();
      
      // Group events by date
      Map<DateTime, List<EventModel>> eventMap = {};
      for (var event in events) {
        final date = DateTime(
          event.startTime.year,
          event.startTime.month,
          event.startTime.day,
        );
        
        if (eventMap[date] == null) {
          eventMap[date] = [];
        }
        eventMap[date]!.add(event);
      }
      
      setState(() {
        _events = eventMap;
        _selectedEvents = _getEventsForDay(_selectedDay!);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoading = false);
    }
  }
  
  List<EventModel> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _buildCalendarContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 8),
          Text(
            'Takvim',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadEvents,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCalendarContent() {
    return Column(
      children: [
        TableCalendar<EventModel>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay,
          
          // Styling
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Color(0xFF1A237E),
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            outsideDaysVisible: false,
          ),
          
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Callbacks
          onDaySelected: (selectedDay, focusedDay) {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _selectedEvents = _getEventsForDay(selectedDay);
            });
          },
          
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        
        Divider(height: 1),
        
        // Selected day events
        Expanded(
          child: _selectedEvents.isEmpty
              ? Center(
                  child: Text(
                    'Bu gün için ders bulunmamaktadır',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _selectedEvents.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(_selectedEvents[index]);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildEventCard(EventModel event) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(
          context,
          '/event-detail',
          arguments: {'event_id': event.id},
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Time
            Container(
              width: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(event.startTime),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  Text(
                    _formatTime(event.endTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider
            Container(
              width: 2,
              height: 40,
              color: Colors.grey.shade300,
              margin: EdgeInsets.symmetric(horizontal: 12),
            ),
            
            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Antrenör: ${event.trainerName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    'Kort: ${event.court}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            // Status badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(event.status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getStatusText(event.status),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'ONAYLANDI':
        return Colors.green;
      case 'BEKLEMEDE':
        return Colors.orange;
      case 'IPTAL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'ONAYLANDI':
        return 'Onaylandı';
      case 'BEKLEMEDE':
        return 'Bekliyor';
      case 'IPTAL':
        return 'İptal';
      default:
        return status;
    }
  }
}
```

---

## Event Model (models/event_model.dart)

```dart
class EventModel {
  final int id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String trainerName;
  final int trainerId;
  final String court;
  final String type;
  final String status;
  final List<int> participantIds;
  final bool isMakeup;
  
  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.trainerName,
    required this.trainerId,
    required this.court,
    required this.type,
    required this.status,
    required this.participantIds,
    required this.isMakeup,
  });
  
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['baslik'],
      description: json['aciklama'] ?? '',
      startTime: DateTime.parse(json['baslangic_zamani']),
      endTime: DateTime.parse(json['bitis_zamani']),
      trainerName: json['antrenor_ad'] ?? '',
      trainerId: json['antrenor'],
      court: json['kort'] ?? '',
      type: json['tur'],
      status: json['durum'],
      participantIds: List<int>.from(json['katilimcilar'] ?? []),
      isMakeup: json['telafi_dersi_mi'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baslik': title,
      'aciklama': description,
      'baslangic_zamani': startTime.toIso8601String(),
      'bitis_zamani': endTime.toIso8601String(),
      'antrenor': trainerId,
      'kort': court,
      'tur': type,
      'durum': status,
      'katilimcilar': participantIds,
      'telafi_dersi_mi': isMakeup,
    };
  }
  
  bool canCancel() {
    // 24 saat kuralı kontrolü
    final now = DateTime.now();
    final difference = startTime.difference(now);
    return difference.inHours >= 24;
  }
}
```

---

## QR Code Screen (screens/qr_code_screen.dart)

```dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';

class QRCodeScreen extends StatefulWidget {
  @override
  _QRCodeScreenState createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  final ApiService _apiService = ApiService();
  String? _qrCode;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadQRCode();
  }
  
  Future<void> _loadQRCode() async {
    try {
      final response = await _apiService.get('/api/member/qr-code/');
      setState(() {
        _qrCode = response['qr_code'];
        _isLoading = false;
      });
    } catch (e) {
      print('QR code error: $e');
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Giriş QR Kodu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Center(
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Container(
                          margin: EdgeInsets.all(32),
                          padding: EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Turnike Geçişi',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Tesis girişinde bu kodu okutunuz',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 32),
                              
                              // QR Code
                              if (_qrCode != null)
                                QrImageView(
                                  data: _qrCode!,
                                  version: QrVersions.auto,
                                  size: 250,
                                  backgroundColor: Colors.white,
                                ),
                              
                              SizedBox(height: 32),
                              
                              // Refresh button
                              ElevatedButton.icon(
                                onPressed: _loadQRCode,
                                icon: Icon(Icons.refresh),
                                label: Text('Yenile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF1A237E),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## UI Theme (utils/theme.dart)

**Material Design 3 İlkeleri**

```dart
import 'package:flutter/material.dart';

class AppTheme {
  // Ana renkler
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color secondaryColor = Color(0xFF0D47A1);
  static const Color accentColor = Color(0xFF00B0FF);
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      
      // Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Text theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
    );
  }
}
```

**Tasarım Prensipleri**:
- Gradient arka planlar (aşırı renkli değil)
- Yuvarlak köşeler (12-20px border radius)
- Hafif gölgeler (subtle shadows)
- Material Design 3 standartları
- Profesyonel ve temiz estetik
- Haptic feedback önemli aksiyonlarda

---

## Deployment ve Konfigürasyon

### Android (android/app/build.gradle)

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.binay.tenis"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.0.0'
    // ... other dependencies
}
```

**Google Play 16KB Page Size Requirement** (Kasım 2025 sonrası zorunlu):
```gradle
android {
    defaultConfig {
        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a'
        }
    }
}
```

### Firebase Configuration

**android/app/google-services.json** - Firebase console'dan indirilir
**ios/Runner/GoogleService-Info.plist** - Firebase console'dan indirilir

**UYARI**: Bu dosyaları asla git'e commit etmeyin!

---

## Önemli Paketler (pubspec.yaml)

```yaml
name: binay_tenis
description: Binay Tenis Akademi Mobil Uygulaması

dependencies:
  flutter:
    sdk: flutter
  
  # UI & Design
  cupertino_icons: ^1.0.2
  
  # State Management
  provider: ^6.0.0
  
  # Network
  http: ^1.1.0
  
  # Local Storage
  shared_preferences: ^2.2.0
  
  # Firebase
  firebase_core: ^2.15.0
  firebase_messaging: ^14.6.5
  
  # Notifications
  flutter_local_notifications: ^15.1.0
  
  # Calendar
  table_calendar: ^3.0.9
  
  # QR Code
  qr_flutter: ^4.1.0
  qr_code_scanner: ^1.0.1
  
  # Image
  cached_network_image: ^3.2.3
  image_picker: ^1.0.0
  
  # Utilities
  intl: ^0.18.0
  url_launcher: ^6.1.12
```

---

## Geliştirme Workflow'u

### 1. Backend Değişiklikleri için:
```bash
# Local development
python manage.py runserver

# Migrate database
python manage.py makemigrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Heroku deploy
git push heroku main
heroku run python manage.py migrate
```

### 2. Flutter Değişiklikleri için:
```bash
# Development
flutter run

# Build APK (release)
flutter build apk --release

# Build for iOS
flutter build ios --release

# Clean build
flutter clean
flutter pub get
flutter run
```

### 3. Test:
```bash
# Django tests
python manage.py test

# Flutter tests
flutter test
```

---

## İzleme ve Loglama

### Django Logging:
```python
import logging
logger = logging.getLogger(__name__)

logger.info('User logged in')
logger.error('Error occurred', exc_info=True)
```

### Heroku Logs:
```bash
heroku logs --tail
heroku logs --source app --tail
```

### Flutter Debugging:
```dart
print('Debug message');
debugPrint('Debug message');

// Firebase Crashlytics (opsiyonel)
FirebaseCrashlytics.instance.recordError(error, stackTrace);
```

---

## Bilinen Sorunlar ve Çözümler

### 1. Timezone Sorunu
**Sorun**: Flutter ve Django arasında saat farkı
**Çözüm**: Backend'de timezone dönüşümü yapılır, Flutter'da doğrudan kullanılır

### 2. FCM Token Yönetimi
**Sorun**: Her cihazda farklı token
**Planlanan**: "Last login device only" yaklaşımı

### 3. N+1 Query Problemi
**Çözüm**: select_related ve prefetch_related kullanımı

### 4. Duplicate Notification
**Sorun**: Signal'lar birden fazla tetiklenebilir
**Çözüm**: created kontrolü ve get_or_create kullanımı

### 5. Firebase Credentials Güvenliği
**Çözüm**: Environment variables kullanımı, asla kod içine yazılmaz

---

## Gelecek Geliştirmeler

### Kısa Vadeli:
- [ ] Notification system modernizasyonu tamamlanması
- [ ] Google Play 16KB requirement uyumu
- [ ] UI modernizasyonu - kalan ekranlar
- [ ] FCM "last device only" implementasyonu

### Orta Vadeli:
- [ ] Offline mode desteği
- [ ] Dark mode
- [ ] Çoklu dil desteği
- [ ] Advanced analytics

### Uzun Vadeli:
- [ ] Mobil ödeme entegrasyonu
- [ ] Video ders platformu
- [ ] AI-powered antrenör önerileri
- [ ] Sosyal özellikler (chat, paylaşım)

---

## Önemli Notlar

### Kodlama Standartları:
- Descriptive method/variable names
- Minimal logging (sadece gerekli yerlerde)
- Mevcut proje pattern'larını takip et
- Yeni convention'lar ekleme
- Her değişiklikte backward compatibility

### Debug Yaklaşımı:
- Step-by-step verification
- Her aşamada test
- Comprehensive error handling
- Systematic problem isolation

### URL Organization:
- `/member/...` - Üye işlemleri
- `/trainer/...` - Antrenör işlemleri
- `/notification/...` - Bildirim işlemleri
- `/api/...` - REST API endpoints

### Git Workflow:
- Feature branch'ler kullan
- Descriptive commit messages
- Pull request before merge
- Code review

---

## İletişim ve Destek

**Proje Sahibi**: Cero
**Backend**: Django 4.2 + PostgreSQL
**Frontend**: Flutter (latest stable)
**Hosting**: Heroku
**Version Control**: GitHub

---

## Lisans ve Kullanım

Bu proje Binay Tenis Akademi için özel olarak geliştirilmiştir. Tüm hakları saklıdır.

---

**Son Güncelleme**: 2025-01-02
**Dokümantasyon Versiyonu**: 1.0
