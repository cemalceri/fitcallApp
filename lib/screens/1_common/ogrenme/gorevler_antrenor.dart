// lib/screens/1_common/ogrenme/gorevler_antrenor.dart
//
// Antrenör rehberleri. Yazım kuralları gorevler.dart'ta.

import 'package:fitcall/common/constants.dart';
import 'package:fitcall/screens/1_common/ogrenme/gorev_ortak.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';

/// Plan dışı üye ekleme: yoklama penceresinden sonraki ortak adımlar.
const _planDisiAdimlari = [
  OgrenmeAdimi(
    hedef: Secici.metin('Üye'),
    metin: '«Üye»ye dokun.',
  ),
  OgrenmeAdimi(
    hedef: Secici.hedef(Hedef.planDisiUye),
    metin: 'Listeden üyeyi seç.',
  ),
  OgrenmeAdimi(
    hedef: Secici.hedef(Hedef.katilimNot),
    metin: 'Kutuya nedenini yaz.',
    bilgi: true,
    dokunulur: true,
  ),
  OgrenmeAdimi(
    hedef: Secici.hedef(Hedef.katilimNotKaydet),
    metin: '«Kaydet»e dokun.',
  ),
  OgrenmeAdimi(
    hedef: Secici.hedef(Hedef.yoklamaKaydet),
    metin: 'Alttaki «Kaydet»e dokun.',
    kalici: true,
    sonuc: 'yoklaman girilir, ofise haber gider',
  ),
];

const _planDisiKurali = 'Kayıtlı değilse «Misafir»e dokunup adını yaz. '
    'Nota kim olduğunu ve neden geldiğini yaz. '
    'Ücreti yönetim belirler.';

/// Takvim rehberlerinin başı: dersin günü seçili değilse gün şeridiyle başka
/// güne (geçmiş ya da gelecek haftaya) gidilir. Sonraki hedef (ders bloğu)
/// zaten ekrandaysa adım atlanır.
const _gunAdimi = OgrenmeAdimi(
  hedef: Secici.hedef(Hedef.antrenorGunSeridi),
  metin: 'Dersin gününü seç; oklarla haftayı değiştir.',
  bilgi: true,
  dokunulur: true,
  atlanabilir: true,
  yoksa: 'Bu günde uygun ders yok; başka gün seç.',
);

