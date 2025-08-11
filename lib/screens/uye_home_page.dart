import 'package:fitcall/common/routes.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/1_notification/notifications_bell.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:fitcall/services/etkinlik/etkinlik_service.dart';
import 'package:fitcall/services/core/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UyeHomePage extends StatefulWidget {
  const UyeHomePage({super.key});

  @override
  State<UyeHomePage> createState() => _UyeHomePageState();
}

class _UyeHomePageState extends State<UyeHomePage> {
  final List<Map<String, dynamic>> menuItems = [
    {
      'name': routeEnums[SayfaAdi.profil]!,
      'icon': Icons.person,
      'text': 'Bilgilerim'
    },
    {
      'name': routeEnums[SayfaAdi.muhasebe]!,
      'icon': Icons.payment,
      'text': 'Ödeme/Borç'
    },
    {
      'name': routeEnums[SayfaAdi.dersler]!,
      'icon': Icons.sports_tennis,
      'text': 'Derslerim'
    },
    {
      'name': routeEnums[SayfaAdi.uyeGenelDersTalep]!,
      'icon': Icons.sports_baseball,
      'text': 'Ders Taleplerim'
    },
    {
      'name': routeEnums[SayfaAdi.qrKodKayit]!,
      'icon': Icons.qr_code,
      'text': 'QR Kod İle Giriş'
    },
    {
      'name': routeEnums[SayfaAdi.yardim]!,
      'icon': Icons.help,
      'text': 'Yardım'
    },
  ];

  /* ---------------- Haftalık Program State ---------------- */
  final Map<int, List<EtkinlikModel>> _haftalik = {
    for (var k = 1; k <= 7; k++) k: []
  };
  bool _loadingWeek = true;
  EtkinlikModel? _nextLesson;

  @override
  void initState() {
    super.initState();
    NotificationService.refreshUnreadCount();
    _fetchWeek();
  }

  Future<void> _fetchWeek() async {
    try {
      final list = await EtkinlikService.getirHaftalikDersBilgilerim();

      final tmp = {for (var k = 1; k <= 7; k++) k: <EtkinlikModel>[]};
      for (final e in list) {
        tmp[e.baslangicTarihSaat.weekday]!.add(e);
      }

      final now = DateTime.now();
      final filtered =
          list.where((e) => e.baslangicTarihSaat.isAfter(now)).toList();
      final next = filtered.isEmpty
          ? null
          : filtered.reduce((a, b) =>
              a.baslangicTarihSaat.isBefore(b.baslangicTarihSaat) ? a : b);

      if (!mounted) return;
      setState(() {
        _haftalik
          ..clear()
          ..addAll(tmp);
        _nextLesson = next;
        _loadingWeek = false;
      });
    } catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, 'Hata: $e');
      setState(() => _loadingWeek = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gunler = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final tf = DateFormat('HH:mm');
    final df = DateFormat('d MMMM', 'tr_TR');

    String nextLessonText;
    if (_nextLesson == null) {
      nextLessonText = 'Planlı ders bulunmuyor';
    } else {
      nextLessonText = '${df.format(_nextLesson!.baslangicTarihSaat)}, '
          '${tf.format(_nextLesson!.baslangicTarihSaat)}–${tf.format(_nextLesson!.bitisTarihSaat)} '
          'Kort ${_nextLesson!.kortAdi}';
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          NotificationsBell(),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => AuthService.logout(context)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hoşgeldin! 🎾",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: menuItems.map(_buildMenuButton).toList(),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text("Bir Sonraki Dersin"),
                subtitle: Text(nextLessonText),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.pushNamed(context, routeEnums[SayfaAdi.dersler]!),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Haftalık Programım',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: _loadingWeek
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      itemBuilder: (_, i) {
                        final dayIdx = i + 1;
                        final dersler = _haftalik[dayIdx] ?? [];
                        final text = dersler.isEmpty
                            ? 'Boş'
                            : dersler
                                .map((e) =>
                                    '🎾 ${tf.format(e.baslangicTarihSaat)}')
                                .join('\n');
                        return _dayCard(gunler[i], text);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /* --------------------- Görsel iyileştirmeler --------------------- */
  Widget _buildMenuButton(Map<String, dynamic> item) => Padding(
        padding: const EdgeInsets.all(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, item['name']),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item['icon'], size: 34, color: Colors.blueAccent),
                const SizedBox(height: 6),
                Text(item['text'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );

  Widget _dayCard(String day, String activity) {
    final todayCode =
        DateFormat('E', 'tr_TR').format(DateTime.now()).substring(0, 3);
    final isToday = day == todayCode;

    final gradientColors = isToday
        ? [Colors.orange[100]!, Colors.orange[200]!]
        : [Colors.blue[50]!, Colors.blue[100]!];

    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(day,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(activity,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
