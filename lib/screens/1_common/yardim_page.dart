// lib/screens/1_common/help/faq_page.dart
// ignore_for_file: constant_identifier_names

import 'package:fitcall/screens/1_common/widgets/sss_arama.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class YardimPage extends StatefulWidget {
  const YardimPage({super.key});

  @override
  State<YardimPage> createState() => _YardimPageState();
}

class _YardimPageState extends State<YardimPage> {
  final _aramaCtrl = TextEditingController();
  String _sorgu = '';

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  List<_FAQ> get _sonuclar {
    if (_sorgu.trim().isEmpty) return _faqs;
    final q = _sorgu.toLowerCase();
    return _faqs
        .where((f) =>
            f.question.toLowerCase().contains(q) ||
            f.answer.toLowerCase().contains(q))
        .toList();
  }

  static const _faqs = <_FAQ>[
    _FAQ(
      icon: Icons.person_add_outlined,
      question: 'Uygulamaya nasıl kayıt olurum?',
      answer:
          'Giriş ekranındaki "Kayıt ol" bağlantısıyla bilgilerinizi doldurarak kayıt'
          ' başvurusunda bulunabilirsiniz. Başvurunuz kulüp tarafından onaylandığında'
          ' hesabınız aktifleşir; kullanıcı adınız ve şifreniz SMS ve e-posta yoluyla'
          ' size iletilir.',
    ),
    _FAQ(
      icon: Icons.dashboard_outlined,
      question: 'Ana sayfada neler var, menüye nasıl ulaşırım?',
      answer:
          'En üstte bakiyenizi, kalan haklarınızı ve telafi derslerinizi özet'
          ' kartlarında görürsünüz. "Yapılacaklar" bölümünde sizi bekleyen işlemler'
          ' (katılım bildirimi, ödeme, ders değerlendirmesi) listelenir. Alttaki'
          ' çubuktan Takvim, Geçmiş, QR, Hareketler ve Hesabım sayfalarına; sol'
          ' üstteki ☰ menüsünden ise tüm sayfalara ve Yardım\'a ulaşabilirsiniz.',
    ),
    _FAQ(
      icon: Icons.calendar_month_outlined,
      question: 'Derslerimi nereden görürüm?',
      answer:
          'Alttaki "Takvim" ekranından haftalar ve günler arasında gezinerek geçmiş'
          ' ve planlanan derslerinizi görebilirsiniz. Bir güne dokunduğunuzda o günün'
          ' dersleri, bir derse dokunduğunuzda dersin detayları açılır. Sıradaki'
          ' dersiniz ana sayfada da gösterilir.',
    ),
    _FAQ(
      icon: Icons.how_to_reg_outlined,
      question: 'Bir derse katılıp katılmayacağımı nasıl bildiririm?',
      answer:
          'Kulüp bir ders için görüş istediğinde ana sayfada "Katılım geri bildirimi'
          ' bekleniyor" kartı görünür. Bu karta dokunduğunuzda bekleyen dersleriniz'
          ' listelenir; dersi seçip "Katılacağım" veya "Katılamayacağım" olarak'
          ' durumunuzu bildirebilirsiniz. Aynı istek size bildirim olarak da'
          ' ulaşabilir.',
    ),
    _FAQ(
      icon: Icons.event_busy_outlined,
      question: 'Bir derse katılamayacağımı nasıl bildiririm?',
      answer: 'Takvimde ilgili derse dokunup "Katılamayacağım" ile durumunuzu'
          ' iletebilirsiniz. Ders saatinden en az 24 saat önce yapılan bildirimlerde'
          ' telafi hakkı tanımlanır ve ders bir pakete dahilse paketinizden düşülmez.'
          ' İstisnai durumlarda kulüple iletişime geçmeniz gerekir; telafi hakkının'
          ' tanımlanması kulübün değerlendirmesindedir.',
    ),
    _FAQ(
      icon: Icons.notifications_active_outlined,
      question: 'Dersimi telefon takvimime ekleyebilir miyim?',
      answer:
          'Yaklaşan bir dersin detayında "Telefon Takvimine Ekle" butonuyla dersi'
          ' cihazınızın takvimine kaydedebilirsiniz. Böylece telefonunuz ders'
          ' öncesinde sizi hatırlatır.',
    ),
    _FAQ(
      icon: Icons.confirmation_number_outlined,
      question: 'Kalan haklarımı ve paketlerimi nereden görürüm?',
      answer:
          'Ana sayfadaki "Kalan Haklarım" kartına ya da menüdeki "Üyelik & Paket'
          ' Bilgilerim" bölümüne dokunabilirsiniz. Kayıtlarınız Paket, Aidat ve Tek'
          ' Ders başlıkları altında gruplanır; bir başlığa dokunduğunuzda o gruptaki'
          ' kayıtlar açılır.',
    ),
    _FAQ(
      icon: Icons.event_repeat_rounded,
      question: 'Telafi derslerim nedir, nereden takip ederim?',
      answer: 'Uygun koşullarda katılamadığınız derslerden kazandığınız telafi'
          ' haklarınızı ana sayfadaki "Telafi Derslerim" kartından veya menüden takip'
          ' edebilirsiniz. Geçerlilik tarihlerini, kullanılan ve aktif telafilerinizi'
          ' burada görürsünüz.',
    ),
    _FAQ(
      icon: Icons.account_balance_wallet_outlined,
      question: 'Bakiyemi ve hesap hareketlerimi nasıl görürüm?',
      answer:
          'Ana sayfadaki "Bakiye" kartına ya da alttaki "Hareketler" butonuna'
          ' dokunarak hesap hareketlerinizi zaman tüneli halinde görebilirsiniz.'
          ' Ödemeler kulübünüzün belirlediği yöntemlerle yapılır; ayrıntılı bilgi için'
          ' kulüp yönetimine başvurabilirsiniz.',
    ),
    _FAQ(
      icon: Icons.history_rounded,
      question: 'Geçmiş derslerimi görüp değerlendirebilir miyim?',
      answer: 'Alttaki "Geçmiş" ekranında tamamlanan derslerinizi aya göre'
          ' listeleyebilir, dilerseniz derse puan ve yorum bırakabilirsiniz. Ders'
          ' durumları renklerle gösterilir: yeşil katıldığınız/yapılan dersler,'
          ' kırmızı iptaller, sarı ise sonucu henüz girilmemiş (kulüp onayında)'
          ' derslerdir.',
    ),
    _FAQ(
      icon: Icons.qr_code_rounded,
      question: 'QR Giriş ne işe yarar?',
      answer:
          'Tesise girişte alttaki "QR Giriş" ekranındaki kodu okutarak hızlıca giriş'
          ' yapabilirsiniz. Kulübünüzde aktif bir etkinlik veya davet varsa, ilgili'
          ' buton da bu ekranda görünür.',
    ),
    _FAQ(
      icon: Icons.notifications_off_outlined,
      question: 'Bildirim gelmiyor, ne yapmalıyım?',
      answer:
          'Bildirimleri alabilmek için telefonunuzun ayarlarından uygulamaya bildirim'
          ' izni verdiğinizden emin olun. İzin kapalıyken yaklaşan ders, katılım'
          ' bildirimi ve duyuru bildirimleri size ulaşmaz.',
    ),
    _FAQ(
      icon: Icons.switch_account_outlined,
      question: 'Birden fazla profilim var, nasıl geçiş yaparım?',
      answer:
          'Hesabınıza birden fazla üye veya antrenör profili bağlıysa, üst köşedeki'
          ' profil alanından "Profil Seç" ekranına geçerek dilediğiniz profile geçiş'
          ' yapabilirsiniz.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final sonuclar = _sonuclar;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yardım & SSS'),
        // Arama kutusu listeyle kaymaz: 14 sorunun içinde cevabı aramak
        // kaydırmayla değil yazarak yapılır.
        bottom: SssArama(
          denetleyici: _aramaCtrl,
          onDegisti: (v) => setState(() => _sorgu = v),
          yaziOlcegi: MediaQuery.textScalerOf(context).scale(1.0),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          if (_sorgu.isEmpty) SliverToBoxAdapter(child: _buildHeaderCard()),
          if (sonuclar.isEmpty)
            SliverToBoxAdapter(child: SssSonucYok(sorgu: _sorgu))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList.builder(
                itemCount: sonuclar.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FAQTile(faq: sonuclar[index], index: index),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildContactCard(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
          ],
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
                  'En sık sorulan sorulara göz atın veya bize ulaşın.',
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
              Icons.help_outline_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.10),
            Colors.amber.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.16),
          width: 1,
        ),
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
          onTap: () => _launchEmail(),
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

  Future<void> _launchEmail() async {
    final uri = Uri(scheme: 'mailto', path: 'binayakademi@gmail.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _FAQTile extends StatefulWidget {
  final _FAQ faq;
  final int index;

  const _FAQTile({required this.faq, required this.index});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _iconRotation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _expanded
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded
              ? Colors.blue.shade200
              : Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _expanded
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: _expanded ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _expanded
                            ? Colors.blue.shade400
                            : Colors.blue.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.faq.icon,
                        size: 20,
                        color: _expanded ? Colors.white : Colors.blue.shade400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Question
                    Expanded(
                      child: Text(
                        widget.faq.question,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _expanded
                              ? Colors.blue.shade700
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    // Arrow
                    RotationTransition(
                      turns: _iconRotation,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _expanded
                              ? Colors.blue.shade400
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: _expanded
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                // Answer
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, left: 52),
                    child: Text(
                      widget.faq.answer,
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

class _FAQ {
  final IconData icon;
  final String question;
  final String answer;

  const _FAQ({
    required this.icon,
    required this.question,
    required this.answer,
  });
}
