// lib/screens/1_common/ogrenme/gorevler_genel.dart
//
// Rollerle ortak sayfaların rehberleri (QR Oluştur, Bildirimler, Ayarlar). Rol
// bağımlı rehberde `roller` verilir. Yazım kuralları gorevler.dart'ta.

import 'package:fitcall/common/constants.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';

const List<OgrenmeGorevi> genelGorevler = [
  // ------------------------------------------------------------- QR Oluştur
  OgrenmeGorevi(
    id: 'qr.misafirDavet',
    sayfa: OgrenmeSayfasi.qrOlustur,
    baslik: 'Misafirimi nasıl davet ederim?',
    kosulMetni: 'QR ekranı açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Misafir Davet Et'),
        metin: '«Misafir Davet Et»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.qrMisafirAdi),
        metin: 'Misafirinin adını yaz.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.qrSure),
        metin: 'Kodun geçerli olacağı süreyi seç.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('QR Oluştur'),
        metin: '«QR Oluştur»a dokun.',
        kalici: true,
        sonuc: 'misafirine giriş kodu oluşur',
      ),
    ],
    kural: 'İlk seçili süre 5 dakikadır; misafirin sonra gelecekse uzununu '
        'seç. Oluşunca paylaşım penceresi açılır, kodu «Paylaş» ile '
        'gönderirsin. Sildiğin kod kapıda çalışmaz.',
  ),
  OgrenmeGorevi(
    id: 'qr.kisisel',
    sayfa: OgrenmeSayfasi.qrOlustur,
    baslik: 'Tesise QR ile nasıl girerim?',
    kosulMetni: 'Kişisel kodun olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.genelQrKisisel),
        metin: 'Kapıdaki okuyucuya bu kodu göster.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.genelQrYenile),
        metin: 'Süre dolunca yenile düğmesine dokun.',
        kalici: true,
        sonuc: 'kodun yeniden yüklenir',
      ),
    ],
    kural: 'Kodun kalan süresi altında yazar. '
        'Ekran parlaklığı kod açıkken kendiliğinden artar. '
        'Misafirler için «Misafir Davet Et» kullan.',
  ),
  OgrenmeGorevi(
    id: 'qr.davetSil',
    sayfa: OgrenmeSayfasi.qrOlustur,
    baslik: 'Misafir davetimi nasıl silerim?',
    kosulMetni: 'Aktif davetin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.genelQrDavetSil),
        metin: 'Misafirin satırında çöp kutusuna dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Sil'),
        metin: 'Onay penceresinde «Sil»e dokun.',
        kalici: true,
        sonuc: 'kod iptal olur, kapıda çalışmaz',
      ),
    ],
    kural: 'Süresi dolan kodlar kendiliğinden geçersiz olur. '
        'Silinen kod kapıda çalışmaz. '
        '«Paylaş» ikonu kodu yeniden gönderir.',
  ),

  // ------------------------------------------------------------ Bildirimler
  OgrenmeGorevi(
    id: 'bildirim.sil',
    sayfa: OgrenmeSayfasi.bildirimler,
    baslik: 'Bildirimi nasıl silerim?',
    kosulMetni: 'Bildirimin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.genelBildirimSatiri),
        metin: 'Satırı sola kaydırırsan silinir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.genelBildirimMenu),
        metin: 'Sağ üstteki ⋮ düğmesine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Tümünü sil'),
        metin: 'Hepsini silmek için «Tümünü sil»e dokun.',
        kalici: true,
        sonuc: 'onay sorulur, bildirimlerin hepsi silinir',
      ),
    ],
    kural: 'Tek bildirimi sildikten sonra 4 saniye geri alabilirsin. '
        'Tümünü silme geri alınamaz.',
  ),
  OgrenmeGorevi(
    id: 'bildirim.okundu',
    sayfa: OgrenmeSayfasi.bildirimler,
    baslik: 'Hepsini okundu nasıl yaparım?',
    kosulMetni: 'Okunmamış bildirimin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.genelBildirimMenu),
        metin: 'Sağ üstteki ⋮ düğmesine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Tümünü okundu yap'),
        metin: '«Tümünü okundu yap»a dokun.',
        kalici: true,
        sonuc: 'okunmamış sayısı sıfırlanır',
      ),
    ],
    kural: 'Bir bildirime dokununca da tek tek okundu olur.',
  ),

  // ---------------------------------------------------------------- Ayarlar
  OgrenmeGorevi(
    id: 'ayar.bildirimIzni',
    sayfa: OgrenmeSayfasi.ayarlar,
    baslik: 'Bildirimler gelmiyor, ne yapmalıyım?',
    kosulMetni: 'Ayarlar açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Bildirim izni'),
        metin: 'Burada izin açık mı kapalı mı yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Bildirim izni'),
        metin: 'Kapalıysa satıra dokunup izni aç.',
        bilgi: true,
      ),
    ],
    kural: 'İzni açınca Bildirimler sayfasını bir kez aç. '
        'Kapalıyken ders hatırlatması ve duyuru gelmez.',
  ),
  OgrenmeGorevi(
    id: 'ayar.tema',
    sayfa: OgrenmeSayfasi.ayarlar,
    baslik: 'Koyu temayı nasıl açarım?',
    kosulMetni: 'Ayarlar açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.genelAyarTema),
        metin: 'Renk teması ve koyu mod burada.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Koyu'),
        metin: 'Koyu mod için «Koyu»yu seç.',
        kalici: true,
        sonuc: 'uygulama koyu temaya geçer',
      ),
    ],
    kural: '«Sistem» seçiliyken telefonun ayarına uyar. '
        'Seçimin bu telefondaki bütün profillere uygulanır.',
  ),
  OgrenmeGorevi(
    id: 'ayar.sifre',
    sayfa: OgrenmeSayfasi.ayarlar,
    baslik: 'Şifremi nasıl değiştiririm?',
    kosulMetni: 'Ayarlar açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Şifreyi değiştir'),
        metin: '«Şifreyi değiştir» satırına dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.genelSifreAlanlari),
        metin: 'Mevcut ve yeni şifreni yaz.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Şifreyi Değiştir'),
        metin: '«Şifreyi Değiştir»e dokun.',
        kalici: true,
        sonuc: 'şifren değişir',
      ),
    ],
    kural: 'En az 8 karakter, harf ve rakam içermeli. '
        'Şifreni unuttuysan çıkış yapıp «Şifremi unuttum»u kullan.',
  ),
  OgrenmeGorevi(
    id: 'ayar.profilDegistir',
    sayfa: OgrenmeSayfasi.ayarlar,
    baslik: 'Başka profile nasıl geçerim?',
    kosulMetni: 'Birden çok profilin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Profil değiştir'),
        metin: '«Profil değiştir» satırına dokun.',
        kalici: true,
        sonuc: 'profil seçme ekranı açılır',
      ),
    ],
    kural: 'Çocuğunun profilini seçince onun takvimini görürsün. '
        'Bakiye ve paket ana hesapta kalır.',
  ),
  OgrenmeGorevi(
    id: 'ayar.isletmeBasvurusu',
    sayfa: OgrenmeSayfasi.ayarlar,
    baslik: 'Başka işletmeye nasıl üye olurum?',
    kosulMetni: 'Ana hesapla girince',
    roller: {Roller.uye},
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Başka işletmeye üyelik'),
        metin: '«Başka işletmeye üyelik» satırına dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.isletmeBasvuruIsletmeler),
        metin: 'Listeden başvuracağın işletmeyi seç.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.isletmeBasvuruBilgiler),
        metin: 'Aktarılacak bilgilerini kontrol et.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.isletmeBasvuruKvkk),
        metin: 'KVKK kutusunu işaretle.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Başvur'),
        metin: '«Başvur»a dokun.',
        kalici: true,
        sonuc: 'başvurun işletmenin ofisine gider',
      ),
    ],
    kural: 'Ofis onaylayınca sana haber gelir. '
        'Yeni profile «Profil değiştir» ile geçersin. '
        'Ödemeler her işletmede ayrı tutulur.',
  ),
  OgrenmeGorevi(
    id: 'ayar.cikis',
    sayfa: OgrenmeSayfasi.ayarlar,
    baslik: 'Oturumu nasıl kapatırım?',
    kosulMetni: 'Ayarlar açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Çıkış yap'),
        metin: '«Çıkış yap» satırına dokun.',
        kalici: true,
        sonuc: 'onay sorulur, oturumun kapanır',
      ),
    ],
    kural: 'Çıkınca bildirimler durur. '
        'Tekrar girince kaldığın yerden devam edersin.',
  ),
];
