// lib/screens/1_common/help/faq_page.dart
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class YardimPage extends StatelessWidget {
  const YardimPage({super.key});

  static const _faqs = <_FAQ>[
    _FAQ(
      icon: Icons.person_add_outlined,
      question: 'Uygulamaya nasıl kayıt olurum?',
      answer:
          'Kulüp yönetiminden aldığınız "davet kodu" ile kayıt ekranındaki ilgili'
          ' alana kodu girin ve formu doldurun. Ardından hesabınız onaylandığında'
          ' giriş yapabilirsiniz.',
    ),
    _FAQ(
      icon: Icons.calendar_month_outlined,
      question: 'Ders nasıl rezerve ederim?',
      answer:
          'Derslerim > Takvim sayfasına gidin, müsait saat seçin ve "Ders Talep Et"'
          ' butonuna tıklayın. Antrenörünüz talebi onayladığında bildirim alırsınız.',
    ),
    _FAQ(
      icon: Icons.cancel_outlined,
      question: 'Ders iptal politikası nedir?',
      answer:
          'Ders saatinden en az 24 saat önce iptal ederseniz hak düşmez. Daha geç'
          ' iptallerde ders hakkınız kullanılmış sayılır.',
    ),
    _FAQ(
      icon: Icons.payment_outlined,
      question: 'Ödemeleri nasıl yaparım?',
      answer:
          'Ödeme/Borç ekranında açık bakiyenizi görebilir ve kredi kartı ile anında'
          ' ödeme gerçekleştirebilirsiniz. Ayrıca kulüp resepsiyonundan nakit veya'
          ' EFT ile de ödeme yapabilirsiniz.',
    ),
    _FAQ(
      icon: Icons.swap_horiz_outlined,
      question: 'Antrenörümü nasıl değiştirebilirim?',
      answer:
          'Profil > Antrenörüm bölümünden "Değiştir"e basın ve listeden uygun'
          ' antrenörü seçin. Kulüp onayından sonra değişiklik aktif olur.',
    ),
    _FAQ(
      icon: Icons.autorenew_outlined,
      question: 'Paket haklarım ne zaman yenilenir?',
      answer:
          'Aylık paketlerde haklar her 30 günde bir, paket başlangıç tarihine'
          ' göre otomatik olarak yenilenir.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Modern App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      _buildBackButton(context),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Yardım & SSS',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Sıkça sorulan sorular',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Header Illustration
              SliverToBoxAdapter(
                child: _buildHeaderCard(),
              ),

              // FAQ List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FAQTile(
                          faq: _faqs[index],
                          index: index,
                        ),
                      );
                    },
                    childCount: _faqs.length,
                  ),
                ),
              ),

              // Contact Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildContactCard(),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
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
                const Text(
                  'Size nasıl yardımcı olabiliriz?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
            child: const Icon(
              Icons.help_outline_rounded,
              size: 40,
              color: Colors.white,
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
            Colors.orange.shade50,
            Colors.amber.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.shade100,
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
                      const Text(
                        'Destek & İletişim',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'binayakademi@gmail.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
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
        color: _expanded ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded ? Colors.blue.shade200 : Colors.grey.shade100,
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
                            : Colors.blue.shade50,
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
                              : const Color(0xFF1E293B),
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
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color:
                              _expanded ? Colors.white : Colors.grey.shade600,
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
                        color: Colors.grey.shade700,
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
