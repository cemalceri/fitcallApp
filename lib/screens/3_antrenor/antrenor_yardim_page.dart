// lib/screens/3_antrenor/antrenor_yardim_page.dart
//
// Antrenöre özel Yardım & SSS sayfası.
//
// Ortak `yardim_page.dart` üye diliyle yazılmış (paket, bakiye, telafi); antrenör
// oradan kendi işine yarayan tek bir cevap bulamıyordu. Bu sayfa antrenörün
// gerçekten takıldığı yerleri anlatır: yoklama kilidi, plan dışı katılımcı,
// devir, hakediş durumları.
//
// Cevaplar uygulamanın GERÇEK davranışını anlatır; kural metinleri backend'deki
// tek doğruluk kaynaklarından türetildi (`api/yonetici/hakedis_servis.py`,
// `api/etkinlik/metots.py` yoklama kilitleri, `api/antrenor/metots.py` devir
// kuralları, `api/antrenor/gunluk_ozet.py` eksik yoklama pencereleri). Kural
// değişirse buradaki metin de güncellenmeli.
//
// Sayfa API çağırmadığı için doğrudan taşma testine girebiliyor
// (bkz. test/tasma_ekranlar_test.dart).

import 'package:fitcall/screens/1_common/widgets/sss_arama.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AntrenorYardimPage extends StatefulWidget {
  const AntrenorYardimPage({super.key});

  @override
  State<AntrenorYardimPage> createState() => _AntrenorYardimPageState();
}

class _AntrenorYardimPageState extends State<AntrenorYardimPage> {
  final _aramaCtrl = TextEditingController();
  String _sorgu = '';
  String? _seciliBolum;

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  /// Arama + bölüm çipi birlikte uygulanır; sonuç bölüm bölüm döner.
  List<_Bolum> get _sonuclar {
    final q = _sorgu.trim().toLowerCase();
    final liste = <_Bolum>[];
    for (final bolum in _bolumler) {
      if (_seciliBolum != null && bolum.baslik != _seciliBolum) continue;
      final sorular = q.isEmpty
          ? bolum.sorular
          : bolum.sorular
              .where((s) =>
                  s.soru.toLowerCase().contains(q) ||
                  s.cevap.toLowerCase().contains(q))
              .toList();
      if (sorular.isNotEmpty) {
        liste.add(
            _Bolum(baslik: bolum.baslik, ikon: bolum.ikon, sorular: sorular));
      }
    }
    return liste;
  }

