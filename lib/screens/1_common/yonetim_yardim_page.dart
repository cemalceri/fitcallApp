// lib/screens/1_common/yonetim_yardim_page.dart
//
// Yönetici ve ofis kabuklarının Yardım & SSS sayfası.
//
// Neden var: iki kabuğun drawer'ındaki "Yardım" ortak `yardim_page.dart`'a
// gidiyordu; oradaki soruların hepsi üye diliyle yazılmış (kayıt olma, bakiye,
// paket, telafi). Ofis çalışanı "bakiyemi nasıl görürüm"ü okuyordu. Antrenör
// için 2026-08-10'da çözülen aynı hata bu iki kabukta duruyordu.
//
// Tek dosya, iki kapsam: sorular `_Kapsam` ile etiketli ve sayfa role göre
// süzüyor. Ayrı iki dosya tutmak, ortak soruları (QR, bildirim, tema) iki yerde
// güncellemek demekti.
//
// Cevaplar backend'deki kural kaynaklarından türetildi:
//   - iptal modları ve ürün tipi kısıtı  → calendarapp/services/etkinlik_iptal_service.py
//   - kalıcı silmenin etkisi             → calendarapp/services/etkinlik_silme_service.py
//   - ofisin göremediği alanlar          → api/ofis/metots.py (beyaz liste)
//   - hakediş grupları                   → api/yonetici/hakedis_servis.py
//   - QR sonuç kodları                   → lib/screens/1_common/widgets/qr_sonuc_gorunumu.dart
//   - bildirim türleri                   → calendarapp/models/concrete/notification.py
// Kural değişirse buradaki metin de güncellenmeli.
//
// Sayfa API çağırmadığı için doğrudan taşma testine giriyor
// (bkz. test/tasma_ekranlar_test.dart).

import 'package:fitcall/screens/1_common/widgets/sss_gorunumu.dart';
import 'package:flutter/material.dart';

/// Sorunun hangi kabukta görüneceği.
enum _Kapsam { ortak, ofis, yonetici }

class _KapsamliSoru {
  final _Kapsam kapsam;
  final SssSoru soru;
  const _KapsamliSoru(this.kapsam, this.soru);
}

class _KapsamliBolum {
  final String baslik;
  final IconData ikon;
  final List<_KapsamliSoru> sorular;
  const _KapsamliBolum(this.baslik, this.ikon, this.sorular);
}

class YonetimYardimPage extends StatelessWidget {
  /// true → ofis kabuğu, false → yönetici kabuğu.
  final bool ofis;

  const YonetimYardimPage({super.key, required this.ofis});

  @override
  Widget build(BuildContext context) {
    return SssGorunumu(
      baslik: 'Yardım & SSS',
      ustAciklama: ofis
          ? 'Program, ders iptali, QR ve üye işlemlerinde en çok sorulanlar.'
          : 'Panolar, raporlar, üye takibi ve hakediş konusunda en çok sorulanlar.',
      ustIkon: ofis ? Icons.support_agent_rounded : Icons.insights_rounded,
      bolumler: _bolumler(ofis),
    );
  }
}

/// Rol kapsamına göre süzülmüş bölüm listesi; boşalan bölüm hiç çizilmez.
List<SssBolum> _bolumler(bool ofis) {
  final hedef = ofis ? _Kapsam.ofis : _Kapsam.yonetici;
  final liste = <SssBolum>[];
  for (final bolum in _tumBolumler) {
    final sorular = [
      for (final s in bolum.sorular)
        if (s.kapsam == _Kapsam.ortak || s.kapsam == hedef) s.soru,
    ];
    if (sorular.isNotEmpty) {
      liste.add(SssBolum(
        baslik: bolum.baslik,
        ikon: bolum.ikon,
        sorular: sorular,
      ));
    }
  }
  return liste;
}

