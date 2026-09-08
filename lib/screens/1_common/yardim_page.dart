// lib/screens/1_common/yardim_page.dart
//
// Üyenin Yardım & SSS sayfası.
//
// 3.8.x turlarından sonra taslak metin ekranla uyuşmaz hâle gelmişti: "Geçmiş"
// diye bir alt sekme yok (Geçmiş Dersler ☰ menüde), profil değiştirme üst
// köşede değil Ayarlar'da, kayıt ve şifre sıfırlama artık tarayıcıda değil
// uygulama içinde. Koyu tema, ajanda görünümü ve Ayarlar sayfası hiç
// anlatılmıyordu. Metin bu turda ekrana göre yeniden yazıldı ve konu
// başlıklarına ayrıldı.
//
// Ekranın kendisi ortak `SssGorunumu`'nda; antrenör ve yönetici/ofis yardım
// sayfaları da aynı gövdeyi kullanıyor.

import 'package:fitcall/screens/1_common/widgets/sss_gorunumu.dart';
import 'package:flutter/material.dart';

class YardimPage extends StatelessWidget {
  const YardimPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SssGorunumu(
      baslik: 'Yardım & SSS',
      ustAciklama: 'Dersler, paketler, telafi ve bakiye hakkında en çok sorulanlar.',
      ustIkon: Icons.help_outline_rounded,
      bolumler: _bolumler,
    );
  }
}