  static const _bolumler = <_Bolum>[
    _Bolum(
      baslik: 'Yoklama ve ders onayı',
      ikon: Icons.fact_check_outlined,
      sorular: [
        _SSS(
          ikon: Icons.check_circle_outline_rounded,
          soru: '"Ders yapıldı, herkes geldi" butonu tam olarak neyi kaydeder?',
          cevap:
              'Tek dokunuşta dersi "yapıldı", nedenini "Planlandığı gibi yapıldı" ve derse'
              ' planlı tüm katılımcıları "katıldı" olarak kaydeder. Katılımcı listesini tek'
              ' tek işaretlemeniz gerekmez. Gelmeyen ya da plana ek katılan biri varsa bu'
              ' butonu kullanmayın; altındaki "Eksik ya da fazla var" seçeneğiyle detay'
              ' ekranını açın.',
        ),
        _SSS(
          ikon: Icons.edit_outlined,
          soru: 'Yoklamayı yanlış girdim, sonradan düzeltebilir miyim?',
          cevap:
              'Yönetici o derse kendi onayını vermediği sürece evet. Derse tekrar'
              ' dokunduğunuzda ekran doğrudan detay görünümünde ve önceki kaydınız dolu'
              ' olarak açılır; değişikliği yapıp "Kaydet" dediğinizde eski kaydın üzerine'
              ' yazılır.',
        ),
        _SSS(
          ikon: Icons.lock_outline_rounded,
          soru:
              '"Yönetici onayı verildiği için bu ders kilitlenmiştir" uyarısını neden alıyorum?',
          cevap:
              'Yönetici o ders için "yapıldı" veya "yapılmadı" kararını sisteme işlediğinde'
              ' ders kilitlenir ve yoklama ekranı salt okunur hâle gelir. Kilitli derste'
              ' durumu, nedeni ve katılım listesini görebilirsiniz ama değiştiremezsiniz.'
              ' Düzeltme gerekiyorsa yöneticinize başvurmanız gerekir; uygulama üzerinden'
              ' kilidi açmanın bir yolu yoktur.',
        ),
        _SSS(
          ikon: Icons.cancel_outlined,
          soru: '"Ders yapılmadı" seçtiğimde ne oluyor?',
          cevap:
              'Katılımcı listesi kapanır ve derse planlı tüm üyeler otomatik olarak'
              ' "katılmadı" sayılır; tek tek işaretleme yapmazsınız. Ayrıca o derse'
              ' eklediğiniz, yöneticinin henüz karar vermediği plan dışı üye ve misafir'
              ' kayıtları silinir.',
        ),
        _SSS(
          ikon: Icons.block_rounded,
          soru:
              '"Yapıldı" kaydettiğim dersi "yapılmadı"ya çeviremiyorum, hata alıyorum — neden?',
          cevap:
              'O derste yöneticinin parasal kararını verdiği bir plan dışı kayıt (borç'
              ' yazılmış ya da paketten düşülmüş) var demektir. Böyle bir kayıt varken ders'
              ' "yapılmadı"ya çevrilemez, çünkü o kayıt karşılıksız kalır. İstek tamamen'
              ' reddedilir ve dersinize hiçbir şey yazılmaz; değişiklik için yöneticinize'
              ' başvurun.',
        ),
        _SSS(
          ikon: Icons.rule_rounded,
          soru:
              '"Yapılmadı" nedenleri arasında ne fark var, hangisini seçmeliyim?',
          cevap:
              'Seçim otomatik bir işlem başlatmaz; hiçbir neden kendiliğinden hakediş'
              ' vermez veya kesmez. Neden ve açıklama kayda düşer, yönetici hakediş kararını'
              ' verirken bunları görür ve hakediş ekranınızdaki ders kartında not olarak'
              ' görünür. Bu yüzden nedeni doğru seçmek ve gerekiyorsa açıklama yazmak sizin'
              ' lehinizedir.',
        ),
        _SSS(
          ikon: Icons.event_repeat_rounded,
          soru:
              '"Planlandığı gibi yapıldı" ile "Telafi/ek ders yapıldı" arasındaki fark nedir?',
          cevap:
              'İkisi de dersi "yapıldı" olarak kaydeder; fark yalnızca kayda düşen'
              ' etikettir. Bu seçim üyeye telafi hakkı üretmez ve mevcut telafi hakkını'
              ' harcamaz — telafi hakları ders iptal akışında oluşur. Amaç, dersin planlı'
              ' akışın parçası mı yoksa sonradan konulmuş bir telafi/ek ders mi olduğunu'
              ' yöneticiye bildirmektir.',
        ),
        _SSS(
          ikon: Icons.report_problem_outlined,
          soru: 'Yoklamayı hiç girmezsem ne olur?',
          cevap:
              'Ders "Eksik Yoklamalar" listenizde kalır ve ana sayfada uyarı olarak'
              ' görünmeye devam eder. Daha önemlisi, yönetici karar veremediği için o ders'
              ' hakediş ekranınızda "Bekliyor" grubunda takılı kalır.',
        ),
      ],
    ),
    _Bolum(
      baslik: 'Eksik yoklamalar',
      ikon: Icons.pending_actions_outlined,
      sorular: [
        _SSS(
          ikon: Icons.list_alt_rounded,
          soru: '"Eksik Yoklamalar" listesine hangi dersler düşüyor?',
          cevap:
              'Bitiş saati geçmiş, iptal edilmemiş ve sizin hiç onay vermediğiniz dersler'
              ' girer; pencere son 30 gündür. Hem ana antrenör hem yardımcı antrenör'
              ' olduğunuz dersler listelenir. Bir dersin yoklamasını kaydettiğiniz anda liste'
              ' yenilenir ve o ders listeden düşer.',
        ),
        _SSS(
          ikon: Icons.difference_outlined,
          soru:
              'Ana sayfadaki uyarı ile Eksik Yoklamalar sayfasındaki sayı neden tutmuyor?',
          cevap:
              'İki ekran farklı pencerelere bakar. Ana sayfadaki günlük özet uyarısı yalnızca'
              ' bugünü ve bugün hariç son 7 günü sayar; Eksik Yoklamalar sayfası ise son 30'
              ' günün tamamını listeler. Bu yüzden sayfadaki liste normalde daha uzundur,'
              ' ikisi arasında bir çelişki yoktur.',
        ),
        _SSS(
          ikon: Icons.event_busy_outlined,
          soru: 'İptal edilen dersin yoklamasını girmem gerekir mi?',
          cevap:
              'Hayır. İptal edilen dersin yoklaması olmaz; bu dersler eksik yoklama listesine'
              ' hiç girmez ve sizden bir işlem beklenmez. Listeyi açtıktan sonra ders iptal'
              ' edilirse kaydetmeye çalıştığınızda "İptal edilen dersin yoklaması alınamaz"'
              ' uyarısını alırsınız; yapılacak bir şey yoktur.',
        ),
      ],
    ),
    _Bolum(
      baslik: 'Plan dışı katılımcı ve misafir',
      ikon: Icons.person_add_alt_1_outlined,
      sorular: [
        _SSS(
          ikon: Icons.group_add_outlined,
          soru: 'Derse planda olmayan kayıtlı bir üyeyi nasıl eklerim?',
          cevap:
              'Dersi "yapıldı" olarak işaretleyip Katılımcılar bölümündeki "Üye" butonuna'
              ' dokunun; açılan listede aktif üyeler arasında arama yapıp kişiyi seçin.'
              ' Eklenen kişi "Plan Dışı" etiketiyle ve varsayılan olarak "katıldı" işaretli'
              ' gelir, ardından not girmeniz istenir.',
        ),
        _SSS(
          ikon: Icons.person_outline_rounded,
          soru: 'Üye olmayan birini derse nasıl eklerim?',
          cevap:
              'Katılımcılar bölümündeki "Misafir" butonunu kullanın. Yalnızca ad soyad'
              ' zorunludur; telefon ve diğer bilgileri serbest not alanına yazabilirsiniz.'
              ' Misafirler üye listesinden bağımsız, ayrı bir kayıt olarak tutulur.',
        ),
        _SSS(
          ikon: Icons.help_outline_rounded,
          soru: '"Üye" mi "Misafir" mi seçmeliyim?',
          cevap:
              'Kişi kulüpte kayıtlı bir üyeyse "Üye" seçin; ücret ya da paket düşümü'
              ' doğrudan o kişinin hesabına işlenebilir. Kayıtlı değilse "Misafir" seçin;'
              ' kaydı misafir havuzunda tutulur ve kişi sonradan üye olursa yönetici dersi ve'
              ' borcu ona aktarabilir. Kayıtlı bir üyeyi misafir olarak eklerseniz ders onun'
              ' kendi paket ve hesap dökümünde görünmez.',
        ),
        _SSS(
          ikon: Icons.payments_outlined,
          soru: 'Plan dışı eklediğim kişinin ücretini kim belirliyor?',
          cevap:
              'Siz belirlemezsiniz, kararı yönetici verir: borç yazılması, paketten'
              ' düşülmesi, ücretsiz olması ve kimin ödeyeceği yönetim tarafında karara'
              ' bağlanır. Yoklamayı kaydettiğinizde ofise otomatik bildirim gider; birini'
              ' listeden çıkarmanız da aynı şekilde bildirilir. Sizden beklenen tek şey'
              ' kişiyi doğru eklemek ve nota gerekli bilgiyi yazmaktır.',
        ),
        _SSS(
          ikon: Icons.lock_person_outlined,
          soru:
              'Plan dışı satırdaki kilit simgesi ne anlama geliyor, neden silemiyorum?',
          cevap:
              'Yönetici o kayıt için parasal kararını vermiş demektir. Arkasında yazılmış bir'
              ' borç ya da yapılmış bir paket düşümü olduğu için kayıt silinirse bu işlem'
              ' karşılıksız kalır; bu yüzden satır kilitlenir. Yanlış eklediyseniz'
              ' yöneticinize haber verin.',
        ),
        _SSS(
          ikon: Icons.sticky_note_2_outlined,
          soru: 'Not alanına ne yazmalıyım, bu notu kim görüyor?',
          cevap:
              'Notu yönetici, kişinin ücret ve paket kararını verirken okur. Misafirlerde'
              ' kişinin telefonu ve kim olduğu, plan dışı üyelerde ise derse neden katıldığı'
              ' (telafi, deneme dersi, arkadaşıyla geldi gibi) en işe yarayan bilgilerdir.',
        ),
      ],
    ),
    _Bolum(
      baslik: 'Ders devri',
      ikon: Icons.swap_horiz_rounded,
      sorular: [
        _SSS(
          ikon: Icons.send_outlined,
          soru: 'Dersimi başka bir antrenöre nasıl devrederim?',
          cevap:
              'Takvimde gelecek bir derse dokunup açılan detayda "Devret" butonunu kullanın,'
              ' listeden antrenörü seçin ve isterseniz not ekleyip talebi gönderin. Ders hemen'
              ' el değiştirmez; karşı taraf kabul edene kadar ders sizde kalır ve yoklamadan'
              ' siz sorumlusunuz.',
        ),
        _SSS(
          ikon: Icons.do_not_disturb_on_outlined,
          soru:
              'Antrenör listesinde bazı isimler soluk ve seçilemiyor — neden?',
          cevap:
              'Aynı derste diğer rolde görevli olan antrenör devralamaz. Siz ana'
              ' antrenörseniz o dersin yardımcı antrenörü, yardımcı antrenörseniz ana'
              ' antrenörü listede pasif görünür ve nedeni satırın altında yazar. Bir kişi aynı'
              ' derste iki rolü birden üstlenemez.',
        ),
        _SSS(
          ikon: Icons.hourglass_empty_rounded,
          soru: 'Gönderdiğim devir talebine cevap gelmezse ne olur?',
          cevap:
              'Ders başlayana kadar cevap gelmezse talep "süresi geçti" durumuna düşer ve'
              ' ders sizde kalır — yoklamayı yine siz girersiniz. Beklerken fikrinizi'
              ' değiştirirseniz aynı dersin detayından "Talebi Gör" diyerek talebi geri'
              ' çekebilirsiniz. Bir derste aynı anda yalnız bir bekleyen talep olabilir.',
        ),
        _SSS(
          ikon: Icons.mark_email_unread_outlined,
          soru: 'Bana gelen devir teklifini nereden görüp cevaplarım?',
          cevap:
              'Teklif geldiğinde bildirim alırsınız ve bildirime dokunarak doğrudan cevap'
              ' ekranına gidebilirsiniz. Bildirimi kaçırdıysanız takvimde ilgili derse dokunup'
              ' "Talebi Gör" ile aynı ekrana ulaşır, kabul veya reddedersiniz.',
        ),
        _SSS(
          ikon: Icons.published_with_changes_rounded,
          soru: 'Devri kabul edersem ne değişir?',
          cevap:
              'Ders üzerinize geçer: talep hangi rol içinse (ana ya da yardımcı antrenörlük)'
              ' o rol size aktarılır, ders takviminizde görünmeye başlar ve yoklamayı artık'
              ' siz girersiniz. Hakediş de bu andan itibaren size yazılır. Talebi gönderen'
              ' antrenöre sonucun bildirimi gider.',
        ),
        _SSS(
          ikon: Icons.history_toggle_off_rounded,
          soru: 'Geçmiş veya iptal edilmiş bir dersi devredebilir miyim?',
          cevap:
              'Hayır. Başlamış, bitmiş ya da iptal edilmiş dersler için devir talebi'
              ' oluşturulamaz; devir yalnızca henüz başlamamış dersler içindir. Geçmiş bir'
              ' dersin yoklaması dersin o anki antrenörüne aittir.',
        ),
        _SSS(
          ikon: Icons.people_alt_outlined,
          soru: 'Yardımcı antrenör olduğum dersi devredebilir miyim?',
          cevap:
              'Evet, ama devredilen yalnızca yardımcı antrenörlüktür; dersin ana antrenörü'
              ' değişmez. Uygulama derste hangi rolde olduğunuzu kendisi tespit eder ve devir'
              ' ekranının üstünde size bunu yazar.',
        ),
      ],
    ),
    _Bolum(
      baslik: 'Ders iptali',
      ikon: Icons.event_busy_rounded,
      sorular: [
        _SSS(
          ikon: Icons.gavel_rounded,
          soru: 'Dersi kendim iptal edebilir miyim?',
          cevap:
              'Hayır. "Dersi İptal Et" butonu dersi iptal etmez, yöneticiye bir iptal talebi'
              ' gönderir; iptal nedeni yazmanız zorunludur. Ders, yönetici talebi onaylayana'
              ' kadar sizin ve üyelerin takviminde planlı görünmeye devam eder.',
        ),
        _SSS(
          ikon: Icons.undo_rounded,
          soru: 'Gönderdiğim iptal talebini geri çekebilir miyim?',
          cevap:
              'Yönetici talebi henüz karara bağlamadıysa evet. Aynı derse tekrar dokunup'
              ' açılan ekrandan "İptal Talebini Geri Çek" diyebilirsiniz. Talep işleme'
              ' alındıktan sonra geri çekilemez.',
        ),
        _SSS(
          ikon: Icons.timer_off_outlined,
          soru: 'İptal edilen ders hakedişime sayılır mı?',
          cevap:
              'İptal edilen dersler hakediş ekranınızda "Hakediş dışı" grubunda görünür; ay'
              ' toplamları tutsun diye listeden gizlenmezler. Bu dersler size hakediş'
              ' kazandırmaz, ama aynı saatte yaptığınız başka bir dersin süresini de'
              ' eksiltmezler.',
        ),
      ],
    ),
    _Bolum(
      baslik: 'Hakediş saatlerim',
      ikon: Icons.access_time_filled_rounded,
      sorular: [
        _SSS(
          ikon: Icons.category_outlined,
          soru:
              '"Hakediş alacak", "Bekliyor" ve "Hakediş dışı" ne anlama geliyor?',
          cevap:
              '"Hakediş alacak", yöneticinin o ders için hakediş verdiğini kesinleştirdiği'
              ' derslerdir. "Bekliyor", yöneticinin henüz karar vermediği, yani sonucu'
              ' belirsiz derslerdir. "Hakediş dışı" ise yöneticinin açıkça "hakediş almaz"'
              ' dediği dersler ile iptal edilmiş dersleri kapsar.',
        ),
        _SSS(
          ikon: Icons.hourglass_bottom_rounded,
          soru:
              'Dersi yaptım ve yoklamayı girdim, ama hâlâ "Bekliyor" — neden?',
          cevap:
              'Sizin verdiğiniz yoklama onayı dersi tek başına "hakediş alacak" yapmaz;'
              ' belirleyici olan yöneticinin o derse verdiği karardır. Yoklamayı girmeniz'
              ' kararın önünü açar, sonrasında ders yönetici onayıyla "Hakediş alacak"'
              ' grubuna geçer. Uzun süre beklemede kalan dersler için yöneticinize'
              ' başvurabilirsiniz.',
        ),
        _SSS(
          ikon: Icons.swap_vert_rounded,
          soru:
              'Yapılmadı işaretli bir ders hakedişte, yaptığım bir ders "hakediş dışı"nda — bu nasıl olur?',
          cevap:
              'Yöneticinin hakediş işareti, dersin yapıldı/yapılmadı durumunu ezer. Bu yüzden'
              ' yapılmamış bir derse (örneğin öğrenci haber vermeden gelmediğinde) hakediş'
              ' verilebilir, onaylı bir ders ise açıkça "almaz" işaretlenmiş olabilir. Bu'
              ' derslerde yöneticinin seçtiği neden ve açıklama, ders kartında not olarak'
              ' gösterilir.',
        ),
        _SSS(
          ikon: Icons.merge_type_rounded,
          soru: '"3 ders / 60 dk" yazıyor, toplam yanlış mı hesaplanmış?',
          cevap:
              'Hayır. Aynı saate denk gelen dersleriniz varsa (farklı kort ya da farklı grup)'
              ' çalıştığınız süre bir kez sayılır; üst üste binen zaman iki katına çıkmaz.'
              ' Kısmi çakışma da doğru hesaplanır: 10:00-11:00 ve 10:30-11:30 iki ders toplamda'
              ' 90 dakikadır. Ders sayısı bundan etkilenmez, her ders ayrı sayılır ve yoklaması'
              ' ayrı alınır.',
        ),
        _SSS(
          ikon: Icons.people_outline_rounded,
          soru: 'Ana antrenör ve yardımcı antrenör kartları neden ayrı?',
          cevap:
              'Hakediş iki rol için ayrı tutulur, çünkü aynı derste iki antrenör görev alabilir'
              ' ve kararları birbirinden bağımsızdır. Yardımcı antrenör olduğunuz derslerde'
              ' "yapıldı/yapılmadı" onayı vermezsiniz; o rolde yalnızca yöneticinin hakediş'
              ' kararı işlenir. Yardımcı olarak hiç ders vermediyseniz o kart hiç görünmez.',
        ),
        _SSS(
          ikon: Icons.money_off_csred_outlined,
          soru: 'Bu ekrandaki rakamlar ücretimi mi gösteriyor?',
          cevap:
              'Hayır, gösterilen değerler ders sayısı ve saattir ("23,5 sa" gibi); uygulamada'
              ' ücret veya tutar bilgisi yer almaz. Ücret hesabı kulüp yönetimi tarafından bu'
              ' saatler üzerinden yapılır.',
        ),
        _SSS(
          ikon: Icons.calendar_view_month_rounded,
          soru:
              'Ay ızgarasındaki noktalar ne demek, neden 12 aydan eskisi yok?',
          cevap:
              'Nokta, o ayda kararı henüz verilmemiş, yani "Bekliyor" durumunda dersiniz'
              ' olduğunu gösterir. Ekran son 12 ayı kapsar ve en yeni ay en sonda, açılışta'
              ' seçili gelir; daha eski dönemler için yönetime başvurmanız gerekir.',
        ),
        _SSS(
          ikon: Icons.info_outline_rounded,
          soru: 'Bir dersin neden iptal edildiğini görebilir miyim?',
          cevap:
              'Evet. "Hakediş dışı" grubundaki iptal edilmiş derslerin kartında ayrı bir panel'
              ' açılır; dersi kimin iptal ettiği, ne zaman iptal edildiği, iptal sebebi ve'
              ' açıklaması burada yazar.',
        ),
      ],
    ),
    _Bolum(
      baslik: 'Takvim',
      ikon: Icons.calendar_month_outlined,
      sorular: [
        _SSS(
          ikon: Icons.palette_outlined,
          soru: 'Takvimdeki ders renkleri ne anlama geliyor?',
          cevap:
              'Mavi henüz gerçekleşmemiş dersi, turuncu bitmiş ama sizin yoklamasını'
              ' girmediğiniz dersi gösterir. Açık yeşil sizin onayladığınız fakat yöneticinin'
              ' henüz karar vermediği dersi, koyu yeşil hem sizin hem yöneticinin onayladığı'
              ' dersi işaret eder. Gri "yapılmadı" olarak kapatılmış dersleri, kırmızı ise'
              ' iptal edilmiş dersleri gösterir.',
        ),
        _SSS(
          ikon: Icons.groups_outlined,
          soru: 'Yardımcı antrenör olduğum dersler de takvimimde görünür mü?',
          cevap:
              'Evet. Takviminiz ana antrenör olduğunuz ve yardımcı antrenör olarak atandığınız'
              ' derslerin tamamını gösterir; ana sayfadaki "sonraki ders" ve günlük özet de'
              ' aynı şekilde ikisini birden kapsar.',
        ),
        _SSS(
          ikon: Icons.how_to_reg_outlined,
          soru: 'Üyelerin derse katılıp katılmayacağını nereden görürüm?',
          cevap:
              'Gelecek bir derse dokunduğunuzda "Katılımcı Durumları" bölümünde her üye renkli'
              ' bir etiketle listelenir: yeşil katılacağını bildirenleri, kırmızı'
              ' katılmayacağını bildirenleri, sarı ise henüz cevap vermeyenleri gösterir.',
        ),
        _SSS(
          ikon: Icons.person_search_outlined,
          soru: 'Üye "katılmayacağım" demişti ama derse geldi, ne yapmalıyım?',
          cevap:
              'Yoklamada o kişiyi "katıldı" olarak işaretleyin. Üyenin önceden verdiği teyit'
              ' yalnızca bilgilendirme amaçlıdır; kayda geçen ve hakediş ile paket hesabına'
              ' esas olan sizin girdiğiniz yoklamadır.',
        ),
        _SSS(
          ikon: Icons.refresh_rounded,
          soru:
              'Takvim neden tek gün gösteriyor, "Yenile" butonunu ne zaman kullanmalıyım?',
          cevap:
              'Takvim seçtiğiniz günün derslerini yükler ve gezindiğiniz günleri hafızada'
              ' tutar, böylece hızlı çalışır. Bir ders siz ekrandayken yönetici tarafından'
              ' değiştirilmiş ya da iptal edilmişse sağ üstteki "Yenile" ile o günü sunucudan'
              ' yeniden çekebilirsiniz.',
        ),
      ],
    ),
    _Bolum(
      baslik: 'Çalışma saatlerim',
      ikon: Icons.schedule_rounded,
      sorular: [
        _SSS(
          ikon: Icons.merge_rounded,
          soru:
              '"Birden fazla saat aralığı tanımlıydı, tek aralığa dönüşür" uyarısı ne demek?',
          cevap:
              'Bir gün için sistemde iki ayrı aralık (örneğin 09:00-12:00 ve 16:00-20:00)'
              ' tanımlıysa, bu ekran gün başına tek aralık gösterdiği için bunları en erken'
              ' başlangıç ve en geç bitişle birleştirip gösterir. Kaydederseniz aradaki boşluk'
              ' kapanır ve gün tek aralık olarak yazılır. Araya boşluk kalması gerekiyorsa'
              ' kaydetmeyin, yöneticinizden düzenlemesini isteyin.',
        ),
        _SSS(
          ikon: Icons.event_available_outlined,
          soru: 'Bir günü kapatırsam o gündeki mevcut derslerim iptal olur mu?',
          cevap:
              'Hayır. Çalışma saatleri yalnızca haftalık uygunluğunuzu kaydeder; planlanmış'
              ' dersleriniz olduğu gibi kalır ve yoklamalarını girmeye devam edersiniz. Var'
              ' olan bir dersin kaldırılması ancak iptal talebiyle olur.',
        ),
      ],
    ),
    _Bolum(
      baslik: 'Öğrencilerim',
      ikon: Icons.groups_rounded,
      sorular: [
        _SSS(
          ikon: Icons.person_search_rounded,
          soru:
              '"Öğrencilerim" listesine kimler giriyor, ders verdiğim herkes neden yok?',
          cevap:
              'Bu liste, sorumlu hocası siz olarak atanmış aktif üyeleri gösterir; ders'
              ' verdiğiniz ama sorumlu hocası başka bir antrenör olan öğrenciler burada'
              ' çıkmaz. Onları takvimde ilgili dersin katılımcı listesinde görürsünüz. Listeye'
              ' birinin eklenmesi gerekiyorsa bu atamayı yönetim yapar.',
        ),
        _SSS(
          ikon: Icons.percent_rounded,
          soru:
              'Öğrenci detayındaki katılım yüzdesi nasıl hesaplanıyor, neden bazen "—" görünüyor?',
          cevap:
              'Yüzde, son 90 gün içinde yalnızca yoklaması girilmiş dersler üzerinden'
              ' hesaplanır; yoklaması alınmamış dersler paydaya girmez. O dönemde hiç yoklama'
              ' kaydı yoksa yanıltıcı bir oran göstermek yerine "—" yazılır ve altında bunun'
              ' nedeni belirtilir.',
        ),
        _SSS(
          ikon: Icons.contact_phone_outlined,
          soru: 'Öğrencinin velisine veya acil durumda birine nasıl ulaşırım?',
          cevap:
              'Öğrenci detayındaki "İletişim" kartında öğrencinin kendi telefonu ile kayıtlı'
              ' anne, baba ve acil durum numaraları listelenir; numaraya dokunarak doğrudan'
              ' arayabilirsiniz. Kayıtlı numara yoksa kart bunu belirtir, güncelleme yönetim'
              ' tarafından yapılır.',
        ),
        _SSS(
          ikon: Icons.inventory_2_outlined,
          soru:
              'Öğrencinin kalan paket hakkını görüyorum, dersten düşümü ben mi yapmalıyım?',
          cevap:
              'Hayır, hiçbir düşüm işlemi sizde değildir. Paket düşümleri yoklama ve yönetici'
              ' onayı üzerinden otomatik işler; buradaki bilgi yalnızca öğrencinin hakkının'
              ' bitmek üzere olduğunu görmeniz içindir.',
        ),
        _SSS(
          ikon: Icons.edit_note_outlined,
          soru: 'Öğrenci detayındaki görüşme notlarını ben ekleyebilir miyim?',
          cevap:
              'Hayır, bu bölüm uygulamada salt okunurdur; notları yönetim ve ofis girer, siz'
              ' yalnızca görürsünüz. Derse özel bir gözleminizi kayda geçirmek isterseniz'
              ' yoklama ekranındaki açıklama alanını ya da katılımcı notunu kullanabilirsiniz.',
        ),
      ],
    ),
    _Bolum(
      baslik: 'Genel',
      ikon: Icons.settings_outlined,
      sorular: [
        _SSS(
          ikon: Icons.admin_panel_settings_outlined,
          soru:
              '"Bildirimler" sayfasına girmeye çalışınca ana hesap uyarısı alıyorum, ne demek?',
          cevap:
              'Bazı sayfalar yalnızca hesabın ana profiliyle açılabilir. Aile üyeleriyle ortak'
              ' bir hesap kullanıyorsanız ve şu an ana profil seçili değilse bu sayfalar'
              ' kapalıdır; ana profile geçtiğinizde açılır.',
        ),
        _SSS(
          ikon: Icons.switch_account_outlined,
          soru:
              'Hem üye hem antrenör profilim var, aralarında nasıl geçiş yaparım?',
          cevap:
              'Ana sayfanın üst köşesindeki profil alanına dokunup "Profil Seç" ekranına'
              ' geçerek hesabınıza bağlı diğer profile geçebilirsiniz. Her profil kendi'
              ' ekranlarını ve yetkilerini taşır; antrenör işlemleri yalnızca antrenör'
              ' profilinde görünür.',
        ),
        _SSS(
          ikon: Icons.public_rounded,
          soru:
              'Yurt dışındayım ya da telefonumun saati farklı; ders saatleri kayar mı?',
          cevap:
              'Hayır. Uygulama tüm ders saatlerini kulübün saatine göre gösterir; telefonunuzun'
              ' saat dilimi ne olursa olsun ekranda gördüğünüz saat kulüpteki gerçek ders'
              ' saatidir.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final sonuclar = _sonuclar;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yardım & SSS'),
        // 50 soruyu kaydırarak aramak cevabın bulunamaması demekti:
        // yapışkan arama kutusu + bölüm çipleri.
        bottom: SssArama(
          denetleyici: _aramaCtrl,
          onDegisti: (v) => setState(() => _sorgu = v),
          bolumler: [for (final b in _bolumler) b.baslik],
          seciliBolum: _seciliBolum,
          onBolum: (b) => setState(() => _seciliBolum = b),
          yaziOlcegi: MediaQuery.textScalerOf(context).scale(1.0),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          if (_sorgu.isEmpty && _seciliBolum == null)
            SliverToBoxAdapter(child: _ustKart()),
          if (sonuclar.isEmpty)
            SliverToBoxAdapter(child: SssSonucYok(sorgu: _sorgu))
          else
            for (final bolum in sonuclar) ...[
              SliverToBoxAdapter(child: _bolumBasligi(bolum)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: bolum.sorular.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SSSKarti(sss: bolum.sorular[i]),
                  ),
                ),
              ),
            ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _iletisimKarti(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _ustKart() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Size nasıl yardımcı olabiliriz?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yoklama, devir, iptal ve hakediş konularında en çok sorulanlar.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.sports_tennis_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bolumBasligi(_Bolum bolum) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Icon(bolum.ikon, size: 18, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              bolum.baslik,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iletisimKarti() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.10),
            Colors.amber.withValues(alpha: 0.10)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _epostaAc,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Destek & İletişim',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'binayakademi@gmail.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _epostaAc() async {
    final uri = Uri(scheme: 'mailto', path: 'binayakademi@gmail.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

/* -------------------------------------------------------------------------- */
/*                                  MODELLER                                  */
/* -------------------------------------------------------------------------- */

class _Bolum {
  final String baslik;
  final IconData ikon;
  final List<_SSS> sorular;

  const _Bolum({
    required this.baslik,
    required this.ikon,
    required this.sorular,
  });
}

class _SSS {
  final IconData ikon;
  final String soru;
  final String cevap;

  const _SSS({required this.ikon, required this.soru, required this.cevap});
}

/* -------------------------------------------------------------------------- */
/*                              AÇILIR SORU KARTI                             */
/* -------------------------------------------------------------------------- */

class _SSSKarti extends StatefulWidget {
  final _SSS sss;

  const _SSSKarti({required this.sss});

  @override
  State<_SSSKarti> createState() => _SSSKartiState();
}

class _SSSKartiState extends State<_SSSKarti>
    with SingleTickerProviderStateMixin {
  bool _acik = false;
  late AnimationController _kontrolcu;
  late Animation<double> _okDonusu;
  late Animation<double> _acilma;

  @override
  void initState() {
    super.initState();
    _kontrolcu = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _okDonusu = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _kontrolcu, curve: Curves.easeInOut),
    );
    _acilma = CurvedAnimation(parent: _kontrolcu, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _kontrolcu.dispose();
    super.dispose();
  }

  void _degistir() {
    setState(() {
      _acik = !_acik;
      if (_acik) {
        _kontrolcu.forward();
      } else {
        _kontrolcu.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _acik ? Colors.blue.withValues(alpha: 0.10) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _acik
              ? Colors.blue.shade200
              : Theme.of(context).colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: _acik
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: _acik ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _degistir,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _acik
                            ? Colors.blue.shade400
                            : Colors.blue.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.sss.ikon,
                        size: 20,
                        color: _acik ? Colors.white : Colors.blue.shade400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          widget.sss.soru,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _acik
                                ? Colors.blue.shade700
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: RotationTransition(
                        turns: _okDonusu,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _acik
                                ? Colors.blue.shade400
                                : Theme.of(context).colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: _acik
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizeTransition(
                  sizeFactor: _acilma,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      widget.sss.cevap,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