/* -------------------------------------------------------------------------- */
/*                                   İÇERİK                                   */
/* -------------------------------------------------------------------------- */

const _tumBolumler = <_KapsamliBolum>[
  /* ----------------------------- BAŞLARKEN ------------------------------ */
  _KapsamliBolum(
    'Başlarken',
    Icons.flag_outlined,
    [
      _KapsamliSoru(
        _Kapsam.ortak,
        SssSoru(
          ikon: Icons.compare_arrows_rounded,
          soru: 'Ofis profili ile yönetici profili arasındaki fark ne?',
          cevap:
              'İkisi ayrı kabuk, yetkileri de ayrı. Ofis (ön büro) profili işi'
              ' YAPAN taraftır: haftalık programda ders açar, düzenler, iptal eder,'
              ' QR doğrular, üye listesine bakar. Yönetici profili ise RAPORLAYAN'
              ' taraftır: ana sayfa, raporlar, bakiyeli üye listesi, antrenörler,'
              ' hakediş saatleri ve borçlu üyeler. Yönetici kabuğunda ders açma ya da'
              ' iptal etme ekranı bilerek yoktur; o işler ofiste toplanmıştır.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ortak,
        SssSoru(
          ikon: Icons.switch_account_outlined,
          soru: 'Birden fazla profilim var, aralarında nasıl geçiş yaparım?',
          cevap:
              'Ayarlar sayfasındaki "Profil değiştir" ile profil seçim ekranına'
              ' dönersiniz; oradan diğer profilinizi seçtiğinizde uygulama o rolün'
              ' kabuğuyla açılır. Aynı yere ana ekranın üst köşesindeki çift oklu'
              ' (⇄) butonla da gidebilirsiniz: yöneticide ana sayfanın başlığında, ofiste'
              ' haftalık programın başlığında, "Bugün"ün yanında. Her profil kendi'
              ' oturum anahtarıyla çalışır, yani yönetici olarak gördüğünüz veri ofis'
              ' profiline taşınmaz.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ortak,
        SssSoru(
          ikon: Icons.campaign_outlined,
          soru: 'Bir duyuruyu kimlerin gördüğünü nasıl anlarım?',
          cevap:
              '☰ menüdeki "Duyurular" sayfası duyuruları Yayında / Planlanan /'
              ' Geçmiş diye listeler; sağdaki oran, duyuruyu görebilecek hesapların'
              ' kaçının gördüğüdür. Duyuruya dokununca "Gördü" ve "Görmedi"'
              ' listeleri açılır; çocuk adıyla arayabilir, üyeye dokunup detayından'
              ' arayabilirsiniz. Sayım hesap bazındadır (veli ve çocukları tek hesap).'
              ' Ana sayfadaki duyuru yalnız açılınca, açılış popup\'ı ise ekrana'
              ' geldiğinde sayılır. Uygulamayı son 60 günde kullanmamış hesaplar'
              ' ayrı grupta durur. Duyuru oluşturma ve yayından kaldırma web'
              ' panelindedir; sayfanın sağ üstündeki bağlantı web panelinde açar.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.lock_outline_rounded,
          soru: 'Giriş yaparken "işletme tanımlı değil" hatası alıyorum.',
          cevap:
              'Ofis profilinin bağlı olduğu işletme alanı boş demektir. Uygulama'
              ' hangi kulübün verisini göstereceğini o alandan çözüyor; boşken hiçbir'
              ' veri gelmez. Kulüp yöneticisinin sistem kullanıcı kaydınızdaki işletme'
              ' alanını doldurması gerekir.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ortak,
        SssSoru(
          ikon: Icons.dark_mode_outlined,
          soru: 'Koyu temayı nasıl açarım?',
          cevap:
              'Ayarlar > Tema bölümünden Sistem, Açık veya Koyu seçebilirsiniz.'
              ' "Sistem" seçiliyken telefonun karanlık mod ayarına uyar. Yazı boyutu'
              ' telefonun kendi erişilebilirlik ayarından gelir; uygulama çok büyük'
              ' ölçeklerde yerleşim bozulmasın diye bir üst sınır uygular.',
        ),
      ),
    ],
  ),

  /* -------------------------- HAFTALIK PROGRAM -------------------------- */
  _KapsamliBolum(
    'Haftalık program',
    Icons.grid_view_rounded,
    [
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.table_chart_outlined,
          soru: 'Program ekranını nasıl okurum?',
          cevap:
              'Üstteki şeritten günü seçersiniz; altındaki ızgarada sütunlar kortları,'
              ' satırlar saatleri gösterir. Kort sayısı ekrana sığmıyorsa ızgara yana'
              ' kaydırılır. Dolu bir hücre o saatteki dersin bloğudur: ürün, antrenör ve'
              ' katılımcı bilgisini taşır; iptal edilmiş dersler "İptal" rozetiyle'
              ' ızgarada durmaya devam eder.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.add_circle_outline_rounded,
          soru: 'Yeni ders nasıl eklerim?',
          cevap:
              'Izgarada boş bir hücreye dokunun; ders formu o kort ve saat seçili'
              ' olarak açılır. Formda ürün, süre, ana antrenör, yardımcı antrenör'
              ' (opsiyonel), antrenör katsayısı, ekstra ücret ve katılımcılar yer alır.'
              ' Kaydettiğinizde doğrulamayı sunucu yapar — çakışma, kapasite ve ürün'
              ' kuralları web ile aynı servisten geçer, yani mobilden açılan ders web\'den'
              ' açılanla birebir aynı kurallara tabidir.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.edit_calendar_outlined,
          soru: 'Var olan bir dersi nasıl düzenlerim?',
          cevap:
              'Ders bloğuna dokunduğunuzda işlem sayfası açılır; oradaki "Düzenle" ile'
              ' aynı form dolu olarak gelir. Saat, kort, antrenör veya katılımcı'
              ' değişikliği burada yapılır. Ders geçmişte kaldıysa ya da yönetici onayı'
              ' verilmişse sunucu değişikliği reddedebilir.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.help_center_outlined,
          soru: 'İptal etmekle kalıcı silmek arasındaki fark ne?',
          cevap:
              'İptalde ders kayıtta kalır: 24 saat kuralı işler, telafi üretilir,'
              ' paket hakkı iade edilir ya da borç yazılır, kimin ne zaman iptal ettiği'
              ' görünür. Kalıcı silmede ders ve ona bağlı her şey yok olur — katılımcı'
              ' kayıtları, paket kullanımları, teyitler, onaylar ve değerlendirmeler.'
              ' En kritiği telafi hakları: bu dersin iptalinden doğmuş haklar birlikte'
              ' SİLİNİR, üyenin hakkı geri dönüşsüz kaybolur. Neredeyse her durumda'
              ' doğru işlem iptaldir; silme yalnız yanlışlıkla açılmış, hiç yaşanmamış'
              ' ders içindir.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.warning_amber_rounded,
          soru: 'Silme onayındaki sayılar ne anlama geliyor?',
          cevap:
              'Silmeden önce sunucuya "bu ders silinirse ne olur" diye sorulur ve'
              ' gelen sayım gösterilir: kaç katılımcı kaydı, kaç paket kullanımı, kaç'
              ' teyit/onay/değerlendirme silinecek; kaç telafi hakkı KAYBOLACAK ve kaç'
              ' telafi hakkı üyeye GERİ VERİLECEK. "Kaybolacak" satırı doluysa iki kez'
              ' düşünün: o hak bir daha oluşturulamaz.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.rule_rounded,
          soru: 'İptalde "işlem şekli" seçenekleri ne yapıyor?',
          cevap:
              'Dört seçenek var ve her biri yalnız kendi ürün tipinde anlamlıdır:\n\n'
              '• Standart — 24 saat kuralı normal işler (varsayılan).\n'
              '• Telafi ver — yalnız abonelik (aidat) dersinde: 24 saat şartı aranmaz,'
              ' telafi tanımlanır.\n'
              '• Paket hakkını iade et — yalnız paket dersinde: hak düşülmez, iade edilir.\n'
              '• Borç yazma — yalnız tek seferlik derste: borç yansıtılmaz.\n\n'
              'Ürün tipine uymayan seçenek hata verir. Bu bilinçli: eskiden paket'
              ' dersinde "Telafi ver" seçilebiliyor, hiçbir şey olmadığı hâlde ekran'
              ' "telafi tanımlandı" diyordu.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.undo_rounded,
          soru: 'Yanlışlıkla iptal ettim, geri alabilir miyim?',
          cevap:
              'Evet. İptal edilmiş dersin bloğuna dokunup "İptali geri al" deyin; ders'
              ' yeniden aktif olur ve açıklamasına kimin geri aldığı not düşülür.'
              ' İptalin otomatik yazdığı onay kaydı silinir: son 24 saatte yapılan'
              ' iptalde düşülen paket hakkı ya da yazılan tek ders borcu geri alınır,'
              ' antrenörün hakedişi yeniden karar bekler ve ders yeniden yönetici onayı'
              ' ister. Telafi tarafı da toparlanır, ama her şey otomatik dönmeyebilir:'
              ' iptalden doğan telafi hakkı bu arada KULLANILMIŞSA ya da telafi'
              ' dersine yeniden bağlanacak hak kalmamışsa ekranda uyarı çıkar. O'
              ' uyarıyı okumadan geçmeyin.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.badge_outlined,
          soru: 'Bir dersin kim tarafından iptal edildiğini nereden görürüm?',
          cevap:
              'İptal edilmiş dersin işlem sayfasında kırmızı bir künye paneli çıkar:'
              ' iptal eden kişi, iptal tarihi, iptal sebebi ve varsa iptal notu. Not,'
              ' iptal sırasında yazılan "açıklama" alanıdır — bu yüzden iptalli derslerde'
              ' ayrı bir açıklama satırı değil, künyenin içinde gösterilir.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.yonetici,
        SssSoru(
          ikon: Icons.event_note_outlined,
          soru: '"Dersler" sekmesi ile program ızgarası arasındaki fark ne?',
          cevap:
              'Izgara bir günün kort × saat yerleşimini gösterir — boş saatleri ve'
              ' çakışmaları orada görürsünüz. "Dersler" ise seçilen günün düz listesidir'
              ' ve duruma göre süzülür: Tümü, Tamamlandı, Bekliyor, İptal. Bir dersin'
              ' yoklaması girildi mi, onayı verildi mi sorusunun cevabı listede daha'
              ' hızlı bulunur.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.home_outlined,
          soru: 'Ana Sayfa\'daki bekleyen işler neler?',
          cevap: 'Üç iş listelenir, her birine dokununca ilgili ekran açılır:\n'
              '• Ders onayı — son 60 günde bitmiş ama "Yapıldı/Yapılmadı" kararı'
              ' verilmemiş dersler, gün gün. Daha eski dersler web panelinde.\n'
              '• Plan dışı / misafir kararı — antrenörün derse eklediği plan dışı'
              ' üyeler ve misafirler için borç, paket ya da ücretsiz kararı.\n'
              '• Katılım cevabı bekleyen — bugün ve yarınki derslerde katılım'
              ' bildirimine cevap vermemiş üyeler.\n'
              'Üstteki "Bugün" kartı günün ders sayısını gösterir; dokununca'
              ' Dersler sekmesine geçer.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.fact_check_outlined,
          soru: 'Ders nasıl onaylanır?',
          cevap:
              'Dersler sekmesinde günü seçip derse dokunun; ders bittiyse "Yapıldı"'
              ' ya da "Yapılmadı" düğmesi çıkar. Yapılmadı derken neden seçip not'
              ' yazabilirsiniz; bu dersteki plan dışı kararları da geri alınır.'
              ' Kararı yanlış verdiyseniz "Kararı kaldır" dersi yeniden onay'
              ' bekleyenlere döndürür. Antrenörün "yapıldı" dediği dersler listenin'
              ' üstündeki "Hepsini onayla" ile tek seferde onaylanır; antrenörün'
              ' yapılmadı dediği ya da bildirmediği derslere bu düğme dokunmaz.'
              ' Kurallar web\'deki Ders Yönetimi ile aynıdır.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.payments_outlined,
          soru: 'Hakediş "Alır / Almaz" ne demek?',
          cevap:
              'Antrenörün (ve varsa yardımcısının) o dersten ders ücreti alıp'
              ' almayacağının işaretidir; tutar görünmez, yalnız karar verilir.'
              ' Seçili olana yeniden dokunursanız karar kaldırılır. Varsayılanı'
              ' ders onayından gelir; özel bir durum yoksa değiştirmeniz gerekmez.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.person_add_alt_1_outlined,
          soru: 'Plan dışı / misafir kararı nasıl verilir?',
          cevap:
              'Menüden ya da Ana Sayfa\'dan "Plan dışı kararlar"ı açıp kişiye'
              ' dokunun. Üç seçenek var: Borç yaz (tutar girilir, ücreti üstlenen'
              ' kişinin hesabına yazılır), Paketten (seçilen kişinin aktif'
              ' paketinden bir hak düşülür) ve Ücretsiz. Açıklama zorunludur: kişi'
              ' ileride üye olursa borcun hangi dersten geldiği oradan anlaşılır.'
              ' Misafirden ödeme alma ve misafiri üyeye aktarma web panelindedir.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.how_to_reg_outlined,
          soru: 'Katılım cevabı vermeyen üye için ne yapabilirim?',
          cevap:
              'Gelecek bir derse dokunduğunuzda her katılımcının cevabı görünür.'
              ' Üye size telefonda ya da yüz yüze geleceğini söylediyse "Katılacak"'
              ' ile onun yerine işaretleyin. Cevap vermediyse "Hatırlat" uygulamadaki'
              ' hesabına yeniden katılım bildirimi gönderir.',
        ),
      ),
    ],
  ),

  /* ------------------------------- ÜYELER ------------------------------- */
  _KapsamliBolum(
    'Üyeler',
    Icons.people_outline_rounded,
    [
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.visibility_off_outlined,
          soru: 'Üye listesinde bakiye ve borç neden görünmüyor?',
          cevap:
              'Ofis profiline finansal ve özel bilgi hiç GÖNDERİLMİYOR; ekranda gizli'
              ' değil, sunucudan gelmiyor. Kapalı olanlar: bakiye, para hareketleri,'
              ' aylık özet, adres, meslek, acil durum kişisi, veli (anne/baba) bilgileri,'
              ' okul, doğum tarihi ve cinsiyet. Aynı nedenle listeyi bakiyeye göre'
              ' sıralayamaz ve "borçlu" filtresi uygulayamazsınız — sıralamanın kendisi'
              ' de kimin borçlu olduğunu ele verir. Bu bilgilere düzenli ihtiyacınız'
              ' varsa çözüm ekranı zorlamak değil, size yönetici profili tanımlanmasıdır.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.person_search_outlined,
          soru: 'Üye listesinde ne arayabilir, neye göre sıralayabilirim?',
          cevap:
              'Ad, soyad ve üye numarasıyla arama yapabilir; listeyi ada, üye numarasına'
              ' ya da son ders tarihine göre sıralayabilirsiniz. Filtreler: tümü, aktif,'
              ' pasif. Üyeye dokunduğunuzda detayda iletişim bilgileri, seviye, sorumlu'
              ' hoca, kayıt tarihi, paketleri ve yaklaşan/geçmiş dersleri açılır.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.yonetici,
        SssSoru(
          ikon: Icons.group_outlined,
          soru:
              'Üyeler listesindeki kartlar ve kaydırma hareketleri ne işe yarar?',
          cevap:
              'Üstteki Toplam, Aktif, Pasif, Borçlu ve Yeni kartları hem sayıyı'
              ' gösterir hem filtredir: dokununca liste süzülür. Borçlu en borçluyu,'
              ' Yeni bu ay kaydolanları önce gösterir; Toplam ada göre, baş harf'
              ' gruplarıyla listeler. Borç satırdaki kırmızı tutardan, pasiflik'
              ' rozetten okunur. Bir satırı yana kaydırınca'
              ' Ara ve WhatsApp kısayolları açılır; ekran okuyucuyla kullanıyorsanız aynı'
              ' eylemler satıra uzun basınca alt sayfada listelenir. Arama kutusu aşağı'
              ' kaydırınca gizlenir, yukarı çekince geri gelir.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.yonetici,
        SssSoru(
          ikon: Icons.account_balance_wallet_outlined,
          soru:
              '"Borçlu Üyeler" sayfası ile üye listesindeki borçlu grubu aynı mı?',
          cevap:
              'Aynı veriye iki farklı giriştir. Üye listesinde "Borçlu" kartı'
              ' borçluları en borçlu önce süzer; drawer\'daki "Borçlu Üyeler" sayfası yalnız'
              ' borçluları, toplam borç özetiyle birlikte listeler. Tahsilat turu'
              ' yapıyorsanız ikincisi daha pratiktir.',
        ),
      ),
    ],
  ),

  /* --------------------------------- QR --------------------------------- */
  _KapsamliBolum(
    'QR işlemleri',
    Icons.qr_code_scanner_rounded,
    [
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.qr_code_2_rounded,
          soru: 'QR Doğrula ekranını nasıl kullanırım?',
          cevap:
              'Kamerayı üyenin telefonundaki koda tutmanız yeterli; sonuç tüm ekranı'
              ' kaplayan renkli bir kartta çıkar, böylece kapıda uzaktan da okunur.'
              ' Kartın altındaki "Sonrakini tara" ile sıradaki kişiye geçersiniz —'
              ' ekrandan çıkıp yeniden girmenize gerek yok. Okutma saati kartta yazar.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.error_outline_rounded,
          soru: 'Doğrulama sonucundaki durumlar ne anlama geliyor?',
          cevap:
              'Yedi ayrı durum var, her birinin ne yapmanız gerektiği kartta yazılıdır:\n\n'
              '• Giriş onaylandı — geçebilir.\n'
              '• Kodun süresi dolmuş — kod hâlâ geçerli bir kayda ait ama zamanı geçmiş;'
              ' uygulamasından yeni kod üretmesini isteyin.\n'
              '• Kayıt bulunamadı — kod bu tesise ait değil.\n'
              '• Geçersiz kod — okutulan görsel bir giriş kodu bile değil.\n'
              '• Giriş iptal edilmiş — davet geri çekilmiş; daveti veren üyeye danışın.\n'
              '• Etkinlik uygun değil — kod bir etkinliğe bağlı, saati gelmemiş ya da geçmiş.\n'
              '• Doğrulanamadı — teknik hata; bağlantıyı kontrol edip tekrar deneyin.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ortak,
        SssSoru(
          ikon: Icons.qr_code_rounded,
          soru: 'QR Oluştur ne işe yarar?',
          cevap:
              'Misafir/geçici giriş kodu üretir. Kişinin adını ve kodun kaç dakika'
              ' geçerli olacağını yazarsınız; oluşan kodu WhatsApp veya başka bir'
              ' uygulamayla paylaşabilirsiniz. Aktif kodlar listede kalan süreleriyle'
              ' görünür, gerekirse süresi dolmadan iptal edilebilir. Kod ekranda'
              ' gösterilirken parlaklık otomatik artar ve zemin her temada beyaz kalır —'
              ' koyu temada okunamama sorunu için.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.no_photography_outlined,
          soru: 'Kamera izni istemedim / reddettim, ne olur?',
          cevap:
              'QR Doğrula kamerasız çalışmaz. İzni bir kez reddettiyseniz ekran sizi'
              ' telefonun uygulama ayarlarına yönlendirir; izni oradan açıp ekrana'
              ' dönmeniz yeterli. Kod üretme (QR Oluştur) kamera istemez.',
        ),
      ),
    ],
  ),

  /* --------------------------- PANOLAR & RAPOR -------------------------- */
  _KapsamliBolum(
    'Panolar ve raporlar',
    Icons.insights_outlined,
    [
      _KapsamliSoru(
        _Kapsam.yonetici,
        SssSoru(
          ikon: Icons.home_outlined,
          soru: 'Ana sayfa neyi gösteriyor?',
          cevap:
              'En üstte bugünün özeti (yeni üye, ders, doluluk). Bugün / Bu Hafta / Bu Ay'
              ' seçimi yalnız ona bağlı kartlarla (ciro, tahsilat, ders, iptal) aynı'
              ' kutudadır; aktif üye ve alacak "Şu an", haftalık grafik bu haftanın'
              ' günleridir. Bütün hesaplar sunucuda yapılır; uygulama kendi'
              ' başına toplama/çıkarma yapmaz. Bir bölümün verisi alınamazsa o bölüm'
              ' yanlış sayı göstermek yerine gizlenir.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.yonetici,
        SssSoru(
          ikon: Icons.bar_chart_rounded,
          soru: 'Raporlar sekmesinde neler var?',
          cevap:
              'İki kutu, ikisinin de kendi dönem seçimi var: "Ciro ve tahsilat" (özet'
              ' kartlar, günlük ciro ve tahsilat) ile "Kort ve antrenör" (kort'
              ' doluluğu, antrenör performansı). En alttaki ısı haritası her zaman bu'
              ' haftayı (Pzt–Paz, planlı dersler dahil) saat saat gösterir. Rapor'
              ' ekranları salt okunurdur — buradan bir kayıt değiştirilmez.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.yonetici,
        SssSoru(
          ikon: Icons.business_outlined,
          soru: 'Raporlardaki rakamlar beklediğimden düşük çıkıyor.',
          cevap:
              'Raporlar yalnız kendi işletmenizin verisini kapsar. Aynı sistemde birden'
              ' fazla işletme varsa profilinizin bağlı olduğu işletme dışındaki dersler,'
              ' üyeler ve tahsilatlar sayılmaz. Geçmişte iki işletmenin verisinin'
              ' karıştığı bir dönem yaşandıysa, düzeltmeden sonra rakamların düşmesi'
              ' beklenen davranıştır.',
        ),
      ),
    ],
  ),

  /* ------------------------------- HAKEDİŞ ------------------------------ */
  _KapsamliBolum(
    'Hakediş saatleri',
    Icons.schedule_rounded,
    [
      _KapsamliSoru(
        _Kapsam.yonetici,
        SssSoru(
          ikon: Icons.calendar_month_outlined,
          soru: 'Hakediş saatleri ekranı nasıl ilerliyor?',
          cevap:
              'Üç adım: önce ay ızgarasından ayı seçersiniz, altındaki liste o ayın'
              ' antrenör saatlerini gösterir (12 ay toplamı değil, seçili ay).'
              ' Antrenöre dokununca panosu aynı ayda açılır ve içeride diğer aylara'
              ' geçebilirsiniz. Panodan bir gruba dokununca o gruptaki derslerin listesi'
              ' gelir. Ekrana drawer\'daki "Hakediş Saatleri"nden ya da Antrenörler'
              ' sekmesinde bir antrenöre dokunarak girersiniz.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.yonetici,
        SssSoru(
          ikon: Icons.category_outlined,
          soru: 'Üç grup ne anlama geliyor?',
          cevap: '• Hakediş alacak — ders yapıldı ve hakedişe sayılıyor.\n'
              '• Bekliyor — henüz karar verilmemiş dersler; yoklama ya da yönetici onayı'
              ' tamamlanınca bir üst ya da alt gruba geçer.\n'
              '• Hakediş dışı — sayılmayacak dersler.\n\n'
              'Aynı saatte hem ana hem yardımcı antrenör olarak girilen dersler tekilleştirilir,'
              ' saat iki kez sayılmaz.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.yonetici,
        SssSoru(
          ikon: Icons.info_outline_rounded,
          soru: 'Bir ders neden "hakediş dışı" görünüyor?',
          cevap:
              'Kartın üzerinde sebebi yazar; üç sebepten biridir: ders iptal edilmiştir'
              ' (o zaman iptal künyesi de gösterilir), yönetici "ders yapılmadı" demiştir,'
              ' ya da yönetici o ders için "hakediş almaz" işaretlemiştir. Hakediş bayrağı'
              ' ders onayını ezer: yönetici iptal edilmiş bir ders için "hakediş alır"'
              ' derse ders yine hakediş grubunda görünür.',
        ),
      ),
    ],
  ),

  /* ----------------------------- BİLDİRİMLER ---------------------------- */
  _KapsamliBolum(
    'Bildirimler',
    Icons.notifications_outlined,
    [
      _KapsamliSoru(
        _Kapsam.ofis,
        SssSoru(
          ikon: Icons.inbox_outlined,
          soru: 'Ofis profiline hangi bildirimler geliyor?',
          cevap:
              'İki tür: (1) bir üye planlı derse "katılamayacağım" işaretlediğinde gelen'
              ' ders teyit bildirimi — dersin iptal olup olmadığını da yazar; (2) bir'
              ' antrenör derse plan dışı katılımcı eklediğinde ya da çıkardığında gelen'
              ' bildirim. Bildirimler Ana Sayfa\'nın başlığındaki zilden ve menüden'
              ' açılır; bildirime dokununca ilgili dersin detayı açılır. Plan dışı'
              ' katılımın kararı "Plan dışı kararlar" ekranından verilir.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.yonetici,
        SssSoru(
          ikon: Icons.notifications_off_outlined,
          soru: 'Yönetici profiline neden bildirim gelmiyor?',
          cevap:
              'Şu an yönetici rolüne otomatik gönderilen bir bildirim türü tanımlı'
              ' değil. Üyeye giden hatırlatmalar, antrenöre giden yoklama ve devir'
              ' bildirimleri ile ofise giden teyit/plan dışı katılım bildirimlerinin'
              ' hepsinin alıcısı başka rollerdir. Ön büroya düşen bildirimleri görmek'
              ' istiyorsanız ofis profiliyle girmeniz gerekir.',
        ),
      ),
      _KapsamliSoru(
        _Kapsam.ortak,
        SssSoru(
          ikon: Icons.phonelink_ring_outlined,
          soru: 'Bildirim gelmiyor, ne yapmalıyım?',
          cevap:
              'Sırayla kontrol edin: telefonun bildirim izni uygulamaya verilmiş mi'
              ' (Bildirimler sayfası izin kapalıysa uyarır), pil optimizasyonu uygulamayı'
              ' kısıtlıyor mu, ve doğru profille giriş yapmış mısınız — bildirimler role'
              ' göre gönderilir. İzni açtıktan sonra Bildirimler sayfasını bir kez'
              ' açmanız yeterli; cihaz kaydınız orada tazelenir.',
        ),
      ),
    ],
  ),
];
