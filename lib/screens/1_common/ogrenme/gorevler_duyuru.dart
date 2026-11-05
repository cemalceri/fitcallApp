// lib/screens/1_common/ogrenme/gorevler_duyuru.dart
//
// Duyurular rehberleri (ofis ve yönetici ortak sayfa). Yazım kuralları gorevler.dart'ta.
//
// "?" yalnız liste sayfasında: rehberler oradan başlar, okuma durumu sayfasına
// kendileri yürür. Duyuru oluşturma mobilde yok (web paneli); rehberler bunu
// söyler, web simgesine bastırmaz.

import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';

const List<OgrenmeGorevi> duyuruGorevleri = [
  OgrenmeGorevi(
    id: 'duyuru.oran',
    sayfa: OgrenmeSayfasi.duyurular,
    baslik: 'Duyurunun yanındaki yüzde neyi söylüyor?',
    kosulMetni: 'Duyuru olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.duyuruSatiri),
        metin: 'Sağdaki yüzde duyuruyu görenlerin oranıdır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.duyuruSatiri),
        metin: 'Altındaki «54/142» gören ve hedef hesaptır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.duyuruSatiri),
        metin: 'Popup ya da önemliyse alt satırda yazar.',
        bilgi: true,
      ),
    ],
    kural: 'Liste Yayında, Planlanan ve Geçmiş diye ayrılır. '
        '«ölçülmüyor» yazan duyuruyu antrenörler yalnız popup\'ta görür.',
  ),
  OgrenmeGorevi(
    id: 'duyuru.gorenler',
    sayfa: OgrenmeSayfasi.duyurular,
    baslik: 'Bir duyuruyu kimler görmüş, nasıl anlarım?',
    kosulMetni: 'Yayında duyuru olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.duyuruSatiri),
        metin: 'Bir duyuruya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.okumaOzet),
        metin: 'Üstte oran ve kaç hesabın gördüğü yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.okumaGordu),
        metin: '«Gördü»de görenler, en yenisi üstte.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.okumaListe),
        metin: 'Satırda nereden gördüğü ve saati yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.okumaGormedi),
        metin: '«Görmedi»ye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.okumaListe),
        metin: 'Görmeyenler uygulamayı kullananlar diye ayrılır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.okumaArama),
        metin: '«İsimle ara»ya çocuğun adını da yazabilirsin.',
        bilgi: true,
        dokunulur: true,
      ),
    ],
    kural: 'Sayım hesap bazındadır; veli ve çocukları tek hesaptır. '
        'Son 60 günde uygulamayı açmayanlar kullanmayanlar grubundadır.',
  ),
  OgrenmeGorevi(
    id: 'duyuru.kaynak',
    sayfa: OgrenmeSayfasi.duyurular,
    baslik: 'Ana sayfadan açan ile popup\'ta gören farkı ne?',
    kosulMetni: 'Yayında duyuru olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.duyuruSatiri),
        metin: 'Bir duyuruya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.okumaKaynaklar),
        metin: '«Ana sayfadan açan» duyuruyu kartından açandır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.okumaKaynaklar),
        metin: '«Popup\'ta gören» açılışta ekranda görendir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.okumaKaynaklar),
        metin: '«Detayı açan» içeriğe bakmak isteyendir.',
        bilgi: true,
      ),
    ],
    kural: 'Ana sayfadaki duyuru yalnız açılınca, popup ekrana gelince sayılır. '
        'Bu yüzden popup\'lı duyurunun oranı yüksek çıkar.',
  ),
  OgrenmeGorevi(
    id: 'duyuru.icerik',
    sayfa: OgrenmeSayfasi.duyurular,
    baslik: 'Duyurunun içeriğini nasıl okurum?',
    kosulMetni: 'Duyuru olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.duyuruSatiri),
        metin: 'Bir duyuruya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('İçeriği gör'),
        metin: '«İçeriği gör»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.duyuruIcerik),
        metin: 'Başlık, görsel ve metin burada.',
        bilgi: true,
      ),
    ],
    kural: 'İçeriğe bakman okundu sayılmaz; ölçüme karışmaz.',
  ),
  OgrenmeGorevi(
    id: 'duyuru.yonetim',
    sayfa: OgrenmeSayfasi.duyurular,
    baslik: 'Yeni duyuruyu nasıl yayınlar ya da kaldırırım?',
    kosulMetni: 'Duyuru olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.duyuruSatiri),
        metin: 'Yeni duyuru mobilden eklenmez.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.duyuruSatiri),
        metin: 'Bir duyuruya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.okumaWeb),
        metin: 'Sağ üstteki simge web panelini açar.',
        bilgi: true,
      ),
    ],
    kural: 'Oluşturma, düzenleme ve yayından kaldırma web panelindedir. '
        'Mobilde yalnız kimlerin gördüğünü izlersin.',
  ),
];