const List<OgrenmeGorevi> antrenorGorevleri = [
  // ----------------------------------------------------------- Ana sayfa
  OgrenmeGorevi(
    id: 'antrenor.anaSayfa',
    sayfa: OgrenmeSayfasi.antrenorAnaSayfa,
    baslik: 'Ana sayfada neler var?',
    kosulMetni: 'Ana sayfa açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorKokpit),
        metin: 'Bugünkü ders, öğrenci ve kalan sayısı burada.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorSonrakiDers),
        metin: 'Sıradaki dersin burada görünür.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorMenuDugmesi),
        metin: 'Soldaki menü yoklama ve hakedişe götürür.',
        bilgi: true,
      ),
      soruIsaretiAdimi,
    ],
    kural: 'Dersler ve yoklamalar alttaki Takvim sekmesinde. '
        'Yoklamasını girmediğin dersleri menüdeki Eksik Yoklamalar toplar.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.menu',
    sayfa: OgrenmeSayfasi.antrenorAnaSayfa,
    baslik: 'Menüde neler var?',
    kosulMetni: 'Ana sayfa açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorMenuDugmesi),
        metin: 'Sol üstteki menü düğmesine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Eksik Yoklamalar'),
        metin: 'Yoklamasız dersler burada toplanır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Ofis Soruyor'),
        metin: 'Ofisin sorduğu ders saatlerine cevap verirsin.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Çalışma Saatlerim'),
        metin: 'Müsaitliğini buradan güncellersin.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Hakediş Saatlerim'),
        metin: 'Aylık hakediş saatlerin burada.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Bildirimler'),
        metin: 'Devir teklifleri burada görünür.',
        bilgi: true,
      ),
    ],
    kural: 'Alttaki sekmeler Ana Sayfa, Takvim, Öğrenciler ve Bilgilerim. '
        'Ayarlar ve Yardım menünün altında.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.eksikUyari',
    sayfa: OgrenmeSayfasi.antrenorAnaSayfa,
    baslik: 'Eksik yoklama uyarısı ne demek?',
    kosulMetni: 'Yoklaması eksik dersin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorEksikUyari),
        metin: 'Uyarı satırına dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.eksikYoklamaDers),
        metin: 'Yoklamasız dersler bu listede toplanır.',
        bilgi: true,
      ),
    ],
    kural: 'Uyarı bugünkü ve son 7 gündeki eksikleri sayar. '
        'Yoklamayı girince ders listeden çıkar.',
  ),

  // --------------------------------------------------------------- Takvim
  OgrenmeGorevi(
    id: 'antrenor.gecmisYoklama',
    sayfa: OgrenmeSayfasi.antrenorTakvim,
    baslik: 'Geçmiş derse yoklamayı nasıl girerim?',
    kosulMetni: 'Takviminde bitmiş bir ders olunca',
    adimlar: [
      _gunAdimi,
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorYoklamasizDers),
        metin: 'Yoklaması girilmemiş bitmiş derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Ders yapıldı, herkes geldi'),
        metin: 'Herkes geldiyse «Ders yapıldı, herkes geldi» kartına dokun.',
        kalici: true,
        sonuc: 'planlı herkes geldi sayılır, yoklaman girilir',
      ),
    ],
    kural: 'Biri gelmediyse «Eksik ya da fazla var»ı seç. '
        'Ders hiç yapılmadıysa «Ders yapılmadı»yı seç. '
        'Ders onaylanana kadar düzeltebilirsin.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.yoklamaDuzelt',
    sayfa: OgrenmeSayfasi.antrenorTakvim,
    baslik: 'Yoklamayı yanlış girdiysem nasıl düzeltirim?',
    kosulMetni: 'Yoklamasını girdiğin bir ders olunca',
    adimlar: [
      _gunAdimi,
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorYoklamaGirilmisDers),
        metin: 'Yoklaması girilmiş derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoklamaKatilimci),
        metin: 'Yanlış işaretleneni tik ya da çarpıyla düzelt.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoklamaKaydet),
        metin: 'Alttaki «Kaydet»e dokun.',
        kalici: true,
        sonuc: 'yoklaman güncellenir',
      ),
    ],
    kural: 'Ders onaylanana kadar düzeltebilirsin. '
        'Onaydan sonra ders kilitlenir.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.kilitliDers',
    sayfa: OgrenmeSayfasi.antrenorTakvim,
    baslik: 'Dersim neden kilitli?',
    kosulMetni: 'Onaylanmış bir ders olunca',
    adimlar: [
      _gunAdimi,
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorKilitliDers),
        metin: 'Onaylanmış bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorYoklamaKilit),
        metin: 'Kilit kutusu değişiklik yapamayacağını söyler.',
        bilgi: true,
      ),
    ],
    kural: 'Ders onaylanınca yoklama değişmez. '
        'Değişiklik için yöneticinle konuş. '
        'Onaylanmış plan dışı kişiyi silemezsin.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.renkler',
    sayfa: OgrenmeSayfasi.antrenorTakvim,
    baslik: 'Ders bloklarındaki yazılar ne demek?',
    kosulMetni: 'Takviminde bitmiş bir ders olunca',
    adimlar: [
      _gunAdimi,
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorBitmisDers),
        metin: 'Bloğun içindeki yazı yoklama durumunu söyler.',
        bilgi: true,
      ),
    ],
    // Kural en çok üç cümle; blokta kısaltılmış "Yön." burada açık yazılır.
    kural: 'Onay Bekliyor: yoklamanı girmedin; '
        'Yönetici Onayı Bekliyor: girdin, yönetici onaylayacak. '
        'Tamamlandı: onaylandı ve kilitlendi; Yapılmadı: yapılmadı girildi. '
        'İptal Edildi: ders iptal oldu.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.katilimcilar',
    sayfa: OgrenmeSayfasi.antrenorTakvim,
    baslik: 'Derse kimlerin geleceğini nerede görürüm?',
    kosulMetni: 'Takviminde öğrencisi olan gelecek bir ders olunca',
    adimlar: [
      _gunAdimi,
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorKatilimciliDers),
        metin: 'Öğrencisi olan gelecek bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorDetayKatilimcilar),
        metin: 'Her öğrencinin cevabı burada yazar.',
        bilgi: true,
      ),
    ],
    kural: 'Cevaplar katılacağını, katılmayacağını ya da henüz cevap '
        'vermediğini gösterir. '
        'Ajanda görünümünde satırın altında adlar yazar.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.planDisi',
    sayfa: OgrenmeSayfasi.antrenorTakvim,
    baslik: 'Derse planda olmayan birini nasıl eklerim?',
    kosulMetni: 'Takviminde bitmiş bir ders olunca',
    adimlar: [
      _gunAdimi,
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorBitmisDers),
        metin: 'Bitmiş bir derse dokun.',
      ),
      // Yoklama önceden girildiyse pencere doğrudan ayrıntıda açılır.
      OgrenmeAdimi(
        hedef: Secici.metin('Eksik ya da fazla var'),
        metin: '«Eksik ya da fazla var»a dokun.',
        atlanabilir: true,
      ),
      ..._planDisiAdimlari,
    ],
    kural: _planDisiKurali,
  ),
  OgrenmeGorevi(
    id: 'antrenor.misafir',
    sayfa: OgrenmeSayfasi.antrenorTakvim,
    baslik: 'Kayıtsız misafiri nasıl eklerim?',
    kosulMetni: 'Takviminde bitmiş bir ders olunca',
    adimlar: [
      _gunAdimi,
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorBitmisDers),
        metin: 'Bitmiş bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Eksik ya da fazla var'),
        metin: '«Eksik ya da fazla var»a dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Misafir'),
        metin: '«Misafir»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorMisafirAd),
        metin: 'Misafirin adını yaz.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Ekle'),
        metin: '«Ekle»ye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoklamaKaydet),
        metin: 'Alttaki «Kaydet»e dokun.',
        kalici: true,
        sonuc: 'yoklaman girilir, misafir kayda geçer',
      ),
    ],
    kural: 'Misafir sisteme kayıtlı olmayan kişidir. '
        'Nota telefonunu ya da kimin misafiri olduğunu yaz. '
        'Ücreti yönetim belirler.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.devir',
    sayfa: OgrenmeSayfasi.antrenorTakvim,
    baslik: 'Dersimi başka hocaya nasıl veririm?',
    kosulMetni: 'Takviminde gelecek bir ders olunca',
    adimlar: [
      _gunAdimi,
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorGelecekDers),
        metin: 'Gelecek bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Devret'),
        metin: '«Devret»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.devirAntrenorKutusu),
        metin: 'Antrenör kutusuna dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.devirAday),
        metin: 'Listeden bir hoca seç.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Devir Talebi Gönder'),
        metin: '«Devir Talebi Gönder»e dokun.',
        kalici: true,
        sonuc: 'seçtiğin hocaya teklif gider',
      ),
    ],
    kural: 'Hoca kabul edene kadar ders sende kalır, yoklamayı sen girersin. '
        'Ders başlayana kadar cevap gelmezse talep düşer. '
        'Ders bloğuna uzun basıp «Dersi devret»i de seçebilirsin.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.devirGeriCek',
    sayfa: OgrenmeSayfasi.antrenorTakvim,
    baslik: 'Devir talebimi nasıl geri çekerim?',
    kosulMetni: 'Devir talebi gönderdiğin bir ders olunca',
    adimlar: [
      _gunAdimi,
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorDevirliDers),
        metin: 'Devir rozetli derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Talebi Gör'),
        metin: '«Talebi Gör»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Talebi Geri Çek'),
        metin: '«Talebi Geri Çek»e dokun.',
        kalici: true,
        sonuc: 'talebin geri çekilir, ders sende kalır',
      ),
    ],
    kural: 'Hoca kabul edene kadar geri çekebilirsin. '
        'Kabul edilince ders ona geçer.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.ajanda',
    sayfa: OgrenmeSayfasi.antrenorTakvim,
    baslik: 'Haftayı liste halinde nasıl görürüm?',
    kosulMetni: 'Takvim açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorGorunumDugmesi),
        metin: 'Üstteki görünüm düğmesine dokun.',
        kalici: true,
        sonuc: 'hafta liste görünümüne geçer, aynı düğme ızgaraya döner',
      ),
    ],
    kural: 'Ajanda haftanın bütün derslerini listeler. '
        'Satırın altında öğrencilerin adları yazar.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.tumProgram',
    sayfa: OgrenmeSayfasi.antrenorTakvim,
    baslik: 'Başka hocaların programına nasıl bakarım?',
    kosulMetni: 'Takvim açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorTumProgramDugmesi),
        metin: 'Üstteki program ikonuna dokun.',
        kalici: true,
        sonuc: 'bütün hocaların haftalık programı açılır',
      ),
    ],
    kural: 'Tüm program salt okunurdur. '
        'Yeni ders için «Ders kayıt talebi»ni kullan.',
  ),

  // ------------------------------------------------------ Eksik yoklamalar
  OgrenmeGorevi(
    id: 'antrenor.hizliYoklama',
    sayfa: OgrenmeSayfasi.antrenorEksikYoklama,
    baslik: 'Herkes geldiyse yoklamayı nasıl girerim?',
    kosulMetni: 'Yoklaması eksik dersin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.eksikYoklamaDers),
        metin: 'Listeden bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Ders yapıldı, herkes geldi'),
        metin: 'Üstteki «Ders yapıldı, herkes geldi» kartına dokun.',
        kalici: true,
        sonuc: 'planlı herkes geldi sayılır, ders listeden çıkar',
      ),
    ],
    kural: 'Kart planlı herkesi katıldı sayar. '
        'Biri gelmediyse «Eksik ya da fazla var»ı seç. '
        'Ders onaylanana kadar düzeltebilirsin.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.eksikYoklama',
    sayfa: OgrenmeSayfasi.antrenorEksikYoklama,
    baslik: 'Biri gelmediyse yoklamayı nasıl girerim?',
    kosulMetni: 'Yoklaması eksik dersin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.eksikYoklamaDers),
        metin: 'Listeden bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Eksik ya da fazla var'),
        metin: '«Eksik ya da fazla var»a dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoklamaKatilimci),
        metin: 'Herkesi tek tek işaretle: gelene tik, gelmeyene çarpı.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoklamaKaydet),
        metin: 'Alttaki «Kaydet»e dokun.',
        kalici: true,
        sonuc: 'yoklaman girilir, ders listeden çıkar',
      ),
    ],
    kural: 'İşaretlemediğin planlı üye kayda girmez. '
        'Hesap senin yoklamana göre yapılır. '
        'Ders onaylanana kadar düzeltebilirsin.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.dersYapilmadi',
    sayfa: OgrenmeSayfasi.antrenorEksikYoklama,
    baslik: 'Ders hiç yapılmadıysa ne yaparım?',
    kosulMetni: 'Yoklaması eksik dersin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.eksikYoklamaDers),
        metin: 'Listeden bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Ders yapılmadı'),
        metin: '«Ders yapılmadı»ya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoklamaNeden),
        metin: '«Neden yapılmadı?» altından birini seç.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yoklamaKaydet),
        metin: '«Kaydet»e dokun.',
        kalici: true,
        sonuc: 'ders yapılmadı sayılır, planlı herkes gelmedi işaretlenir',
      ),
    ],
    kural: 'Seçtiğin nedeni yönetici hakediş kararında görür. '
        'Ders onaylanana kadar düzeltebilirsin.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.eksikPlanDisi',
    sayfa: OgrenmeSayfasi.antrenorEksikYoklama,
    baslik: 'Derse planda olmayan birini nasıl eklerim?',
    kosulMetni: 'Yoklaması eksik dersin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.eksikYoklamaDers),
        metin: 'Listeden bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Eksik ya da fazla var'),
        metin: '«Eksik ya da fazla var»a dokun.',
      ),
      ..._planDisiAdimlari,
    ],
    kural: _planDisiKurali,
  ),

  // --------------------------------------------------------------- Program
  OgrenmeGorevi(
    id: 'antrenor.dersKayitTalebi',
    sayfa: OgrenmeSayfasi.antrenorProgram,
    baslik: 'Programa yeni bir dersi nasıl eklettiririm?',
    kosulMetni: 'Program açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Ders kayıt talebi'),
        metin: 'Alttaki «Ders kayıt talebi»ne dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.talepZamani),
        metin: 'Gün, kort ve saati kontrol et.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.talepAciklama),
        metin: 'Açıklamaya hangi dersin yerine olduğunu yaz.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Talebi gönder'),
        metin: '«Talebi gönder»e dokun.',
        kalici: true,
        sonuc: 'talebin ofise gider',
      ),
    ],
    kural: 'Ofis onaylayınca ders programa eklenir. '
        'Reddederse sana bildirim gelir. '
        'Bekleyen talebine dokunup geri çekebilirsin.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.programDers',
    sayfa: OgrenmeSayfasi.antrenorProgram,
    baslik: 'Programdaki bir dersin ayrıntısını nasıl görürüm?',
    kosulMetni: 'Programda ders olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programGun),
        metin: 'Dersi olan bir güne dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programDers),
        metin: 'Bir ders bloğuna dokun.',
        kalici: true,
        sonuc: 'dersin antrenörü, kişi sayısı ve katılımcıları açılır',
      ),
    ],
    kural: 'Programdaki değişiklikler ofiste yapılır. '
        'Kendi derslerin belirgin görünür.',
  ),

  OgrenmeGorevi(
    id: 'antrenor.talepGeriCek',
    sayfa: OgrenmeSayfasi.antrenorProgram,
    baslik: 'Bekleyen talebimi nasıl geri çekerim?',
    kosulMetni: 'Bekleyen ders kayıt talebin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programTalepGunu),
        metin: 'Talebi olan güne dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programTalep),
        metin: 'Bekleyen talep kutusuna dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Talebi geri çek'),
        metin: '«Talebi geri çek»e dokun.',
        kalici: true,
        sonuc: 'talebin geri çekilir',
      ),
    ],
    kural: 'Ofis cevaplamadan geri çekebilirsin. '
        'Cevaplanan talep listeden kalkar.',
  ),

  // --------------------------------------------------------------- Hakediş
  OgrenmeGorevi(
    id: 'antrenor.hakedisOku',
    sayfa: OgrenmeSayfasi.antrenorHakedis,
    baslik: 'Hakediş saatlerimi nasıl okurum?',
    kosulMetni: 'Bitmiş dersin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisAy),
        metin: 'Izgarada dersi olan bir aya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorHakedisBasligi),
        metin: 'Başlıkta o ayın ders ve saati yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorHakedisAlacak),
        metin: 'Bu kutu hakedişine girecek saattir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisBekliyor),
        metin: 'Bu kutu onay bekleyen derslerdir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorHakedisOran),
        metin: 'Çubuk bu saatlerin oranını gösterir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorHakedisRol),
        metin: 'Ana ve yardımcı dersler ayrı sayılır.',
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
    kural: 'Ders onaylanana kadar «Bekliyor»da kalır. '
        'Aynı saatteki dersler bir kez sayılır.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.hakedisDisi',
    sayfa: OgrenmeSayfasi.antrenorHakedis,
    baslik: 'Bir ders neden hakediş dışı kaldı?',
    kosulMetni: 'Hakediş dışı dersin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisAy),
        metin: 'Izgarada dersi olan bir aya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorHakedisDisiGrup),
        metin: '«Hakediş dışı» satırına dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.hakedisDers),
        metin: 'Kartta dışarıda kalma nedeni yazar.',
        bilgi: true,
      ),
    ],
    kural: 'İptal edilen ve yapılmayan dersler hakedişe girmez. '
        'Yönetici hakediş verdiyse kartta yazar.',
  ),

  // ------------------------------------------------------ Çalışma saatleri
  OgrenmeGorevi(
    id: 'antrenor.calismaSaati',
    sayfa: OgrenmeSayfasi.antrenorCalismaSaatleri,
    baslik: 'Çalışma saatlerimi nasıl güncellerim?',
    kosulMetni: 'Çalışma saatlerin açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorCalismaNotu),
        metin: 'Bu saatler kulübe bildirdiğin müsaitliktir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorCalismaAnahtar),
        metin: 'Çalışmadığın günün anahtarını kapat.',
        bilgi: true,
        dokunulur: true,
        // Saat yalnız açık günde çıkar; hepsi kapatıldıysa sonraki adım yok.
        yoksa: 'Önce bir günün anahtarını aç.',
      ),
      // Okuma adımı: parlayan saate dokunuş rehberde geçmez, yazı da
      // dokunmayı istemez.
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorCalismaSaat),
        metin: 'Saate dokunarak başlangıç ve bitişi seçersin.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kaydet'),
        metin: 'Alttaki «Kaydet»e dokun.',
        kalici: true,
        sonuc: 'müsaitliğin kulübe bildirilir',
      ),
    ],
    kural: 'Bitiş saati başlangıçtan sonra olmalı. '
        'Yönetici bu saatleri program yaparken görür. '
        'Bir güne tek aralık girilir.',
  ),

  // ------------------------------------------------------------ Öğrenciler
  OgrenmeGorevi(
    id: 'antrenor.ogrenciDetay',
    sayfa: OgrenmeSayfasi.antrenorOgrenciler,
    baslik: 'Öğrencimin durumunu nasıl görürüm?',
    kosulMetni: 'Öğrenci listende öğrencin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorOgrenciSatiri),
        metin: 'Bir öğrenciye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorOgrenciKatilim),
        metin: 'Son günlerdeki katılım oranı burada.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorOgrenciIletisim),
        metin: 'Anne, baba ve acil durum telefonları burada.',
        bilgi: true,
      ),
    ],
    kural: 'Katılım oranı yalnız yoklaması girilen dersleri sayar. '
        'Ara ve WhatsApp düğmeleri telefon uygulamasını açar.',
  ),
  OgrenmeGorevi(
    id: 'antrenor.ogrenciAra',
    sayfa: OgrenmeSayfasi.antrenorOgrenciler,
    baslik: 'Öğrencimi nasıl ararım?',
    kosulMetni: 'Öğrenci listende öğrencin olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorOgrenciArama),
        metin: 'Kutuya öğrencinin adını yaz.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorOgrenciSeviye),
        metin: 'Seviye çiplerinden birine dokun.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorOgrenciSayilar),
        metin: 'Kartlar seviyelere göre öğrenci sayısıdır.',
        bilgi: true,
      ),
    ],
    kural: 'Filtreyi kaldırmak için «Tümü»ne dokun. '
        'Listeyi aşağı çekerek yenilersin.',
  ),

  // ------------------------------------------------------------ Bildirimler
  OgrenmeGorevi(
    id: 'antrenor.devirTeklifi',
    sayfa: OgrenmeSayfasi.bildirimler,
    roller: {Roller.antrenor},
    baslik: 'Bana gelen devir teklifini nasıl yanıtlarım?',
    kosulMetni: 'Sana devir teklifi gelince',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.antrenorBildirimDevir),
        metin: 'Devir teklifli bildirime dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kabul Et'),
        metin: '«Kabul Et»e dokun.',
        kalici: true,
        sonuc: 'ders sana geçer, takvimine eklenir',
      ),
    ],
    kural: '«Reddet»e basarsan isteğe bağlı neden yazarsın. '
        'Ders başlayınca teklif düşer. '
        'Teklifi takvimden değil buradan yanıtlarsın.',
  ),
];
