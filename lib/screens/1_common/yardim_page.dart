// lib/screens/1_common/help/faq_page.dart
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

class YardimPage extends StatelessWidget {
  const YardimPage({super.key});

  static const _faqs = <_FAQ>[
    _FAQ(
      question: 'Uygulamaya nasıl kayıt olurum?',
      answer:
          'Kulüp yönetiminden aldığınız “davet kodu” ile kayıt ekranındaki ilgili'
          ' alana kodu girin ve formu doldurun. Ardından hesabınız onaylandığında'
          ' giriş yapabilirsiniz.',
    ),
    _FAQ(
      question: 'Ders nasıl rezerve ederim?',
      answer:
          'Derslerim > Takvim sayfasına gidin, müsait saat seçin ve “Ders Talep Et”'
          ' butonuna tıklayın. Antrenörünüz talebi onayladığında bildirim alırsınız.',
    ),
    _FAQ(
      question: 'Ders iptal politikası nedir?',
      answer:
          'Ders saatinden en az 6 saat önce iptal ederseniz hak düşmez. Daha geç'
          ' iptallerde ders hakkınız kullanılmış sayılır.',
    ),
    _FAQ(
      question: 'Ödemeleri nasıl yaparım?',
      answer:
          'Ödeme/Borç ekranında açık bakiyenizi görebilir ve kredi kartı ile anında'
          ' ödeme gerçekleştirebilirsiniz. Ayrıca kulüp resepsiyonundan nakit veya'
          ' EFT ile de ödeme yapabilirsiniz.',
    ),
    _FAQ(
      question: 'Antrenörümü nasıl değiştirebilirim?',
      answer:
          'Profil > Antrenörüm bölümünden “Değiştir”e basın ve listeden uygun'
          ' antrenörü seçin. Kulüp onayından sonra değişiklik aktif olur.',
    ),
    _FAQ(
      question: 'Paket haklarım ne zaman yenilenir?',
      answer:
          'Aylık paketlerde haklar her 30 günde bir, paket başlangıç tarihine'
          ' göre otomatik olarak yenilenir.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yardım & SSS')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length + 1, // +1: iletişim kartı
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          if (i < _faqs.length) {
            final faq = _faqs[i];
            return _FAQTile(faq: faq);
          }
          // En alttaki iletişim kutusu
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.email, color: Colors.blueAccent),
              title: const Text('Destek & İletişim'),
              subtitle: const Text('Her türlü sorunuz için bize yazın'),
              trailing: const Text('destek@teniskulubu.com',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                // mailto linki açmak istiyorsanız url_launcher ekleyip açabilirsiniz
              },
            ),
          );
        },
      ),
    );
  }
}

class _FAQTile extends StatefulWidget {
  final _FAQ faq;
  const _FAQTile({required this.faq});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(widget.faq.question,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onExpansionChanged: (v) => setState(() => _expanded = v),
        trailing: Icon(
          _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.blueAccent,
        ),
        children: [
          Text(widget.faq.answer),
        ],
      ),
    );
  }
}

class _FAQ {
  final String question;
  final String answer;
  const _FAQ({required this.question, required this.answer});
}