const _bolumler = <SssBolum>[
  /* ----------------------------- BAŞLARKEN ------------------------------ */
  SssBolum(
    baslik: 'Başlarken',
    ikon: Icons.flag_outlined,
    sorular: [
      SssSoru(
        ikon: Icons.person_add_outlined,
        soru: 'Uygulamaya nasıl kayıt olurum?',
        cevap:
            'Giriş ekranındaki "Kayıt ol" bağlantısıyla başvuru formu uygulamanın'
            ' içinde açılır; dört adımda doldurulur (kulüp ve kimlik bilgileri,'
            ' iletişim, yaşa göre veli ya da meslek bilgisi, tenis geçmişi ve KVKK'
            ' onayı). Her adımda kendi alanları denetlenir, üstteki çubuk kaçıncı'
            ' adımda olduğunuzu gösterir. Başvurunuz kulüp tarafından onaylandığında'
            ' hesabınız aktifleşir; kullanıcı adınız ve şifreniz SMS ve e-posta ile'
            ' iletilir. Aynı kişi ikinci kez başvurursa hata almaz, "başvurunuz zaten'
            ' sırada" bilgisi görür.',
      ),
      SssSoru(
        ikon: Icons.lock_reset_rounded,
        soru: 'Şifremi unuttum, ne yapmalıyım?',
        cevap:
            'Giriş ekranındaki "Şifremi unuttum" ile kullanıcı adınızı ya da 10'
            ' haneli cep telefonu numaranızı yazmanız yeterli; sıfırlama bağlantısı'
            ' e-postanıza gelir. Aynı numara birden çok hesaba bağlıysa (örneğin veli'
            ' kendi numarasını çocuğunun kaydına yazdıysa) önce hesap seçim adımı'
            ' çıkar; bu ekran kimlik doğrulamasından önce geldiği için ad ve e-posta'
            ' maskeli gösterilir. Yeni şifreyi e-postadaki tek kullanımlık bağlantıdan'
            ' belirlersiniz.',
      ),
      SssSoru(
        ikon: Icons.switch_account_outlined,
        soru: 'Birden fazla profilim var, nasıl geçiş yaparım?',
        cevap:
            'Ayarlar sayfasındaki "Profil değiştir" satırı sizi profil seçim ekranına'
            ' götürür; hesabınıza kaç profil bağlıysa orada listelenir. Satır yalnız'
            ' birden fazla profili olan hesaplarda görünür. Ayarlar\'a ☰ menüden ya da'
            ' "Hesabım" sekmesinden ulaşırsınız.',
      ),
      SssSoru(
        ikon: Icons.lock_outline_rounded,
        soru: '"Erişim kısıtlı" uyarısı görüyorum, neden?',
        cevap:
            'Hareketler ve Hesabım sayfalarını yalnızca ana hesap kullanıcısı'
            ' görebilir. Aile üyeleri tek bir ana hesaba bağlıysa, bakiye ve hesap'
            ' bilgilerini ana hesap sahibi görür. Ana hesaba geçmek için Ayarlar >'
            ' Profil değiştir\'i kullanın.',
      ),
    ],
  ),

  /* ---------------------------- ANA SAYFA ------------------------------- */
  SssBolum(
    baslik: 'Ana sayfa',
    ikon: Icons.dashboard_outlined,
    sorular: [
      SssSoru(
        ikon: Icons.space_dashboard_outlined,
        soru: 'Ana sayfada neler var, menüye nasıl ulaşırım?',
        cevap:
            'En üstte bakiyenizi, kalan haklarınızı ve telafi derslerinizi özet'
            ' şeridinde görürsünüz; her birine dokununca ilgili sayfa açılır. Altında'
            ' sıradaki dersiniz ve "Bekleyen İşlemler" bölümü vardır. Alt çubuktan Ana'
            ' Sayfa, Takvim, Hareketler ve Hesabım sayfalarına, ortadaki düğmeden QR'
            ' ekranına geçersiniz; sol üstteki ☰ menüsünden Üyelik & Paket, Telafi'
            ' Derslerim, Geçmiş Dersler, Bildirimler, Event/Davet, Yardım ve Ayarlar\'a'
            ' ulaşırsınız.',
      ),
      SssSoru(
        ikon: Icons.playlist_add_check_rounded,
        soru: '"Bekleyen İşlemler" bölümünde neler çıkar?',
        cevap:
            'Sizden bir adım bekleyen konular: katılım bildirimi beklenen dersler,'
            ' ödenmemiş borç, değerlendirmediğiniz dersler, bitmek üzere olan paket ve'
            ' süresi dolmak üzere olan telafi hakkı. Karta dokunduğunuzda doğrudan'
            ' ilgili sayfaya gidersiniz. Bekleyen bir işiniz yoksa bölüm hiç çıkmaz.',
      ),
    ],
  ),

  /* -------------------------- TAKVİM VE DERSLER ------------------------- */
  SssBolum(
    baslik: 'Takvim ve dersler',
    ikon: Icons.calendar_month_outlined,
    sorular: [
      SssSoru(
        ikon: Icons.event_available_outlined,
        soru: 'Derslerimi nereden görürüm?',
        cevap:
            'Alt çubuktaki "Takvim" sekmesinden haftalar ve günler arasında gezinerek'
            ' geçmiş ve planlanan derslerinizi görürsünüz. Bir güne dokununca o günün'
            ' dersleri, bir derse dokununca dersin detayı açılır. Sıradaki dersiniz ana'
            ' sayfada da gösterilir.',
      ),
      SssSoru(
        ikon: Icons.view_agenda_outlined,
        soru: 'Ajanda (liste) görünümü ne işe yarar?',
        cevap:
            'Takvimin sağ üstündeki görünüm düğmesiyle ızgara ile ajanda arasında'
            ' geçiş yaparsınız. Ajanda, derslerinizi gün gün alt alta listeler —'
            ' "sıradaki derslerim ne zaman" sorusunun cevabı ızgarada saat aralıklarını'
            ' taramaktan daha hızlı bulunur. Hafta şeridindeki "Bugün" düğmesi hangi'
            ' görünümde olursanız olun sizi bugüne döndürür.',
      ),
      SssSoru(
        ikon: Icons.how_to_reg_outlined,
        soru: 'Bir derse katılıp katılmayacağımı nasıl bildiririm?',
        cevap:
            'Kulüp bir ders için görüş istediğinde ana sayfada "Katılım geri bildirimi'
            ' bekleniyor" kartı çıkar. Karta dokunduğunuzda bekleyen dersleriniz'
            ' listelenir; dersi seçip "Katılacağım" ya da "Katılamayacağım" olarak'
            ' durumunuzu bildirirsiniz. Aynı istek size bildirim olarak da ulaşabilir.',
      ),
      SssSoru(
        ikon: Icons.event_busy_outlined,
        soru: 'Bir derse katılamayacağımı nasıl bildiririm?',
        cevap:
            'Takvimde ilgili derse dokunup "Katılamayacağım" ile durumunuzu'
            ' iletebilirsiniz. Ders saatinden en az 24 saat önce yapılan bildirimlerde'
            ' telafi hakkı tanımlanır ve ders bir pakete dahilse paketinizden düşülmez.'
            ' Daha geç bildirimlerde bu haklar oluşmaz; istisnai durumlar için kulüple'
            ' iletişime geçmeniz gerekir. Bildiriminiz ön büroya da düşer.',
      ),
      SssSoru(
        ikon: Icons.event_note_outlined,
        soru: 'Dersimi telefon takvimime ekleyebilir miyim?',
        cevap:
            'Evet. Yaklaşan bir dersin detayındaki "Telefon Takvimine Ekle" ya da ana'
            ' sayfadaki sıradaki ders kartındaki "Takvime Ekle" ile dersi cihazınızın'
            ' takvimine kaydedebilirsiniz; hatırlatmayı telefonunuz yapar.',
      ),
      SssSoru(
        ikon: Icons.schedule_rounded,
        soru: 'Saatler telefonumun saat dilimine göre mi gösteriliyor?',
        cevap:
            'Hayır. Uygulama tüm ders saatlerini kulübün saatine göre gösterir;'
            ' telefonunuzun saat dilimi ne olursa olsun ekranda gördüğünüz saat'
            ' kulüpteki gerçek ders saatidir.',
      ),
    ],
  ),

  /* ---------------------- PAKET, TELAFİ VE BAKİYE ----------------------- */
  SssBolum(
    baslik: 'Paket, telafi ve bakiye',
    ikon: Icons.confirmation_number_outlined,
    sorular: [
      SssSoru(
        ikon: Icons.card_membership_outlined,
        soru: 'Kalan haklarımı ve paketlerimi nereden görürüm?',
        cevap:
            'Ana sayfadaki "Kalan Haklarım" kartına ya da ☰ menüdeki "Üyelik & Paket'
            ' Bilgilerim" bölümüne dokunun. Kayıtlarınız Paket, Aidat ve Tek Ders'
            ' başlıkları altında gruplanır; bir başlığa dokununca o gruptaki kayıtlar'
            ' açılır.',
      ),
      SssSoru(
        ikon: Icons.event_repeat_rounded,
        soru: 'Telafi derslerim nedir, nereden takip ederim?',
        cevap:
            'Uygun koşullarda katılamadığınız derslerden kazandığınız haklardır. Ana'
            ' sayfadaki "Telafi Derslerim" kartından ya da ☰ menüden takip edersiniz;'
            ' aktif ve kullanılmış telafilerinizi geçerlilik tarihleriyle birlikte'
            ' görürsünüz. Telafi hakkının süresi dolmak üzereyse ana sayfada uyarı'
            ' kartı çıkar.',
      ),
      SssSoru(
        ikon: Icons.account_balance_wallet_outlined,
        soru: 'Bakiyemi ve hesap hareketlerimi nasıl görürüm?',
        cevap:
            'Ana sayfadaki "Bakiye" kartına ya da alt çubuktaki "Hareketler" sekmesine'
            ' dokunarak hesap hareketlerinizi zaman tüneli hâlinde görürsünüz. Ödemeler'
            ' kulübünüzün belirlediği yöntemlerle yapılır; ayrıntı için kulüp yönetimine'
            ' başvurun.',
      ),
      SssSoru(
        ikon: Icons.hourglass_bottom_rounded,
        soru: '"Paketiniz bitiyor" uyarısını neden aldım?',
        cevap:
            'Kalan ders hakkınız ikiye ya da altına düştüğünde ve paketi son 45 gün'
            ' içinde kullanmışsanız uyarı çıkar. Amaç düzenli devam ederken paketin'
            ' habersiz bitmesini önlemek; uzun süredir kullanılmayan paketler için'
            ' uyarı gösterilmez.',
      ),
    ],
  ),

  /* -------------------- GEÇMİŞ DERSLER VE DEĞERLENDİRME ----------------- */
  SssBolum(
    baslik: 'Geçmiş dersler',
    ikon: Icons.history_rounded,
    sorular: [
      SssSoru(
        ikon: Icons.list_alt_rounded,
        soru: 'Geçmiş derslerimi nereden görürüm?',
        cevap:
            '☰ menüdeki "Geçmiş Dersler" sayfasında tamamlanan dersleriniz aya göre'
            ' gruplanmış olarak listelenir. Durumlar renk ve etikete göre ayrılır:'
            ' katıldığınız/yapılan dersler, iptaller, kulüp onayında bekleyenler,'
            ' yöneticinin "yapılmadı" dediği dersler ve katılmadığınız dersler.',
      ),
      SssSoru(
        ikon: Icons.star_outline_rounded,
        soru: 'Dersi değerlendirebilir miyim?',
        cevap:
            'Evet. Geçmiş Dersler listesinde bir derse dokunup puan ve yorum'
            ' bırakabilirsiniz. Değerlendirmediğiniz ders varsa ana sayfadaki Bekleyen'
            ' İşlemler bölümünde hatırlatma kartı çıkar ve karta dokununca doğrudan bu'
            ' sayfaya gelirsiniz.',
      ),
    ],
  ),

  /* --------------------------- QR VE DAVETLER --------------------------- */
  SssBolum(
    baslik: 'QR ve davetler',
    ikon: Icons.qr_code_rounded,
    sorular: [
      SssSoru(
        ikon: Icons.qr_code_scanner_rounded,
        soru: 'QR kod ekranı ne işe yarar?',
        cevap:
            'Alt çubuğun ortasındaki QR düğmesi tesis giriş ekranını açar. Üstte'
            ' "Kişisel QR Kodunuz" bölümü vardır; görevliye okutarak hızlıca giriş'
            ' yaparsınız. Kod ekranda dururken parlaklık otomatik artar ve zemin her'
            ' temada beyaz kalır, böylece koyu temada da okunur.',
      ),
      SssSoru(
        ikon: Icons.person_add_alt_rounded,
        soru: 'Misafir davet edebilir miyim?',
        cevap:
            'Evet. Aynı QR ekranındaki "Misafir Davetlerim" bölümünden misafirin adını'
            ' ve kodun kaç süre geçerli olacağını yazarak davet oluşturursunuz. Kod,'
            ' kalan süresiyle listede durur; WhatsApp ya da başka bir uygulamayla'
            ' paylaşabilir, gerekirse süresi dolmadan silebilirsiniz. Sildiğiniz bir'
            ' davet kapıda okutulduğunda görevli "giriş iptal edilmiş" uyarısı görür.',
      ),
      SssSoru(
        ikon: Icons.celebration_outlined,
        soru: 'Event / Davet bölümü nedir?',
        cevap:
            '☰ menüdeki bu bölüm, kulübün düzenlediği etkinlik için ayrı bir giriş'
            ' kodu ve davetli listesi tutar. Etkinliğe özel kotanız varsa kaç davet'
            ' hakkınızın kaldığı yazar. Bölüm yalnız aktif bir etkinlik varsa anlamlıdır;'
            ' yoksa liste boş görünür.',
      ),
    ],
  ),

  /* ------------------------ BİLDİRİM VE AYARLAR ------------------------- */
  SssBolum(
    baslik: 'Bildirimler ve ayarlar',
    ikon: Icons.settings_outlined,
    sorular: [
      SssSoru(
        ikon: Icons.notifications_off_outlined,
        soru: 'Bildirim gelmiyor, ne yapmalıyım?',
        cevap:
            'Ayarlar > Bildirim izni satırı iznin açık mı kapalı mı olduğunu yazar;'
            ' kapalıysa dokunduğunuzda telefonun uygulama ayarları açılır. İzin'
            ' kapalıyken ders hatırlatması, katılım isteği ve duyuru bildirimleri size'
            ' ulaşmaz. İzni açtıktan sonra Bildirimler sayfasını bir kez açın; cihaz'
            ' kaydınız orada tazelenir.',
      ),
      SssSoru(
        ikon: Icons.dark_mode_outlined,
        soru: 'Koyu temayı nasıl açarım?',
        cevap:
            'Ayarlar > Tema bölümünden Sistem, Açık veya Koyu seçebilirsiniz. "Sistem"'
            ' seçiliyken telefonunuzun karanlık mod ayarına uyar. Seçiminiz uygulamayı'
            ' kapatıp açsanız da korunur.',
      ),
      SssSoru(
        ikon: Icons.password_rounded,
        soru: 'Şifremi nasıl değiştiririm?',
        cevap:
            'Ayarlar > Şifreyi değiştir ile mevcut şifrenizi girerek yenisini'
            ' belirlersiniz. Şifrenizi hatırlamıyorsanız çıkış yapıp giriş ekranındaki'
            ' "Şifremi unuttum" akışını kullanmanız gerekir.',
      ),
      SssSoru(
        ikon: Icons.privacy_tip_outlined,
        soru: 'Verilerim nasıl işleniyor, hesabımı sildirebilir miyim?',
        cevap:
            'Ayarlar > KVKK aydınlatma metni verilerin nasıl işlendiğini ve saklandığını'
            ' anlatır. Aynı sayfadaki "Hesabı kalıcı sil" ile hesap silme talebinde'
            ' bulunabilirsiniz; işlem geri alınamaz, bu yüzden onay istenir. Ödeme ve'
            ' üyelik kayıtlarınızla ilgili sorularınız için kulüp yönetimine başvurun.',
      ),
    ],
  ),
];
