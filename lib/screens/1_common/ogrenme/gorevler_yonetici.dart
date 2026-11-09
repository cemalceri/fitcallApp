// lib/screens/1_common/ogrenme/gorevler_yonetici.dart
//
// Yönetici rehberleri. Yazım kuralları gorevler.dart'ta.

import 'package:fitcall/screens/1_common/ogrenme/gorev_ortak.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';

const List<OgrenmeGorevi> yoneticiGorevleri = [
  OgrenmeGorevi(
    id: 'yonetici.anaSayfa',
    sayfa: OgrenmeSayfasi.yoneticiAnaSayfa,
    baslik: 'Ana sayfadaki kartlar neyi gösteriyor?',
    kosulMetni: 'Ana sayfa açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiBugun),
        metin: 'Üstteki kart yalnız bugünü gösterir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.panoDonemSecici),
        metin: 'Dönemi buradan seçersin.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiDonem),
        metin: 'Kutudaki dört kart seçtiğin dönemi gösterir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiSuAn),
        metin: '«Şu an» altındakiler dönemden bağımsızdır.',
        bilgi: true,
      ),
      soruIsaretiAdimi,
    ],
    kural: 'Yüzdeler, önceki aynı uzunluktaki dönemle kıyastır. '
        '«Toplam Alacak»a dokununca borçlu üyeler açılır.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.ciroTahsilat',
    sayfa: OgrenmeSayfasi.yoneticiAnaSayfa,
    baslik: 'Ciro ile tahsilat neden farklı?',
    kosulMetni: 'Ana sayfa açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiCiro),
        metin: '«Ciro»: iptal edilmeyen derslerin ücreti.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiTahsilat),
        metin: '«Tahsilat»: o günlere yazılan ödemeler.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.grafikTahsilat),
        metin: 'Alttaki grafikte «Tahsilat»a dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.grafikAlani),
        metin: 'Grafik bu haftanın günlerini gösterir.',
        bilgi: true,
      ),
    ],
    kural: 'Ciro onay beklemez; iptal edilmeyen her ders sayılır. '
        'Ödemeler sonradan girilebildiği için tahsilat geriden gelir.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.kortDoluluk',
    sayfa: OgrenmeSayfasi.yoneticiRaporlar,
    baslik: 'Kort doluluğu nasıl hesaplanıyor?',
    kosulMetni: 'Raporlar açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporKortSecici),
        metin: '«Kort ve antrenör» kutusunda «Bu Ay»ı seç.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporKortSatiri),
        metin: 'Yüzde, kortta ders olan saatin oranı.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporKortSatiri),
        metin: 'Altında dolu saat ve toplam saat yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporIsiHaritasi),
        metin: 'En alttaki harita bu haftayı gösterir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporIsiHaritasi),
        metin: 'Hücredeki sayı o saatte başlayan derslerdir.',
        bilgi: true,
      ),
    ],
    kural: 'Aynı saatte iki ders olsa da kort bir kez dolu sayılır. '
        'Açık saat her gün 07:00–23:00 arasıdır.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.gelmeyenler',
    sayfa: OgrenmeSayfasi.yoneticiUyeler,
    baslik: 'Uzun süredir gelmeyen üyeleri nasıl bulurum?',
    kosulMetni: 'Üye listesi açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeFiltrele),
        metin: '«Filtrele»ye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.filtreDurum),
        metin: '«Durum»da «Aktif»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.filtreDers),
        metin: '«Derse gelmeyenler»de «30 gündür»e dokun.',
      ),
      // Filtre bir şey yazmaz: dokununca liste süzülür, rehber biter.
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.filtreUygula),
        metin: 'Alttaki «üyeyi göster»e dokun.',
      ),
    ],
    kural: 'Hiç dersi olmayan üyeler de listeye girer. '
        'Filtreyi listenin üstündeki «Tümünü temizle» kaldırır.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.borc',
    sayfa: OgrenmeSayfasi.yoneticiUyeler,
    baslik: 'Bir üyenin borcu nereden geliyor?',
    kosulMetni: 'Borçlu üye olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeBorcluKart),
        metin: 'Üstteki «Borçlu» kartına dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeSatiri),
        metin: 'Listeden bir üyeye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Borç Dökümü'),
        metin: '«Borç Dökümü»ne dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.borcHareketleri),
        metin: 'Satırdaki + borç, − ödemedir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Aylık Özet'),
        metin: '«Aylık Özet»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.borcAylik),
        metin: 'Her ayın borcu, ödemesi ve bakiyesi yazar.',
        bilgi: true,
      ),
    ],
    kural: 'Bakiye eksideyse üye borçludur. '
        'Aylık özette «(B)» o ay borçlu kapandı demek.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.yorumlar',
    sayfa: OgrenmeSayfasi.yoneticiAntrenorler,
    baslik: 'Bir hocanın yorumlarını nasıl incelerim?',
    kosulMetni: 'Puanı olan bir hoca olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Yorumlar'),
        metin: 'Bir hocanın sağındaki «Yorumlar»a dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.degerlendirmeSuzgec),
        metin: 'Üstteki «3 ve altı» düşük puanları ayırır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.degerlendirmeSatiri),
        metin: 'Listeden bir değerlendirmeye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.digerKatilimcilar),
        metin: '«Diğer katılımcılar»ın puanına da bak.',
        bilgi: true,
      ),
    ],
    kural: 'Puan, üyelerin bu hocanın derslerine verdiği puanların '
        'ortalaması. Hocanın adına dokununca hakediş saatleri açılır.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.hakedis',
    sayfa: OgrenmeSayfasi.yoneticiHakedis,
    baslik: 'Bir hocanın aylık hakedişini nasıl kontrol ederim?',
    kosulMetni: 'Hocaların bitmiş dersi olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisAy),
        metin: 'Izgarada dersi olan bir aya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisAyBasligi),
        metin: 'Başlıkta hakediş ve bekleyen ders yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisAntrenor),
        metin: 'Listeden bir hocaya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorHakedisAlacak),
        metin: '«Hakediş» ödenecek saatlerdir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisBekliyor),
        metin: '«Bekliyor» kararı verilmemiş derslerdir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorHakedisOran),
        metin: 'Çubuk saatlerin dağılımını gösterir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorHakedisRol),
        metin: 'Kartlar hocanın rolüne göre ayrılır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisGrup),
        metin: 'Bir grup satırına dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisDers),
        metin: 'Her dersin tarihi ve durumu yazar.',
        bilgi: true,
      ),
    ],
    kural: 'Ofis «Yapıldı» ya da «Yapılmadı» deyince bekleyen ders gruba '
        'geçer. Aynı saatteki dersler bir kez sayılır.',
  ),

  // ------------------------------------------------------------ Ana sayfa
  OgrenmeGorevi(
    id: 'yonetici.dersKarti',
    sayfa: OgrenmeSayfasi.yoneticiAnaSayfa,
    baslik: 'Onaylanan ve planlanan ders ne demek?',
    kosulMetni: 'Ana sayfa açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiDers),
        metin: 'Soldaki sayı ofisin onayladığı derstir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiDers),
        metin: 'Sağdaki sayı iptal edilmeyen derstir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiIptal),
        metin: '«İptal Edilen» iptal olan dersleri sayar.',
        bilgi: true,
      ),
    ],
    kural: 'Aradaki fark başlamamış ya da onay bekleyen derstir. '
        'Altındaki yüzde kort doluluğudur.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.alacak',
    sayfa: OgrenmeSayfasi.yoneticiAnaSayfa,
    baslik: 'Toplam alacak neyi gösteriyor?',
    kosulMetni: 'Ana sayfa açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiAktifUye),
        metin: '«Aktif Üye» şu anki aktif üye sayısıdır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiAlacak),
        metin: '«Toplam Alacak» üyelerin toplam borcudur.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiAlacak),
        metin: '«Toplam Alacak»a dokun.',
        kalici: true,
        sonuc: 'Üyeler sekmesi borçlu üyelerle açılır',
      ),
    ],
    kural: 'Bu iki kart dönemden bağımsızdır, o anki durumu gösterir. '
        'Borçluları Üyeler sekmesinde en borçludan başlayarak görürsün.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.menu',
    sayfa: OgrenmeSayfasi.yoneticiAnaSayfa,
    baslik: 'Sol menüde neler var?',
    kosulMetni: 'Ana sayfa açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiMenu),
        metin: 'Soldaki menü düğmesine dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Dersler'),
        metin: '«Dersler» günün derslerini listeler.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Raporlar'),
        metin: '«Raporlar» ciro ve doluluk tablolarıdır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Duyurular'),
        metin: '«Duyurular» kimlerin gördüğünü gösterir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Hakediş Saatleri'),
        metin: '«Hakediş Saatleri» hocaların aylık saatidir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Borçlu Üyeler'),
        metin: '«Borçlu Üyeler» borcu olanları açar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('QR Oluştur'),
        metin: '«QR Oluştur»a dokun.',
        kalici: true,
        sonuc: 'kendi giriş QR\'ın ve misafir davetin açılır',
      ),
    ],
    kural: 'Ders açma, iptal ve QR doğrulama ofis profilindedir. '
        'Yönetici menüsü yalnız raporlar.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.bugununOzeti',
    sayfa: OgrenmeSayfasi.yoneticiAnaSayfa,
    baslik: 'Bugünün özetindeki üç sayı ne?',
    kosulMetni: 'Ana sayfa açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiBugun),
        metin: '«Yeni Üye» bugün kaydı açılanlardır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiBugun),
        metin: '«Ders» bugünkü iptal edilmeyen derstir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiBugun),
        metin: '«Doluluk» bugünkü kort doluluğudur.',
        bilgi: true,
      ),
    ],
    kural: 'Bu kart dönem seçiciden etkilenmez. Yalnız bugünü gösterir.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.hizliErisim',
    sayfa: OgrenmeSayfasi.yoneticiAnaSayfa,
    baslik: 'Bugünün derslerinde onay bekleyen nerede görünür?',
    kosulMetni: 'Ana sayfa açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiHizli),
        metin: '«Bugün» altında üç kısayol var.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiBugunDersleri),
        metin: 'Onay bekleyen ders varsa kırmızı sayı çıkar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiBugunDersleri),
        metin: '«Bugünün Dersleri»ne dokun.',
        kalici: true,
        sonuc: 'Dersler sekmesi bugünün listesiyle açılır',
      ),
    ],
    kural: 'Onay bekleyen, dersi bitmiş ama ofis onayı olmayan derstir. '
        'Onayı ofis verir.',
  ),

  // -------------------------------------------------------------- Raporlar
  OgrenmeGorevi(
    id: 'yonetici.ciroRaporu',
    sayfa: OgrenmeSayfasi.yoneticiRaporlar,
    baslik: 'Ciro ve tahsilat tablosu nasıl okunur?',
    kosulMetni: 'Raporlar açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporCiroSecici),
        metin: '«Ciro ve tahsilat» kutusunda «Bu Ay»ı seç.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporOzetKartlar),
        metin: 'Üstteki kartlar seçtiğin dönemin toplamıdır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporCiroTablosu),
        metin: '«Ciro Raporu» günlük ders ücretini gösterir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporTahsilatTablosu),
        metin: '«Tahsilat Raporu» günlük ödemeleri gösterir.',
        bilgi: true,
      ),
    ],
    kural: 'Ciro ders ücretidir, tahsilat ödemedir; aynı güne denk gelmez. '
        'Boş dönemde «veri bulunamadı» yazar.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.antrenorPerformans',
    sayfa: OgrenmeSayfasi.yoneticiRaporlar,
    baslik: 'Antrenör performansı neyi gösteriyor?',
    kosulMetni: 'Antrenör verisi olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporKortSecici),
        metin: '«Kort ve antrenör» kutusunda «Bu Ay»ı seç.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporAntrenorSatiri),
        metin: 'Satırda onaylanan ve toplam ders yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporAntrenorSatiri),
        metin: '«iptal» o hocanın iptal edilen dersidir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporAntrenorSatiri),
        metin: 'Puan varsa sağda yıldızla yazar.',
        bilgi: true,
      ),
    ],
    kural: 'Toplam iptal edilmeyen dersleri sayar. '
        'Puan yoksa yıldız görünmez.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.isiHaritasi',
    sayfa: OgrenmeSayfasi.yoneticiRaporlar,
    baslik: 'Hangi saatler en yoğun, nasıl görürüm?',
    kosulMetni: 'Bu hafta ders olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporIsiHaritasi),
        metin: 'Satırlar saat, sütunlar bu haftanın günleri.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporIsiHaritasi),
        metin: 'Koyu hücre çok ders demektir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.raporIsiHaritasi),
        metin: 'Hücredeki sayı o saatte başlayan derstir.',
        bilgi: true,
      ),
    ],
    kural: 'Harita dönem seçicisine bağlı değil, hep bu haftadır. '
        'Planlı dersler de sayılır.',
  ),

  // ---------------------------------------------------------------- Üyeler
  OgrenmeGorevi(
    id: 'yonetici.uyeAra',
    sayfa: OgrenmeSayfasi.yoneticiUyeler,
    baslik: 'Bir üyeyi isim ya da telefonla nasıl bulurum?',
    kosulMetni: 'Üye listesi açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeArama),
        metin: 'Kutuya isim, telefon ya da üye no yaz.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeSatiri),
        metin: 'Liste yazdıkça süzülür.',
        bilgi: true,
      ),
    ],
    kural: 'Aramayı kutudaki çarpı temizler. '
        'Sonuç sayısı başlıktaki kayıt rozetindedir.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.uyeSirala',
    sayfa: OgrenmeSayfasi.yoneticiUyeler,
    baslik: 'Üyeleri borca ya da son ödemeye göre nasıl sıralarım?',
    kosulMetni: 'Üye listesi açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeSirala),
        metin: '«Sırala»ya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.siralamaBorc),
        metin: '«Borca göre» satırına dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeSatiri),
        metin: 'En borçlu üye listenin başına gelir.',
        bilgi: true,
      ),
    ],
    kural: '«Son ödemeye göre (en eski önce)» uzun süredir ödemeyenleri öne alır. '
        'Seçince satırın altındaki tarih de değişir.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.uyeSatiri',
    sayfa: OgrenmeSayfasi.yoneticiUyeler,
    baslik: 'Üye satırındaki rozet ve rakamlar ne demek?',
    kosulMetni: 'Üye olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeSatiri),
        metin: 'Sağdaki tutar üyenin bakiyesidir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeSatiri),
        metin: 'Kırmızı borç, yeşil alacak demektir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeSatiri),
        metin: '«#» ile başlayan sayı üye numarasıdır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeSatiri),
        metin: 'Pasif üyede adın yanında «Pasif» rozeti çıkar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeSatiri),
        metin: 'Borcu kesinleşen üyede «Kesin» rozeti çıkar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeSatiri),
        metin: 'Telefonu varsa sola kaydırınca «Ara» ve «WhatsApp» çıkar.',
        bilgi: true,
      ),
    ],
    kural: 'Ön muhasebe kesinleştirmeyi web\'de işaretler. '
        'Telefonu olmayan üyede kaydırma eylemi yoktur.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.uyeKartlari',
    sayfa: OgrenmeSayfasi.yoneticiUyeler,
    baslik: 'Üstteki Toplam, Aktif, Pasif, Borçlu, Yeni ne yapar?',
    kosulMetni: 'Üye listesi açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeKartlari),
        metin: 'Kartlardaki sayılar işletmenin üye sayısıdır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeYeniKart),
        metin: '«Yeni»ye dokun.',
      ),
      // Bu ay kayıt yoksa liste boş kalır: son adım satıra değil düğmeye.
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeFiltrele),
        metin: 'Liste bu ay kaydolanlara süzülür, «Filtrele»de görünür.',
        bilgi: true,
      ),
    ],
    kural: '«Toplam» tüm filtreleri kaldırır. '
        '«Borçlu» en borçludan, «Yeni» en yeni kayıttan başlar.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.uyeFiltreleri',
    sayfa: OgrenmeSayfasi.yoneticiUyeler,
    baslik: 'Borç tutarı ya da son ödemeye göre nasıl filtrelerim?',
    kosulMetni: 'Üye listesi açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeFiltrele),
        metin: '«Filtrele»ye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.filtreBorc),
        metin: '«Borç»ta en az ve en çok tutar yazarsın.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.filtreKesin),
        metin: 'Ön muhasebe web\'de «kesinleşme»yi işaretler.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.filtreOdeme),
        metin: '«Hiç ödeme yok» ödemesiz üyeleri bulur.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.filtreUygula),
        metin: 'Alttaki «üyeyi göster»e dokun.',
      ),
    ],
    kural: 'Seçilen filtrelerin hepsi birlikte uygulanır. '
        '«Temizle» hepsini kaldırır.',
  ),

  // ------------------------------------------------------------ Üye detayı
  OgrenmeGorevi(
    id: 'yonetici.uyePaket',
    sayfa: OgrenmeSayfasi.yoneticiUyeDetay,
    baslik: 'Üyenin paketi ve kalan hakkı nerede?',
    kosulMetni: 'Üye detayı açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDetayPaketler),
        metin: '«Paketler & Haklar» tüm paketleri listeler.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDetayPaketler),
        metin: 'Varsa «Kalan hak» kullanılmamış ders sayısıdır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDetayPaketler),
        metin: 'Yeşil işaret aktif, gri işaret pasif pakettir.',
        bilgi: true,
      ),
    ],
    kural: 'Hak yazmayan pakette hak takibi yoktur. '
        'Paket ekleme ofiste ve web\'dedir.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.uyeDersler',
    sayfa: OgrenmeSayfasi.yoneticiUyeDetay,
    baslik: 'Üyenin yaklaşan ve geçmiş dersleri nerede?',
    kosulMetni: 'Üye detayı açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDetayYaklasan),
        metin: '«Yaklaşan Dersler» önümüzdeki dersleri listeler.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDetayGecmis),
        metin: '«Geçmiş Dersler» geçmiş dersleri listeler.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDetayGecmis),
        metin: 'İptal edilen dersin üstü çizilir, «İptal» yazar.',
        bilgi: true,
      ),
    ],
    kural: 'Satırda tarih, paket, hoca ve kort yazar. '
        'Ders açma ve iptal ofiste yapılır.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.uyeBakiye',
    sayfa: OgrenmeSayfasi.yoneticiUyeDetay,
    baslik: 'Üyenin bakiyesi ve borcu nasıl okunur?',
    kosulMetni: 'Üye detayı açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDetayBakiye),
        metin: '«Güncel Bakiye» toplam borç ya da alacaktır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDetayBakiye),
        metin: '«Borçlu» yazıyorsa ödemesi eksiktir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Borç Dökümü'),
        metin: '«Borç Dökümü»ne dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.borcHareketleri),
        metin: 'Satırdaki + borç, − ödemedir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Aylık Özet'),
        metin: '«Aylık Özet»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.borcAylik),
        metin: 'Her ayın borcu, ödemesi ve bakiyesi yazar.',
        bilgi: true,
      ),
    ],
    kural: 'Bakiye eksideyse üye borçludur. '
        'Aylık özette «(B)» o ay borçlu kapandı demek.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.uyeIletisim',
    sayfa: OgrenmeSayfasi.yoneticiUyeDetay,
    baslik: 'Üyenin telefonu, velisi ve sorumlu hocası nerede?',
    kosulMetni: 'Üye detayı açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDetayBilgiler),
        metin: '«İletişim & Bilgiler» telefon ve e-postayı gösterir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDetayBilgiler),
        metin: 'Gençlerde anne, baba ve acil durum kişisi yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDetayBilgiler),
        metin: 'Varsa «Sorumlu Hoca» üyeyle ilgilenen antrenördür.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeDetayHizli),
        metin: '«Ara» ve «WhatsApp» uygulama dışında açılır.',
        bilgi: true,
      ),
    ],
    kural: '«Ödeme Linki» banka entegrasyonu bitene kadar kapalıdır. '
        'Telefon kayıtlı değilse Ara ve WhatsApp çalışmaz.',
  ),

  // ----------------------------------------------------------- Antrenörler
  OgrenmeGorevi(
    id: 'yonetici.antrenorSatiri',
    sayfa: OgrenmeSayfasi.yoneticiAntrenorler,
    baslik: 'Antrenör satırındaki sayılar ne demek?',
    kosulMetni: 'Antrenör olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorSatiri),
        metin: '«Bugün 3 ders» o günkü ders sayısıdır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorSatiri),
        metin: '«hafta» bu haftanın toplam dersidir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorSatiri),
        metin: 'Sonuncu sayı öğrenci sayısıdır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorPuan),
        metin: 'Puan varsa yıldızla, yanında değerlendirme sayısı yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorSatiri),
        metin: 'Hocanın adına dokun.',
        kalici: true,
        sonuc: 'o hocanın aylık hakediş saatleri açılır',
      ),
    ],
    kural: '«Pasif» rozetli hoca ayrılmıştır. '
        'Puanı olmayan hocada «Puan yok» yazar.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.antrenorFiltre',
    sayfa: OgrenmeSayfasi.yoneticiAntrenorler,
    baslik: 'Pasif antrenörleri nasıl görürüm?',
    kosulMetni: 'Antrenörler açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Pasif'),
        metin: '«Pasif»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Tümü'),
        metin: '«Tümü» aktif ve pasif hocaları birlikte gösterir.',
        bilgi: true,
      ),
    ],
    kural: 'Ayrılan hocalar «Pasif» rozetiyle görünür. '
        'Varsayılan görünüm «Aktif»tir.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.antrenorKartlari',
    sayfa: OgrenmeSayfasi.yoneticiAntrenorler,
    baslik: 'Üstteki Toplam, Aktif, Bugün Ders, Ort. Puan ne demek?',
    kosulMetni: 'Antrenör olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorKartlari),
        metin: '«Bugün Ders» bugünkü iptal edilmeyen derstir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorKartlari),
        metin: '«Ort. Puan» üyelerin verdiği puanın ortalamasıdır.',
        bilgi: true,
      ),
    ],
    kural: 'Kartlar seçili süzgeci değil, tüm kadroyu özetler.',
  ),

  // --------------------------------------------------------------- Hakediş
  OgrenmeGorevi(
    id: 'yonetici.hakedisRozet',
    sayfa: OgrenmeSayfasi.yoneticiHakedis,
    baslik: 'Ders kartındaki rozetler ve notlar ne demek?',
    kosulMetni: 'İptal ya da yapılmamış dersi olan hoca olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisAy),
        metin: 'Izgarada dersi olan bir aya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisDisiAntrenor),
        metin: 'Hakediş dışı dersi olan hocaya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorHakedisDisiGrup),
        metin: '«Hakediş dışı» satırına dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisDers),
        metin: 'İptal edilen derste «İptal edildi» rozeti çıkar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisDers),
        metin: 'İptalde altındaki panel kimin, neden iptal ettiğini yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisDers),
        metin: '«Ders yapılmadı» rozeti ofisin kararıdır.',
        bilgi: true,
      ),
    ],
    kural: 'Kararı ofis verir; yönetici yalnız bakar. '
        'Rozetsiz ders normal yapılmıştır.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.hakedisAra',
    sayfa: OgrenmeSayfasi.yoneticiHakedis,
    baslik: 'Hakediş listesinde bir hocayı nasıl bulurum?',
    kosulMetni: 'Hakediş sayfası açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisArama),
        metin: '«Antrenör ara» kutusuna ad yaz.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisFiltre),
        metin: '«Pasif» ayrılan hocaları da gösterir.',
        bilgi: true,
      ),
    ],
    kural: 'Ay ızgarasından başka aya geçebilirsin. '
        'Liste seçtiğin ayın hakedişine göre dizilir.',
  ),

  // -------------------------------------------------------- Değerlendirmeler
  OgrenmeGorevi(
    id: 'yonetici.dusukPuan',
    sayfa: OgrenmeSayfasi.yoneticiDegerlendirmeler,
    baslik: 'Düşük puanları nasıl ayırırım?',
    kosulMetni: 'Değerlendirmeler açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('3 ve altı'),
        metin: '«3 ve altı»ya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.degerlendirmeSatiri),
        metin: 'Liste yalnız düşük puanlıları gösterir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.degerlendirmeSatiri),
        metin: 'Kırmızı simge 2 ve altı puandır.',
        bilgi: true,
      ),
    ],
    kural: '«Tümü» süzgeci kaldırır. '
        'Başlıktaki yıldız ortalama puan ve değerlendirme sayısıdır.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.yorumluOlanlar',
    sayfa: OgrenmeSayfasi.yoneticiDegerlendirmeler,
    baslik: 'Yorum yazılanları nasıl görürüm?',
    kosulMetni: 'Yorumlu değerlendirme olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Yorumlu'),
        metin: '«Yorumlu»ya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.degerlendirmeSatiri),
        metin: 'Satırda yorumun ilk satırı yazar.',
        bilgi: true,
      ),
    ],
    kural: 'Yorumsuz puanlar bu süzgeçte görünmez. '
        '«Tümü» hepsini geri getirir.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.degerlendirmeDetayi',
    sayfa: OgrenmeSayfasi.yoneticiDegerlendirmeler,
    baslik: 'Bir değerlendirmenin detayına nasıl bakarım?',
    kosulMetni: 'Değerlendirme olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.degerlendirmeSatiri),
        metin: 'Listeden bir değerlendirmeye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.digerKatilimcilar),
        metin: '«Diğer katılımcılar» aynı dersteki ötekilerdir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.digerKatilimcilar),
        metin: 'Puan vermeyene «Puanlamadı» yazar.',
        bilgi: true,
      ),
    ],
    kural: 'Üstte puan ve yorum, altında ders bilgisi durur. '
        'Gelmeyen katılımcı «Derse gelmedi» diye işaretlenir.',
  ),

  // ---------------------------------------------------------------- Dersler
  OgrenmeGorevi(
    id: 'yonetici.gunDersleri',
    sayfa: OgrenmeSayfasi.yoneticiDersler,
    baslik: 'Başka bir günün derslerini nasıl görürüm?',
    kosulMetni: 'Dersler açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiDersSonrakiGun),
        metin: 'Sağdaki ok ile ertesi güne geç.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Bugün'),
        metin: '«Bugün»e dokun.',
        kalici: true,
        sonuc: 'liste bugüne döner',
      ),
    ],
    kural: 'Ortadaki tarih kutusundan takvimle gün seçersin. '
        'Liste yalnız okunur.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.dersDurumlari',
    sayfa: OgrenmeSayfasi.yoneticiDersler,
    baslik: 'Tamamlandı, Devam, Bekliyor, İptal ne demek?',
    kosulMetni: 'Dersler açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiDersKartlari),
        metin: '«Toplam» o günün iptaller dahil tüm dersidir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiDersKartlari),
        metin: '«Tamamlandı» ofisin onayladığı derslerdir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiDersKartlari),
        metin: '«Devam» şu an süren, onaysız derstir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiDersKartlari),
        metin: '«Bekliyor» henüz başlamamış derstir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiDersKartlari),
        metin: '«İptal» iptal edilen derstir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiDersSatiri),
        metin: 'Satırda soldaki kutu dersin saatidir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoneticiDersSatiri),
        metin: 'Rozet dersin durumunu, altı hocayı gösterir.',
        bilgi: true,
      ),
    ],
    kural: 'Bitmiş dersin onayını ofis verir. '
        'Onay bekleyenler ana sayfadaki «Bugünün Dersleri» rozetinde de görünür.',
  ),
  OgrenmeGorevi(
    id: 'yonetici.dersFiltre',
    sayfa: OgrenmeSayfasi.yoneticiDersler,
    baslik: 'Sadece iptal edilen dersleri nasıl görürüm?',
    kosulMetni: 'Dersler açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('İptal'),
        metin: '«İptal»e dokun.',
      ),
    ],
    kural: 'Liste yalnız iptal edilenleri gösterir; «Tümü» süzgeci kaldırır. '
        'Süzgeç seçili günün dersleri içindir.',
  ),
];
