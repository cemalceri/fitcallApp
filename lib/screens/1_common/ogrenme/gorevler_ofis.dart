// lib/screens/1_common/ogrenme/gorevler_ofis.dart
//
// Ofis (ön büro) rehberleri. Yazım kuralları gorevler.dart'ta.

import 'package:fitcall/screens/1_common/ogrenme/gorev_ortak.dart';
import 'package:fitcall/screens/1_common/ogrenme/hedefler.dart';
import 'package:fitcall/screens/1_common/ogrenme/ogrenme_gorevi.dart';

const List<OgrenmeGorevi> ofisGorevleri = [
  OgrenmeGorevi(
    id: 'ofis.anaSayfa',
    sayfa: OgrenmeSayfasi.ofisAnaSayfa,
    baslik: 'Ana sayfadaki işler ne anlama geliyor?',
    kosulMetni: 'Bekleyen iş olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisBugun),
        metin: 'Üstteki kart bugünkü dersleri gösterir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Ders onayı'),
        metin: '«Ders onayı»: biten dersler kararını bekler.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Ders kayıt talepleri'),
        metin: '«Ders kayıt talepleri»: hocanın eklenmesini istediği dersler.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Plan dışı / misafir kararı'),
        metin: '«Plan dışı / misafir kararı»: sonradan eklenenin ücreti.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Katılım cevabı bekleyenler'),
        metin: '«Katılım cevabı bekleyenler»: bugün ve yarın cevapsızlar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisZil),
        metin: 'Yeni bildirimler sağ üstteki zilde.',
        bilgi: true,
      ),
      soruIsaretiAdimi,
    ],
    kural: 'Satıra dokununca o iş açılır. Diğer ekranlar alttaki sekmelerde.',
  ),
  OgrenmeGorevi(
    id: 'ofis.iptal',
    sayfa: OgrenmeSayfasi.ofisProgram,
    baslik: 'Bir dersi nasıl iptal ederim?',
    kosulMetni: 'Programda gelecek bir ders olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programGun),
        metin: 'Dersi olan bir güne dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programDers),
        metin: 'İptal edilecek derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Dersi iptal et'),
        metin: '«Dersi iptal et»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.iptalSebebi),
        metin: '«İptal sebebi»nden birini seç.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.iptalIslemSekli),
        metin: '«İşlem şekli»ni oku, gerekirse değiştir.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.iptalOnay),
        metin: '«Dersi iptal et»e dokun.',
        kalici: true,
        sonuc: 'ders iptal olur, programda kalır',
      ),
    ],
    kural: '«Standart»ta 24 saat kuralı işler; diğer seçenek dersin türüne '
        'göredir. Yanlış iptali «İptali geri al» ile düzeltirsin.',
  ),
  OgrenmeGorevi(
    id: 'ofis.dersOnay',
    sayfa: OgrenmeSayfasi.ofisDersler,
    baslik: 'Biten bir dersi nasıl onaylarım?',
    kosulMetni: 'Onay bekleyen ders olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisOnayDers),
        metin: 'Onay bekleyen bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisAntrenorBildirimi),
        metin: 'Önce hocanın ne dediğini oku.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Yapıldı'),
        metin: '«Yapıldı»ya dokun.',
        kalici: true,
        sonuc: 'ders yapıldı sayılır, onay listesinden çıkar',
      ),
    ],
    kural: 'Yanlış verdiysen «Kararı kaldır» ile geri alırsın. '
        'Hocanın yapıldı dediklerini «Hepsini onayla» tek seferde onaylar.',
  ),
  OgrenmeGorevi(
    id: 'ofis.katilacak',
    sayfa: OgrenmeSayfasi.ofisDersler,
    baslik: 'Üye geleceğini söylerse nasıl işaretlerim?',
    kosulMetni: 'Cevap bekleyen üye olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisCevapDers),
        metin: 'Cevap bekleyen bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisKatilacak),
        metin: 'Üyenin satırında «Katılacak»a dokun.',
        kalici: true,
        sonuc: 'üye katılacak diye işaretlenir',
      ),
    ],
    kural: 'Yalnız üye sana geleceğini söylediyse işaretle. '
        'Cevap vermediyse «Hatırlat» yeniden bildirim gönderir.',
  ),
  OgrenmeGorevi(
    id: 'ofis.talepKayit',
    sayfa: OgrenmeSayfasi.ofisDersKayitTalepleri,
    baslik: 'Hocanın ders kayıt talebini nasıl programa eklerim?',
    kosulMetni: 'Bekleyen kayıt talebi olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Kayıt oluştur'),
        metin: 'Bir talepte «Kayıt oluştur»a dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.formTalepNotu),
        metin: 'Üstteki hoca notunu oku.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.formUrun),
        metin: '«Ürün»den dersin türünü seç.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.formUyeler),
        metin: '«Üye seçiniz»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeSecimi),
        metin: 'Üyeleri işaretle, sonra «Onayla»ya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kaydet'),
        metin: '«Kaydet»e dokun.',
        kalici: true,
        sonuc: 'ders programa eklenir, hocaya haber gider',
      ),
    ],
    kural: 'Gün, saat, kort ve hoca talepten dolu gelir. '
        'Uymuyorsa «Reddet»e bas, nedenini yaz; hocaya haber gider.',
  ),
  OgrenmeGorevi(
    id: 'ofis.borcYaz',
    sayfa: OgrenmeSayfasi.ofisPlanDisi,
    baslik: 'Plan dışı gelen kişiye nasıl borç yazarım?',
    kosulMetni: 'Karar bekleyen kişi olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.planDisiKisi),
        metin: 'Listeden bir kişiye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Borç yaz'),
        metin: 'Üstte «Borç yaz» seçili olsun.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.planDisiUstlenen),
        metin: '«Ücreti üstlenen»i kontrol et.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.planDisiTutar),
        metin: '«Tutar» kutusuna tutarı yaz.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.planDisiAciklama),
        metin: '«Açıklama»ya hangi ders olduğunu yaz.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kararı kaydet'),
        metin: '«Kararı kaydet»e dokun.',
        kalici: true,
        sonuc: 'tutar, seçtiğin kişinin hesabına borç yazılır',
      ),
    ],
    kural: 'Misafirde ilk sırada «Misafir havuzu» gelir. '
        'Açıklamadan borcun hangi dersten geldiği anlaşılır.',
  ),
  // ------------------------------------------------------- Ana sayfa
  OgrenmeGorevi(
    id: 'ofis.onayGunleri',
    sayfa: OgrenmeSayfasi.ofisAnaSayfa,
    baslik: 'Onay bekleyen dersleri nasıl bulup onaylarım?',
    kosulMetni: 'Onay bekleyen ders olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Ders onayı'),
        metin: '«Ders onayı»na dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisOnayGunu),
        metin: 'Listeden bir güne dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisOnayDers),
        metin: 'Onay bekleyen bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisAntrenorBildirimi),
        metin: 'Önce hocanın ne dediğini oku.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Yapıldı'),
        metin: '«Yapıldı»ya dokun.',
        kalici: true,
        sonuc: 'ders yapıldı sayılır, onay listesinden çıkar',
      ),
    ],
    kural: 'En yeni gün üstte durur. '
        'Hocanın yapıldı dediklerini «Hepsini onayla» tek seferde onaylar. '
        'Eski dersler web panelinde.',
  ),
  OgrenmeGorevi(
    id: 'ofis.qrIslem',
    sayfa: OgrenmeSayfasi.ofisAnaSayfa,
    baslik: 'Kapıda QR kodu nasıl doğrularım?',
    kosulMetni: 'Ana sayfa açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('QR İşlem'),
        metin: 'Alttaki ortadaki «QR İşlem»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('QR Doğrula'),
        metin: '«QR Doğrula»ya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Tara'),
        metin: '«Tara»ya dokun.',
        kalici: true,
        sonuc: 'kamera açılır, kodu okutunca sonuç çıkar',
      ),
    ],
    kural: 'Sonuç kartında ne yapacağın yazar. '
        '«Sonrakini tara» sıradaki kişiye geçer. '
        'Kamera izni gerekir.',
  ),
  OgrenmeGorevi(
    id: 'ofis.gezinme',
    sayfa: OgrenmeSayfasi.ofisAnaSayfa,
    baslik: 'Ekranlar arasında nasıl gezinirim?',
    kosulMetni: 'Ana sayfa açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisAltBar),
        metin: 'Alttaki sekmelerle ekranlar arasında gezinirsin.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisZil),
        metin: 'Yeni bildirimler sağ üstteki zilde.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisMenu),
        metin: 'Soldaki menü düğmesine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Plan Dışı Kararlar'),
        metin: '«Plan Dışı Kararlar»: karar bekleyen kişiler.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Talepler'),
        metin: '«Talepler»: üye ve hoca ders talepleri.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Duyurular'),
        metin: '«Duyurular»: yayınlananlar ve kimlerin gördüğü.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('QR Doğrula'),
        metin: '«QR Doğrula»: kapıdaki kodu okutursun.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('QR Oluştur'),
        metin: '«QR Oluştur»: kendi ya da misafir kodun.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Bildirimler'),
        metin: '«Bildirimler»: gelen bildirimlerin listesi.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Yardım'),
        metin: '«Yardım»: sık sorulan sorular.',
        bilgi: true,
      ),
    ],
    kural: 'Bekleyen talepler Ana Sayfa\'daki satırda da görünür.',
  ),
  OgrenmeGorevi(
    id: 'ofis.teyitGunleri',
    sayfa: OgrenmeSayfasi.ofisAnaSayfa,
    baslik: 'Cevap vermeyen üyeleri nasıl bulurum?',
    kosulMetni: 'Cevap bekleyen üye olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Katılım cevabı bekleyenler'),
        metin: '«Katılım cevabı bekleyenler»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisCevapDers),
        metin: 'Cevap bekleyen bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Hatırlat'),
        metin: 'Üyenin satırında «Hatırlat»a dokun.',
        kalici: true,
        sonuc: 'üyenin uygulamasına yeniden katılım bildirimi gider',
      ),
    ],
    kural: 'Üye geleceğini söylediyse «Katılacak» kullan. '
        'Bugün ve yarının cevapsızları sayılır.',
  ),
  OgrenmeGorevi(
    id: 'ofis.profilGecis',
    sayfa: OgrenmeSayfasi.ofisAnaSayfa,
    baslik: 'Yönetici profiline nasıl geçerim?',
    kosulMetni: 'Hesabına birden çok profil bağlı olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.profilDegistir),
        metin: 'Üstteki çift oklu düğmeye dokun.',
        kalici: true,
        sonuc: 'profil seçme ekranı açılır',
      ),
    ],
    kural: 'Her profil kendi oturumuyla açılır. '
        'Yönetici profilinde ders açıp iptal edemezsin.',
  ),

  // --------------------------------------------------------- Program
  OgrenmeGorevi(
    id: 'ofis.programOku',
    sayfa: OgrenmeSayfasi.ofisProgram,
    baslik: 'Program ekranını nasıl okurum?',
    kosulMetni: 'Program açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programGunSeridi),
        metin: 'Üstteki şeritten günü seçersin.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programBaslik),
        metin: 'Oklar haftayı, «Bugün» bugünü açar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programIzgara),
        metin: 'Sütunlar kortları, satırlar saatleri gösterir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programIzgara),
        metin: 'Dolu kutu o saatteki derstir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programIzgara),
        metin: 'İptal edilen dersler rozetiyle yerinde durur.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programIzgara),
        metin: 'Kesik çizgili kutu hocanın ders talebidir.',
        bilgi: true,
      ),
    ],
    kural: 'Kort sayısı sığmazsa ızgarayı yana kaydır. '
        'Boş saate dokununca yeni ders formu açılır. '
        'Derse dokununca işlem sayfası açılır.',
  ),
  OgrenmeGorevi(
    id: 'ofis.yeniDers',
    sayfa: OgrenmeSayfasi.ofisProgram,
    baslik: 'Programa yeni bir dersi nasıl eklerim?',
    kosulMetni: 'Seçili günde boş saat olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programBosSaat),
        metin: 'Boş bir saate dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.formZaman),
        metin: 'Tarih ve saatleri kontrol et.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.formKort),
        metin: 'Kortu kontrol et.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.formUrun),
        metin: '«Ürün»den dersin türünü seç.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.formAntrenor),
        metin: '«Antrenör»den hocayı seç.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.formUyeler),
        metin: '«Üye seçiniz»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeSecimi),
        metin: 'Üyeleri işaretle, sonra «Onayla»ya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kaydet'),
        metin: '«Kaydet»e dokun.',
        kalici: true,
        sonuc: 'ders programa eklenir',
      ),
    ],
    kural: 'Saatler 30 dakikanın katları olmalı. '
        'Çakışma ve kapasiteyi sunucu denetler.',
  ),
  OgrenmeGorevi(
    id: 'ofis.dersDuzenle',
    sayfa: OgrenmeSayfasi.ofisProgram,
    baslik: 'Bir dersin saatini ya da üyelerini nasıl değiştiririm?',
    kosulMetni: 'Programda gelecek bir ders olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programGun),
        metin: 'Dersi olan bir güne dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programDers),
        metin: 'Düzenlenecek derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Dersi düzenle'),
        metin: '«Dersi düzenle»ye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.formZaman),
        metin: 'Saati ya da tarihi değiştirebilirsin.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.formUyeler),
        metin: 'Katılımcıları bu kutudan değiştirirsin.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Güncelle'),
        metin: '«Güncelle»ye dokun.',
        kalici: true,
        sonuc: 'ders yeni bilgilerle güncellenir',
      ),
    ],
    kural: 'Geçmişte kalan ya da onaylanmış dersi sunucu değiştirmeyebilir. '
        'Sabit plandan gelen derste ürün değişmez. '
        'Hocayı «Antrenör» kutusundan değiştirirsin.',
  ),
  OgrenmeGorevi(
    id: 'ofis.iptalGeriAl',
    sayfa: OgrenmeSayfasi.ofisProgram,
    baslik: 'Yanlış iptal ettiğim dersi nasıl geri alırım?',
    kosulMetni: 'Programda iptal edilmiş ders olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programIptalGun),
        metin: 'İptal edilmiş dersi olan güne dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programIptalDers),
        metin: 'İptal edilmiş derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programIptalKunyesi),
        metin: 'Kimin, neden iptal ettiği burada yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('İptali geri al'),
        metin: '«İptali geri al»a dokun.',
        kalici: true,
        sonuc: 'ders yeniden aktif olur',
      ),
    ],
    kural: 'Son 24 saatteki iptalde paket hakkı ya da borç da geri döner. '
        'Telafi hakkı kullanılmışsa uyarı çıkar; okumadan geçme. '
        'Ders yeniden onay bekler.',
  ),
  OgrenmeGorevi(
    id: 'ofis.dersSil',
    sayfa: OgrenmeSayfasi.ofisProgram,
    baslik: 'Bir dersi kalıcı olarak nasıl silerim?',
    kosulMetni: 'Programda gelecek bir ders olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programGun),
        metin: 'Dersi olan bir güne dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programDers),
        metin: 'Silinecek derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kalıcı olarak sil'),
        metin: '«Kalıcı olarak sil»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.silEtkisi),
        metin: 'Silinecek kayıtların sayısını oku.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kalıcı olarak sil'),
        metin: 'Pencerede «Kalıcı olarak sil»e dokun.',
        kalici: true,
        sonuc: 'ders ve bağlı her kayıt silinir',
      ),
    ],
    kural: 'Silinen ders geri gelmez; üyenin telafi hakları da gider. '
        'Kaydı tutmak istiyorsan «Dersi iptal et» kullan. '
        'Yanlışlıkla açılmış dersler için silme uygundur.',
  ),
  OgrenmeGorevi(
    id: 'ofis.programTalep',
    sayfa: OgrenmeSayfasi.ofisProgram,
    baslik: 'Programdaki kesik çizgili talebi nasıl işlerim?',
    kosulMetni: 'Programda bekleyen talep olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programTalepGunu),
        metin: 'Talebi olan güne dokun.',
        atlanabilir: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programTalep),
        metin: 'Kesik çizgili talebe dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kayıt oluştur'),
        metin: '«Kayıt oluştur»a dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.formTalepNotu),
        metin: 'Üstteki hoca notunu oku.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.formUrun),
        metin: '«Ürün»den dersin türünü seç.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.formUyeler),
        metin: '«Üye seçiniz»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.uyeSecimi),
        metin: 'Üyeleri işaretle, sonra «Onayla»ya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kaydet'),
        metin: '«Kaydet»e dokun.',
        kalici: true,
        sonuc: 'ders programa eklenir, hocaya haber gider',
      ),
    ],
    kural: 'Gün, saat, kort ve hoca talepten dolu gelir. '
        'Uymuyorsa «Reddet»e bas, nedenini yaz; hocaya haber gider.',
  ),

  // ---------------------------------------------------------- Dersler
  OgrenmeGorevi(
    id: 'ofis.dersGunu',
    sayfa: OgrenmeSayfasi.ofisDersler,
    baslik: 'Başka günün derslerini nasıl bulurum?',
    kosulMetni: 'Dersler açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.dersGunSecici),
        metin: 'Oklar günü, ortadaki kutu takvimi değiştirir.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Bugün'),
        metin: '«Bugün» seni bugüne döndürür.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.dersSuzgec),
        metin: 'Alttaki seçeneklerle bekleyen dersleri ayır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.dersSatiri),
        metin: 'Satırın sağındaki etiket dersin durumunu söyler.',
        bilgi: true,
      ),
    ],
    kural: 'Satıra dokununca dersin işlem sayfası açılır. '
        '«Hepsini onayla» kartı varsa üstte çıkar. '
        'Aşağı çekince liste yenilenir.',
  ),
  OgrenmeGorevi(
    id: 'ofis.hepsiniOnayla',
    sayfa: OgrenmeSayfasi.ofisDersler,
    baslik: 'Hocanın yapıldı dediği dersleri tek seferde nasıl onaylarım?',
    kosulMetni: 'Hocanın yapıldı dediği ders olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.dersTopluOnay),
        metin: 'Kartta hocanın «yapıldı» dediği derslerin sayısı yazar.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Hepsini onayla'),
        metin: '«Hepsini onayla»ya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Onayla'),
        metin: 'Pencerede «Onayla»ya dokun.',
        kalici: true,
        sonuc: 'hocanın yapıldı dediği dersler onaylanır',
      ),
    ],
    kural: 'Hocanın yapılmadı dediği ya da bildirmediği derslere dokunulmaz. '
        'Onay yalnız seçili günün derslerini etkiler.',
  ),
  OgrenmeGorevi(
    id: 'ofis.dersYapilmadi',
    sayfa: OgrenmeSayfasi.ofisDersler,
    baslik: 'Yapılmayan dersi nasıl işaretlerim?',
    kosulMetni: 'Onay bekleyen ders olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisOnayDers),
        metin: 'Onay bekleyen bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisAntrenorBildirimi),
        metin: 'Önce hocanın ne dediğini oku.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Yapılmadı'),
        metin: '«Yapılmadı»ya dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.yapilmadiNeden),
        metin: 'İstersen nedenlerden birini seç.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Yapılmadı'),
        metin: 'Pencerede «Yapılmadı»ya dokun.',
        kalici: true,
        sonuc: 'ders yapılmadı sayılır, plan dışı kararlar geri alınır',
      ),
    ],
    kural: 'Bu dersteki plan dışı / misafir kararları da geri alınır. '
        'Yanlışsa «Kararı kaldır» ile geri dönersin.',
  ),
  OgrenmeGorevi(
    id: 'ofis.hatirlat',
    sayfa: OgrenmeSayfasi.ofisDersler,
    baslik: 'Cevap vermeyen üyeye nasıl hatırlatma gönderirim?',
    kosulMetni: 'Cevap bekleyen üye olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisCevapDers),
        metin: 'Cevap bekleyen bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Hatırlat'),
        metin: 'Üyenin satırında «Hatırlat»a dokun.',
        kalici: true,
        sonuc: 'üyenin uygulamasına yeniden katılım bildirimi gider',
      ),
    ],
    kural: '«Hatırlat» yalnız cevap vermemiş üyede çıkar. '
        'Üye geleceğini söylediyse «Katılacak» kullan. '
        'Başlamış derste ikisi de çıkmaz.',
  ),
  OgrenmeGorevi(
    id: 'ofis.kararKaldir',
    sayfa: OgrenmeSayfasi.ofisDersler,
    baslik: 'Yanlış verdiğim ders kararını nasıl geri alırım?',
    kosulMetni: 'Karar verilmiş ders olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisKararliDers),
        metin: 'Karar verilmiş bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kararı kaldır'),
        metin: '«Kararı kaldır»a dokun.',
        kalici: true,
        sonuc: 'ders yeniden onay bekleyenlere döner',
      ),
    ],
    kural: 'Ders yeniden «Onay bekleyen» listesine düşer. '
        'Sonra «Yapıldı» ya da «Yapılmadı» diyebilirsin.',
  ),
  OgrenmeGorevi(
    id: 'ofis.hakedis',
    sayfa: OgrenmeSayfasi.ofisDersler,
    baslik: 'Antrenörün hakediş işaretini nasıl değiştiririm?',
    kosulMetni: 'Onay bekleyen ders olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisOnayDers),
        metin: 'Onay bekleyen bir derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisHakedis),
        metin: 'Antrenörün bu dersten hakediş alıp almayacağı.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Alır'),
        metin: '«Alır» ya da «Almaz»a dokun.',
        kalici: true,
        sonuc: 'antrenörün hakedişi buna göre işaretlenir',
      ),
    ],
    kural: 'Tutar görünmez; yalnız karar verilir. '
        'Seçili olana yeniden dokunursan karar kalkar. '
        'Özel durum yoksa değiştirme.',
  ),
  OgrenmeGorevi(
    id: 'ofis.paketDusum',
    sayfa: OgrenmeSayfasi.ofisDersler,
    baslik: 'Katılan üyenin paketinden ders hakkını nasıl düşerim?',
    kosulMetni: 'Bitmiş bir ders olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisPaketDusumDers),
        metin: 'Paketten düşülecek üyesi olan derse dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Paketten düş'),
        metin: 'Üyenin satırında «Paketten düş»e dokun.',
        kalici: true,
        sonuc: 'üyenin paketinden bir ders hakkı düşer',
      ),
    ],
    kural: '«Paketten düş» yalnız bitmiş derste ve hakkı düşülebilen üyede '
        'çıkar. Yanlışsa «Düşümü geri al» kullan.',
  ),

  // ---------------------------------------------------------- Talepler
  OgrenmeGorevi(
    id: 'ofis.talepRed',
    sayfa: OgrenmeSayfasi.ofisDersKayitTalepleri,
    baslik: 'Uygun olmayan ders kayıt talebini nasıl reddederim?',
    kosulMetni: 'Bekleyen kayıt talebi olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Reddet'),
        metin: 'Bir talepte «Reddet»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.talepRedNedeni),
        metin: 'Red nedenini kutuya yaz.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Reddet'),
        metin: 'Pencerede «Reddet»e dokun.',
        kalici: true,
        sonuc: 'talep kapanır, hocaya neden bildirimle gider',
      ),
    ],
    kural: 'Red nedeni zorunlu; hoca bildirimle görür. '
        'Uygunsa «Kayıt oluştur» kullan.',
  ),
  OgrenmeGorevi(
    id: 'ofis.talepProgramda',
    sayfa: OgrenmeSayfasi.ofisDersKayitTalepleri,
    baslik: 'Talebin programdaki yerini nasıl görürüm?',
    kosulMetni: 'Bekleyen kayıt talebi olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Programda göster'),
        metin: 'Bir talepte «Programda göster»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.programTalep),
        metin: 'Kesik çizgili kutu talebin yeridir.',
        bilgi: true,
      ),
    ],
    kural: 'Çakışma varsa talebi programda görürsün. '
        'Kutuya dokunup kaydı oluşturabilirsin.',
  ),

  OgrenmeGorevi(
    id: 'ofis.uyeTalepOneri',
    sayfa: OgrenmeSayfasi.ofisDersKayitTalepleri,
    baslik: 'Üyeye başka saat nasıl öneririm?',
    kosulMetni: 'Öneri yapılabilen üye talebi olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisTalepOnerilebilir),
        metin: 'Bir üye talebine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Değişiklik öner'),
        metin: '«Değişiklik öner»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisOneriZamani),
        metin: 'Yeni günü ve saati seç.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisOneriNotu),
        metin: 'Üyeye kısa bir not yaz.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Üyeye gönder'),
        metin: '«Üyeye gönder»e dokun.',
        kalici: true,
        sonuc: 'öneri üyeye gider, cevabını bekler',
      ),
    ],
    kural: 'Üye son cevap saatine kadar cevap vermezse talep kapanır. '
        '«Üye telefonda onayladı» işaretlersen ders hemen kaydedilir.',
  ),
  OgrenmeGorevi(
    id: 'ofis.uyeTalepKayit',
    sayfa: OgrenmeSayfasi.ofisDersKayitTalepleri,
    baslik: 'Üyenin talebini nasıl programa eklerim?',
    kosulMetni: 'Kaydedilebilen üye talebi olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisTalepKaydedilir),
        metin: 'Bir üye talebine dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kayıt oluştur'),
        metin: '«Kayıt oluştur»a dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kaydet'),
        metin: '«Kaydet»e dokun.',
        kalici: true,
        sonuc: 'ders programa eklenir, üyeye bildirim gider',
      ),
    ],
    kural: 'Hocalı talepte önce hocanın onayını al: «Hocaya sor» ya da '
        '«Telefonla onay aldım».',
  ),

  // ------------------------------------------------------- Plan dışı
  OgrenmeGorevi(
    id: 'ofis.kararSecimi',
    sayfa: OgrenmeSayfasi.ofisPlanDisi,
    baslik: 'Plan dışı kişi için hangi kararı seçmeliyim?',
    kosulMetni: 'Karar bekleyen kişi olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.planDisiKisi),
        metin: 'Listeden bir kişiye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Borç yaz'),
        metin: '«Borç yaz»: tutar, ücreti üstlenenin hesabına yazılır.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Paketten'),
        metin: '«Paketten»: seçilen kişinin paketinden bir hak düşer.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Ücretsiz'),
        metin: '«Ücretsiz»: kimseye borç ya da düşüm yazılmaz.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.planDisiAciklama),
        metin: 'Her kararda açıklama zorunlu.',
        bilgi: true,
      ),
    ],
    kural: 'Misafirden ödeme alma ve üyeye aktarma web panelinde. '
        'Tutar yalnız «Borç yaz»da çıkar.',
  ),
  OgrenmeGorevi(
    id: 'ofis.paketten',
    sayfa: OgrenmeSayfasi.ofisPlanDisi,
    baslik: 'Plan dışı kişiyi paketten nasıl düşerim?',
    kosulMetni: 'Aktif paketi olan kişi olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.planDisiKisi),
        metin: 'Listeden bir kişiye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Paketten'),
        metin: '«Paketten»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.planDisiUstlenen),
        metin: '«Ücreti üstlenen»i kontrol et.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.planDisiPaket),
        metin: '«Paket» kutusundan paketi seç.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.planDisiAciklama),
        metin: '«Açıklama»ya hangi ders olduğunu yaz.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kararı kaydet'),
        metin: '«Kararı kaydet»e dokun.',
        kalici: true,
        sonuc: 'seçilen paketten bir hak düşer',
      ),
    ],
    kural: 'Paket, ücreti üstlenen kişiye ait olmalı. '
        'Aktif paketi yoksa başka kişi seç ya da «Borç yaz».',
  ),
  OgrenmeGorevi(
    id: 'ofis.ucretsiz',
    sayfa: OgrenmeSayfasi.ofisPlanDisi,
    baslik: 'Plan dışı kişiyi ücretsiz nasıl kaydederim?',
    kosulMetni: 'Karar bekleyen kişi olunca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.planDisiKisi),
        metin: 'Listeden bir kişiye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Ücretsiz'),
        metin: '«Ücretsiz»e dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.planDisiAciklama),
        metin: '«Açıklama»ya nedenini yaz.',
        bilgi: true,
        dokunulur: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.metin('Kararı kaydet'),
        metin: '«Kararı kaydet»e dokun.',
        kalici: true,
        sonuc: 'kimseye ücret yazılmadan karar kaydedilir',
      ),
    ],
    kural: 'Deneme dersi gibi ücretsiz durumlarda kullan. '
        'Açıklama yine zorunlu.',
  ),

  // ----------------------------------------------------------- Üyeler
  OgrenmeGorevi(
    id: 'ofis.uyeBul',
    sayfa: OgrenmeSayfasi.ofisUyeler,
    baslik: 'Bir üyeyi nasıl bulurum?',
    kosulMetni: 'Listede üye olunca',
    // Arama ve süzgeç yalnız gösterilir: denerken liste boşalırsa (eşleşmeyen
    // arama, pasif üyesi olmayan süzgeç) son adımın satırı kalmıyordu.
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisUyeArama),
        metin: 'İsim, telefon ya da üye no ile ararsın.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisUyeFiltre),
        metin: 'Aramanın altında «Aktif» ya da «Pasif» seçersin.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisUyeSatiri),
        metin: 'Listeden bir üyeye dokun.',
      ),
    ],
    kural: 'Liste ada göre sıralı, 20\'şer gelir. '
        'Satırın sağında son ders tarihi yazar. '
        'Satırı yana kaydırınca «Ara» ve «WhatsApp» çıkar.',
  ),
  OgrenmeGorevi(
    id: 'ofis.uyeKarti',
    sayfa: OgrenmeSayfasi.ofisUyeler,
    baslik: 'Üyenin paketini ve derslerini nasıl görürüm?',
    kosulMetni: 'Üye listesi açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisUyeSatiri),
        metin: 'Listeden bir üyeye dokun.',
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisUyeBilgi),
        metin: 'İletişim, seviye ve sorumlu hoca burada.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisUyePaketler),
        metin: 'Paketleri ve kalan haklar burada.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisUyeYaklasan),
        metin: 'Yaklaşan dersleri burada görürsün.',
        bilgi: true,
      ),
      OgrenmeAdimi(
        hedef: Secici.hedef(Hedef.ofisUyeGecmis),
        metin: 'Geçmiş dersler de altında.',
        bilgi: true,
      ),
    ],
    kural: 'Bakiye, borç ve özel bilgiler ofis profilinde görünmez. '
        '«Ara» ve «WhatsApp» üstteki düğmelerde.',
  ),

  // ---------------------------------------------------------- QR Doğrula
  OgrenmeGorevi(
    id: 'qr.dogrula',
    sayfa: OgrenmeSayfasi.qrDogrula,
    baslik: 'Gelen kodu nasıl doğrularım?',
    kosulMetni: 'QR doğrulama açılınca',
    adimlar: [
      OgrenmeAdimi(
        hedef: Secici.metin('Tara'),
        metin: '«Tara»ya dokun.',
        kalici: true,
        sonuc: 'kamera açılır, kodu okutunca sonuç çıkar',
      ),
    ],
    kural: 'Sonuç kartında ne yapacağın yazar. '
        '«Sonrakini tara» sıradaki kişiye geçer. '
        'Kamera izni gerekir.',
  ),
];
