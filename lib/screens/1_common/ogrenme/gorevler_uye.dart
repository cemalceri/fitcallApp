// lib/screens/1_common/ogrenme/gorevler_uye.dart
//
// Üye rehberleri. Yazım kuralları gorevler.dart'ta. Dışarı çıkan işlemler
// (telefon takvimi, dosya seçici, galeri) adım olarak basılmaz; bilgi ya da
// kalıcı son adım olarak anlatılır.

import 'package:fitcall/screens/1_common/ogrenme/gorev_ortak.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';

const List<OgrenmeGorevi> uyeGorevleri = [
  // ------------------------------------------------------------ Ana sayfa
  OgrenmeGorevi(
    id: 'uye.anaSayfa',
    sayfa: OgrenmeSayfasi.uyeAnaSayfa,
    baslik: 'Ana sayfada neler var?',
    kosulMetni: 'Ana sayfa açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.genelKabukMenu),
        metin: 'Soldaki ☰ menü bütün sayfaları açar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeOzet),
        metin: 'Bakiyen ve kalan hakların burada yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeSonrakiDers),
        metin: 'Sıradaki dersin burada görünür.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDuyuru),
        metin: 'Kulüp duyuruları en altta akar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeAltBar),
        metin: 'Alttan sayfalar arasında geçersin.',
        bilgi: true,
      ),
      soruIsaretiAdimi,
    ],
    kural: 'Derslerin alttaki Takvim sekmesinde. '
        'Ödemelerin Hareketler sekmesinde; aile profilinde görünmez.',
  ),
  OgrenmeGorevi(
    id: 'uye.cocukDersleri',
    sayfa: OgrenmeSayfasi.uyeAnaSayfa,
    baslik: 'Çocuğumun derslerini nasıl görürüm?',
    kosulMetni: 'Hesabına birden çok profil bağlı olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.profilDegistir),
        metin: 'Üstteki çift oklu düğmeye dokun.',
        kalici: true,
        sonuc: 'profil seçme ekranı açılır',
      ),
    ],
    kural: 'Çocuğunun profilini seçince onun takvimini görürsün. '
        'Bakiye, paket ve bildirimler ana hesapta görünür.',
  ),
  OgrenmeGorevi(
    id: 'uye.menu',
    sayfa: OgrenmeSayfasi.uyeAnaSayfa,
    baslik: 'Menüde neler var?',
    kosulMetni: 'Ana sayfa açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.genelKabukMenu),
        metin: 'Soldaki ☰ düğmesine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Ders Talebi ve Kort Kiralama'),
        metin: 'Ders ya da kort istersin, talebini izlersin.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Üyelik & Paket Bilgilerim'),
        metin: 'Paketlerin ve kalan hakların burada.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Telafi Derslerim'),
        metin: 'Telafi haklarının süresi burada.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Geçmiş Dersler'),
        metin: 'Katıldığın dersler burada listelenir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Bildirimler'),
        metin: 'Gelen bildirimler burada durur.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Yardım'),
        metin: 'Sık sorulan sorular burada.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Ayarlar'),
        metin: 'Tema, şifre ve çıkış burada.',
        bilgi: true,
      ),
    ],
    kural: 'Aktif etkinlik varsa «Event / Davet» satırı da çıkar. '
        'Aile profilinde paket, telafi ve bildirim sayfaları açılmaz.',
  ),
  OgrenmeGorevi(
    id: 'uye.borcum',
    sayfa: OgrenmeSayfasi.uyeAnaSayfa,
    baslik: 'Borcumu ya da bakiyemi nereden görürüm?',
    kosulMetni: 'Ana hesapla girince',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeOzetBakiye),
        metin: 'Borç ya da bakiye kutusuna dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeHareketBakiye),
        metin: 'Kalan borcun ya da fazla ödemen yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeHareketSatiri),
        metin: 'Bir hareket satırına dokun.',
        kalici: true,
        sonuc: 'tarih, ödeme şekli ve açıklama açılır',
      ),
    ],
    kural: 'Borç, ödeme ve paket kayıtları tek listede. '
        'Ödemek için «EFT / Havale» düğmesini kullan.',
  ),
  OgrenmeGorevi(
    id: 'uye.kalanHak',
    sayfa: OgrenmeSayfasi.uyeAnaSayfa,
    baslik: 'Kalan ders hakkımı nereden görürüm?',
    kosulMetni: 'Paketin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Kalan Haklarım'),
        metin: '«Kalan Haklarım» kutusuna dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Paketler'),
        metin: '«Paketler» başlığına dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeUrunKart),
        metin: 'Kalan hakkın ve dönemin kartta yazar.',
        bilgi: true,
      ),
    ],
    kural: 'Aidat ve tek dersler aynı sayfada. '
        'Hakkın azalınca ana sayfada uyarı çıkar.',
  ),
  OgrenmeGorevi(
    id: 'uye.bekleyen',
    sayfa: OgrenmeSayfasi.uyeAnaSayfa,
    baslik: '«Bekleyen İşlemler» neyi gösteriyor?',
    kosulMetni: 'Senden bir şey beklenince',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeBekleyen),
        metin: 'Senden adım bekleyen işler burada.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeBekleyen),
        metin: 'Karta dokun.',
        kalici: true,
        sonuc: 'ilgili sayfa açılır',
      ),
    ],
    kural: 'Katılım isteği, borç, biten paket, telafi süresi ve '
        'değerlendirme kartları çıkar. İş yoksa bölüm görünmez.',
  ),
  OgrenmeGorevi(
    id: 'uye.gecmisDersler',
    sayfa: OgrenmeSayfasi.uyeAnaSayfa,
    baslik: 'Geçmiş derslerime nereden bakarım?',
    kosulMetni: 'Son 30 günde dersin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.genelKabukMenu),
        metin: 'Soldaki ☰ düğmesine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Geçmiş Dersler'),
        metin: '«Geçmiş Dersler»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeGecmisDers),
        metin: 'Her derste durum ve yoklama yazar.',
        bilgi: true,
      ),
    ],
    kural: 'Eski kayıtlar için sayfanın sonundaki düğmeyi kullan. '
        'Derse puan vermek için «Değerlendir»e dokun.',
  ),
  OgrenmeGorevi(
    id: 'uye.kahve',
    sayfa: OgrenmeSayfasi.uyeAnaSayfa,
    baslik: 'Kahve ödülünü nasıl kazanırım?',
    kosulMetni: 'Kulüpte ödül tanımlıysa',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeOdul),
        metin: 'Turnikeden girdiğin her gün sayılır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeOdulBilgi),
        metin: 'Ayrıntı için ⓘ düğmesine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Tamam'),
        metin: '«Tamam»a dokun.',
        kalici: true,
        sonuc: 'pencere kapanır, sayaca dönersin',
      ),
    ],
    kural: 'Hedef güne ulaşınca «Ödülü al» çıkar. '
        'Kod sınırlı süre geçerli, görevliye gösterilir. '
        'Kullanınca sayaç sıfırdan başlar.',
  ),
  OgrenmeGorevi(
    id: 'uye.duyuru',
    sayfa: OgrenmeSayfasi.uyeAnaSayfa,
    baslik: 'Duyuruyu nasıl okurum?',
    kosulMetni: 'Duyuru olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDuyuruKarti),
        metin: 'Bir duyuru kartına dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kapat'),
        metin: 'Okuyunca «Kapat»a dokun.',
        kalici: true,
        sonuc: 'duyuru penceresi kapanır',
      ),
    ],
    kural: 'Önemli duyurular rozetle gelir. '
        'Kartlar kendiliğinden kayar, dokununca durur.',
  ),
  OgrenmeGorevi(
    id: 'uye.bildirimZili',
    sayfa: OgrenmeSayfasi.uyeAnaSayfa,
    baslik: 'Bildirimlerime nereden bakarım?',
    kosulMetni: 'Ana sayfa açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeBildirimZili),
        metin: 'Üstteki zil düğmesine dokun.',
        kalici: true,
        sonuc: 'bildirim listesi açılır',
      ),
    ],
    kural: 'Okunmamış bildirim sayısı zilde görünür. '
        'Aynı liste menüde ve Ayarlar\'da da var.',
  ),
  OgrenmeGorevi(
    id: 'uye.sonrakiDers',
    sayfa: OgrenmeSayfasi.uyeAnaSayfa,
    baslik: 'Sıradaki dersimin ayrıntısını nasıl görürüm?',
    kosulMetni: 'Planlı dersin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeSonrakiDersKarti),
        metin: 'Sonraki ders kartına dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Takvime Ekle'),
        metin: 'Dersi telefon takvimine ekleyebilirsin.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kapat'),
        metin: '«Kapat»a dokun.',
        kalici: true,
        sonuc: 'ayrıntı penceresi kapanır',
      ),
    ],
    kural: 'Saatler hep kulübün saatidir. '
        'Dersi değiştirmek için kulüple iletişime geç.',
  ),

  // --------------------------------------------------------------- Takvim
  OgrenmeGorevi(
    id: 'uye.katilamayacagim',
    sayfa: OgrenmeSayfasi.uyeTakvim,
    baslik: 'Derse gelemeyeceğimi nasıl bildiririm?',
    kosulMetni: 'Takviminde ders olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.takvimDersliGun),
        metin: 'Dersi olan bir güne dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.takvimDers),
        metin: 'Gelecek bir dersine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Katılamayacağım'),
        metin: '«Katılamayacağım»a dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.takvimAciklama),
        metin: 'İstersen kutuya nedenini yaz.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Katılamayacağımı Bildir'),
        metin: '«Katılamayacağımı Bildir»e dokun.',
        kalici: true,
        sonuc: 'ofise ve hocana haber gider',
      ),
    ],
    kural: 'Dersten en az 24 saat önce bildirirsen ders yanmaz; '
        'aidat dersinde telafi hakkı doğar. '
        'Daha geç bildirirsen ders yapılmış sayılır. '
        'Grup dersinde diğerleri geliyorsa ders iptal olmaz.',
  ),
  OgrenmeGorevi(
    id: 'uye.katilacagim',
    sayfa: OgrenmeSayfasi.uyeTakvim,
    baslik: 'Derse geleceğimi nasıl bildiririm?',
    kosulMetni: 'Cevap vermediğin dersin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.takvimDersliGun),
        metin: 'Dersi olan bir güne dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.takvimDers),
        metin: 'Gelecek bir dersine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Katılacağım'),
        metin: '«Katılacağım»a dokun.',
        kalici: true,
        sonuc: 'katılımın kaydedilir',
      ),
    ],
    kural: 'Cevabını sonradan değiştiremezsin. '
        'Değişiklik için kulüple iletişime geç.',
  ),
  OgrenmeGorevi(
    id: 'uye.haftaGez',
    sayfa: OgrenmeSayfasi.uyeTakvim,
    baslik: 'Başka haftanın derslerine nasıl bakarım?',
    kosulMetni: 'Takvim açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeHaftaOnceki),
        metin: 'Geçmiş haftalar için sol oka dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeHaftaSonraki),
        metin: 'Sağ ok sonraki haftaya geçer.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeHaftaBugun),
        metin: '«Bugün» seni bu haftaya döndürür.',
        bilgi: true,
      ),
    ],
    kural: 'Bir güne dokununca o günün dersleri açılır. '
        'Geçmiş dersine dokunursan değerlendirme penceresi açılır.',
  ),
  OgrenmeGorevi(
    id: 'uye.ajanda',
    sayfa: OgrenmeSayfasi.uyeTakvim,
    baslik: 'Dersleri liste olarak nasıl görürüm?',
    kosulMetni: 'Takvim açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeTakvimGorunum),
        metin: 'Sağ üstteki görünüm düğmesine dokun.',
        kalici: true,
        sonuc: 'günler yerine ders listesi açılır',
      ),
    ],
    kural: 'Aynı düğme ızgaraya geri döndürür. '
        'Ajanda ne zaman, ızgara günün nasıl olduğunu gösterir.',
  ),
  OgrenmeGorevi(
    id: 'uye.takvimeEkle',
    sayfa: OgrenmeSayfasi.uyeTakvim,
    baslik: 'Dersimi telefon takvimime nasıl eklerim?',
    kosulMetni: 'Cevap vermediğin dersin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.takvimDersliGun),
        metin: 'Dersi olan bir güne dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.takvimDers),
        metin: 'Gelecek bir dersine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Telefon Takvimine Ekle'),
        metin: 'Dersi telefon takvimine ekleyebilirsin.',
        bilgi: true,
      ),
    ],
    kural: 'Hatırlatmayı telefonun yapar. '
        'Ana sayfadaki sıradaki ders kartında da «Takvime Ekle» var.',
  ),
  OgrenmeGorevi(
    id: 'uye.iptalDers',
    sayfa: OgrenmeSayfasi.uyeTakvim,
    baslik: 'İptal edilen dersimi nasıl anlarım?',
    kosulMetni: 'İptal edilmiş dersin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeIptalGunu),
        metin: 'İptalli dersi olan güne dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeIptalDers),
        metin: '«İPTAL» etiketli derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeIptalKarti),
        metin: 'Kimin iptal ettiği burada yazar.',
        bilgi: true,
      ),
    ],
    kural: 'İptal edilen dersler takvimde çizili görünür. '
        'Telafi hakkın varsa Telafi Derslerim\'de çıkar.',
  ),

  // ----------------------------------------------------------- Hareketler
  OgrenmeGorevi(
    id: 'uye.hareketler',
    sayfa: OgrenmeSayfasi.uyeHareketler,
    baslik: 'Hesap hareketlerimi nasıl okurum?',
    kosulMetni: 'Hesap hareketin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeHareketBakiye),
        metin: 'Kalan borcun ya da fazla ödemen yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeHareketSatiri),
        metin: 'Her satır bir borç ya da ödeme.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeHareketSatiri),
        metin: 'Bir satıra dokun.',
        kalici: true,
        sonuc: 'tarih, ödeme şekli ve açıklama açılır',
      ),
    ],
    kural: 'Borç, ödeme ve paket kayıtları burada. '
        'Eksik kayıt görürsen kulüple iletişime geç.',
  ),
  OgrenmeGorevi(
    id: 'uye.havale',
    sayfa: OgrenmeSayfasi.uyeHareketler,
    baslik: 'Havaleyle nasıl öderim?',
    kosulMetni: 'Kulübün havale hesabı tanımlı olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('EFT / Havale'),
        metin: '«EFT / Havale»ye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.havaleIban),
        metin: "Bankandan bu IBAN'a gönder, açıklamaya üyenin adını yaz.",
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Dekont yükle'),
        metin: '«Dekont yükle»ye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Dekont seç'),
        metin: '«Dekont seç»e dokun.',
        kalici: true,
        sonuc: 'dekontunu fotoğraf ya da PDF olarak eklersin',
      ),
    ],
    kural: 'Dekontu gönderince kulüp kontrol edip hesabına işler. '
        'Durumunu Dekontlarım sekmesinden izlersin. '
        'Tutar ve açıklama yazmak isteğe bağlı.',
  ),

  // ------------------------------------------------------------ Havale/EFT
  OgrenmeGorevi(
    id: 'uye.dekontDurumu',
    sayfa: OgrenmeSayfasi.uyeHavale,
    baslik: 'Dekontumun durumunu nasıl görürüm?',
    kosulMetni: 'Dekont yüklemişsen',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeHavaleDekontlar),
        metin: '«Dekontlarım» sekmesine dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDekontSatiri),
        metin: 'Bir dekonta dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Dosyayı gör'),
        metin: 'Yüklediğin dosyayı buradan görürsün.',
        bilgi: true,
      ),
    ],
    kural: 'Durumlar: kontrol bekliyor, işlendi, reddedildi. '
        'Reddedilirse gerekçesi yazar. Onaydan sonra bakiyene yansır.',
  ),
  OgrenmeGorevi(
    id: 'uye.karekod',
    sayfa: OgrenmeSayfasi.uyeHavale,
    baslik: 'Karekodla nasıl öderim?',
    kosulMetni: 'Hesapta karekod tanımlıysa',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Karekodu göster'),
        metin: '«Karekodu göster»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('İndir'),
        metin: '«İndir»e dokun.',
        kalici: true,
        sonuc: 'karekod galeriye kaydedilir',
      ),
    ],
    kural: 'Sonra bankanın uygulamasında galeriden oku seçeneğini kullan. '
        'İlk kayıtta galeri izni istenebilir.',
  ),
  OgrenmeGorevi(
    id: 'uye.dekontGeriCek',
    sayfa: OgrenmeSayfasi.uyeHavale,
    baslik: 'Yanlış dekontu nasıl geri çekerim?',
    kosulMetni: 'Bekleyen dekontun olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeHavaleDekontlar),
        metin: '«Dekontlarım» sekmesine dokun.',
        atlanabilir: true,
      ),
      // «Geri çek» listede yalnız kaydırınca çıkar; rehber detaydan gider.
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeBekleyenDekont),
        metin: 'Bekleyen dekontuna dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Geri çek'),
        metin: '«Geri çek»e dokun.',
        kalici: true,
        sonuc: 'onay sorulur, dekont geri çekilir',
      ),
    ],
    kural: 'Yalnız bekleyen dekont geri çekilir. '
        'İşlenen dekont silinemez. Gerekirse yeniden yükleyebilirsin.',
  ),
  OgrenmeGorevi(
    id: 'uye.ibanKopyala',
    sayfa: OgrenmeSayfasi.uyeHavale,
    baslik: 'IBAN\'ı nasıl kopyalarım?',
    kosulMetni: 'Havale hesabı tanımlı olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.havaleIban),
        metin: 'IBAN bu satırda yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeIbanKopyala),
        metin: 'Yanındaki kopyala ikonuna dokun.',
        kalici: true,
        sonuc: 'IBAN panoya kopyalanır',
      ),
    ],
    kural: 'Alıcı adını da kopyalayabilirsin. '
        'Açıklamaya üyenin adını yaz.',
  ),

  // ---------------------------------------------------------------- Hesabım
  OgrenmeGorevi(
    id: 'uye.profilFoto',
    sayfa: OgrenmeSayfasi.uyeProfil,
    baslik: 'Profil fotoğrafımı nasıl değiştiririm?',
    kosulMetni: 'Hesabım açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeProfilFoto),
        metin: 'Başlıktaki fotoğrafına dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Galeriden seç'),
        metin: 'Fotoğraf çek ya da galeriden seç.',
        bilgi: true,
      ),
    ],
    kural: 'Fotoğrafın antrenöründe ve kulüp ekranlarında görünür. '
        'Kaldırırsan baş harfin görünür.',
  ),
  OgrenmeGorevi(
    id: 'uye.bilgilerim',
    sayfa: OgrenmeSayfasi.uyeProfil,
    baslik: 'Kayıtlı bilgilerime nereden bakarım?',
    kosulMetni: 'Hesabım açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('İletişim Bilgileri'),
        metin: '«İletişim Bilgileri»ne dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeBilgiSayfasi),
        metin: 'Telefon, e-posta ve adresin burada.',
        bilgi: true,
      ),
    ],
    kural: 'Bilgileri uygulamadan değiştiremezsin. '
        'Değişiklik için kulübe haber ver.',
  ),

  // --------------------------------------------------------- Üyelik & Paket
  OgrenmeGorevi(
    id: 'uye.paketHak',
    sayfa: OgrenmeSayfasi.uyeUrunler,
    baslik: 'Paketimden kaç ders kaldı?',
    kosulMetni: 'Paketin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Paketler'),
        metin: '«Paketler» başlığına dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeUrunKart),
        metin: 'Kalan hakkın kartta yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeUrunKart),
        metin: 'Çubuk kalan hakkını gösterir.',
        bilgi: true,
      ),
    ],
    kural: 'Dönem tarihleri kartın altında. '
        'Hakkın ikiye inince ana sayfada uyarı çıkar.',
  ),
  OgrenmeGorevi(
    id: 'uye.aidatTek',
    sayfa: OgrenmeSayfasi.uyeUrunler,
    baslik: 'Aidatım ve tek derslerim nerede?',
    kosulMetni: 'Aidat ya da tek dersin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Aidatlar'),
        metin: '«Aidatlar» başlığına dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeUrunKart),
        metin: 'Aidat dönemin kartta yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Tek Dersler'),
        metin: '«Tek Dersler» başlığına dokun.',
        kalici: true,
        sonuc: 'tek derslerin tarihi, kortu ve hocası listelenir',
      ),
    ],
    kural: 'Eksik kayıt görürsen kulüple iletişime geç.',
  ),

  // ----------------------------------------------------------------- Telafi
  OgrenmeGorevi(
    id: 'uye.telafiSure',
    sayfa: OgrenmeSayfasi.uyeTelafi,
    baslik: 'Telafi hakkımın süresi ne zaman doluyor?',
    kosulMetni: 'Telafi hakkın olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeTelafiOzet),
        metin: 'Toplam hakkın ve durumları yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Aktif'),
        metin: '«Aktif» sekmesine dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeTelafiKart),
        metin: 'Kalan gün kartın sağında yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeTelafiKart),
        metin: 'Karta dokun.',
        kalici: true,
        sonuc: 'iptal edilen ders ve son geçerlilik tarihi açılır',
      ),
    ],
    kural: 'Son 7 günde kalan gün sarı olur. '
        'Süresi dolan hak «Geçmiş» sekmesine geçer. '
        'Telafi dersi için kulüple iletişime geç.',
  ),
  OgrenmeGorevi(
    id: 'uye.telafiYapilan',
    sayfa: OgrenmeSayfasi.uyeTelafi,
    baslik: 'Kullandığım telafiyi nereden görürüm?',
    kosulMetni: 'Telafi dersi yaptıysan',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Yapılan'),
        metin: '«Yapılan» sekmesine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeTelafiYapilanKart),
        metin: 'Yaptığın telafi dersi kartta yazar.',
        bilgi: true,
      ),
    ],
    kural: 'Her kart hangi dersin telafisi olduğunu söyler.',
  ),

  // ---------------------------------------------------------- Geçmiş dersler
  OgrenmeGorevi(
    id: 'uye.degerlendir',
    sayfa: OgrenmeSayfasi.uyeGecmisDersler,
    baslik: 'Bir dersi nasıl değerlendiririm?',
    kosulMetni: 'Değerlendirmediğin dersin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Değerlendir'),
        metin: '«Değerlendir»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDegerlendirmePuan),
        metin: 'Yıldızlara dokunup puan ver.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDegerlendirmeYorum),
        metin: 'İstersen yorumunu yaz.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kaydet'),
        metin: '«Kaydet»e dokun.',
        kalici: true,
        sonuc: 'değerlendirmen kaydedilir',
      ),
    ],
    kural: 'Puan zorunlu, yorum isteğe bağlı. '
        'Kaydettikten sonra değiştiremezsin. '
        'İptal edilen derse puan verilmez.',
  ),
  OgrenmeGorevi(
    id: 'uye.dersDurumu',
    sayfa: OgrenmeSayfasi.uyeGecmisDersler,
    baslik: 'Ders ve yoklama etiketleri ne demek?',
    kosulMetni: 'Son 30 günde dersin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeGecmisDers),
        metin: '«Ders» etiketi dersin kendisini söyler.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeGecmisDers),
        metin: '«Yoklama» etiketi katılımını söyler.',
        bilgi: true,
      ),
    ],
    kural: 'Ders: yapıldı, yapılmadı, onay bekliyor ya da iptal. '
        'Yoklama: katıldı, katılmadı ya da girilmedi.',
  ),
  OgrenmeGorevi(
    id: 'uye.eskiDersler',
    sayfa: OgrenmeSayfasi.uyeGecmisDersler,
    baslik: 'Daha eski derslerime nasıl bakarım?',
    kosulMetni: 'Son 30 günden eski kaydın olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Daha eski dersleri göster'),
        metin: 'Sayfanın sonundaki düğmeye dokun.',
        kalici: true,
        sonuc: 'bir önceki dönemin dersleri eklenir',
      ),
    ],
    kural: 'Daha eski kayıt kalmadıysa bunu yazar.',
  ),

  // ----------------------------------------------------------- Katılım onayı
  OgrenmeGorevi(
    id: 'uye.teyitCevap',
    sayfa: OgrenmeSayfasi.uyeTeyit,
    baslik: 'Katılım isteğine nasıl cevap veririm?',
    kosulMetni: 'Bekleyen isteğin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeTeyitKarti),
        metin: 'Bir ders kartına dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Evet'),
        metin: 'Gelecek misin? «Evet»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Gönder'),
        metin: '«Gönder»e dokun.',
        kalici: true,
        sonuc: 'cevabın ofise ve hocana iletilir',
      ),
    ],
    kural: '«Hayır» dersen nedenini yazabilirsin. '
        'Verdiğin cevap sonradan değişmez. '
        'Süresi geçen derse cevap verilmez.',
  ),

  // ------------------------------------------------------------- Event/Davet
  OgrenmeGorevi(
    id: 'uye.davetEt',
    sayfa: OgrenmeSayfasi.uyeEvent,
    baslik: 'Etkinliğe misafirimi nasıl davet ederim?',
    kosulMetni: 'Aktif etkinlik olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeEventKod),
        metin: 'Giriş kodun etkinlik boyunca geçerli.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Davet Et'),
        metin: '«Davet Et»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('QR Oluştur'),
        metin: '«QR Oluştur»a dokun.',
        kalici: true,
        sonuc: 'davetlin için giriş kodu oluşur',
      ),
    ],
    kural: 'Davet hakkın kalmadıysa düğme «Kota Doldu» olur. '
        'Davetliyi listeden silebilirsin.',
  ),

  // -------------------------------------------- Ders talebi / kort kiralama
  OgrenmeGorevi(
    id: 'uye.talepAc',
    sayfa: OgrenmeSayfasi.uyeTaleplerim,
    baslik: 'Ders ya da kort nasıl isterim?',
    kosulMetni: 'Taleplerim açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Yeni talep'),
        metin: 'Sağ alttaki «Yeni talep»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeTalepTurleri),
        metin: 'Ne istediğini seç.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Devam'),
        metin: '«Devam»a dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeTalepKare),
        metin: 'Uygun bir kareye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeTalepSaatDevam),
        metin: 'Alttaki «Devam»a dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Ofise gönder'),
        metin: '«Ofise gönder»e dokun.',
        kalici: true,
        sonuc: 'talebin ofise gider',
      ),
    ],
    kural: 'Ofis onaylayınca ders takvimine eklenir, sana haber gelir.',
  ),
  OgrenmeGorevi(
    id: 'uye.talepOneri',
    sayfa: OgrenmeSayfasi.uyeTaleplerim,
    baslik: 'Ofisin önerisine nasıl cevap veririm?',
    kosulMetni: 'Ofisten öneri gelince',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeTalepOnerili),
        metin: '«Öneri:» yazan talebine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeTalepOneri),
        metin: '«Ofisin önerisi» kısmını oku.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kabul et'),
        metin: '«Kabul et»e dokun.',
        kalici: true,
        sonuc: 'ders takvimine eklenir',
      ),
    ],
    kural: 'Son cevap saatine kadar cevap ver. '
        '«Reddet» dersen talep kapanır.',
  ),
  OgrenmeGorevi(
    id: 'uye.talepGeriCek',
    sayfa: OgrenmeSayfasi.uyeTaleplerim,
    baslik: 'Talebimi nasıl geri çekerim?',
    kosulMetni: 'Açık talebin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeTalepGeriCekilir),
        metin: 'Açık talebine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Geri çek'),
        metin: '«Geri çek»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Evet'),
        metin: 'Pencerede «Evet»e dokun.',
        kalici: true,
        sonuc: 'talebin kapanır',
      ),
    ],
    kural: 'Açık talep sınırın dolunca birini geri çekip yer açarsın.',
  ),
];
