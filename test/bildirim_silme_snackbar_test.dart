// Bildirim silme uyarısının (notification_page.dart `_bildirimSil`) davranışı.
// Gerçek sayfa ağ/izin servislerine bağlı olduğundan aynı kalıp küçük bir
// düzenekte yeniden kuruldu: önceki uyarıyı kaldır, yenisini göster, kapanınca
// (geri alınmadıysa) sil; dispose'ta güncel uyarıyı kaldır.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

final List<int> silinenler = [];

class _Sayfa extends StatefulWidget {
  const _Sayfa();

  @override
  State<_Sayfa> createState() => _SayfaState();
}

class _SayfaState extends State<_Sayfa> {
  List<int> _liste = [1, 2, 3, 4];
  ScaffoldMessengerState? _messenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    final messenger = _messenger;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => messenger?.removeCurrentSnackBar());
    super.dispose();
  }

  Future<void> _sil(int id) async {
    final eskiListe = _liste;
    setState(() => _liste = [for (final n in _liste) if (n != id) n]);
    final messenger = ScaffoldMessenger.of(context)..removeCurrentSnackBar();
    final sonuc = await messenger
        .showSnackBar(
          SnackBar(
            content: const Text('Bildirim silindi'),
            action: SnackBarAction(label: 'Geri al', onPressed: () {}),
            duration: const Duration(seconds: 4),
            persist: false,
          ),
        )
        .closed;
    if (sonuc == SnackBarClosedReason.action) {
      if (mounted) setState(() => _liste = eskiListe);
      return;
    }
    silinenler.add(id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: ListView(children: [
          for (final n in _liste)
            ListTile(
              title: Text('Bildirim $n'),
              trailing: IconButton(
                key: Key('sil$n'),
                icon: const Icon(Icons.delete),
                onPressed: () => _sil(n),
              ),
            ),
        ]),
      );
}

Widget _uygulama() => MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const _Sayfa())),
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    );

Future<void> _ac(WidgetTester tester) async {
  await tester.pumpWidget(_uygulama());
  await tester.tap(find.text('Aç'));
  await tester.pumpAndSettle();
}

// Ticker'lar kare kare ilerlesin diye zamanı küçük adımlarla ilerletir.
Future<void> _bekle(WidgetTester tester, Duration d) async {
  for (var t = Duration.zero; t < d; t += const Duration(milliseconds: 50)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(silinenler.clear);

  testWidgets('arka arkaya silmede tek uyarı görünür, kuyruk birikmez',
      (tester) async {
    await _ac(tester);
    for (final id in [1, 2, 3]) {
      await tester.tap(find.byKey(Key('sil$id')));
      await _bekle(tester, const Duration(milliseconds: 600));
      expect(find.text('Bildirim silindi'), findsOneWidget);
    }
    // Öncekiler kapandı ve silindi.
    expect(silinenler, [1, 2]);
    // Son uyarı kapanınca arkasında bekleyen başka uyarı olmamalı.
    await _kapat(tester);
    expect(find.text('Bildirim silindi'), findsNothing);
    expect(silinenler, [1, 2, 3]);
  });

  testWidgets('sayfadan çıkınca uyarı kapanır, bekleyen silme gönderilir',
      (tester) async {
    await _ac(tester);
    await tester.tap(find.byKey(const Key('sil2')));
    await _bekle(tester, const Duration(milliseconds: 600));
    expect(find.text('Bildirim silindi'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Bildirim silindi'), findsNothing);
    expect(silinenler, [2]);
  });

  testWidgets('"Geri al" bildirimi geri getirir ve silmez', (tester) async {
    await _ac(tester);
    await tester.tap(find.byKey(const Key('sil3')));
    await _bekle(tester, const Duration(milliseconds: 600));
    expect(find.text('Bildirim 3'), findsNothing);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();
    expect(find.text('Bildirim 3'), findsOneWidget);
    expect(find.text('Bildirim silindi'), findsNothing);
    await _bekle(tester, const Duration(seconds: 10));
    expect(silinenler, isEmpty);
  });

  // Uç durum: önceki uyarı kapanma animasyonundayken (~250 ms) gelen silmeler.
  testWidgets('çok hızlı silmede uyarılar kuyrukta birikmez', (tester) async {
    await _ac(tester);
    await tester.tap(find.byKey(const Key('sil1')));
    await _bekle(tester, const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const Key('sil2')));
    await _bekle(tester, const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('sil3')));
    await tester.pumpAndSettle();
    expect(find.text('Bildirim silindi'), findsOneWidget);

    // Görünen uyarı kapanınca ikinci bir uyarı gelmemeli.
    await _kapat(tester);
    expect(find.text('Bildirim silindi'), findsNothing,
        reason: 'kapanmakta olan uyarının arkasına birden fazla uyarı '
            'sıraya girdi');
  });

  testWidgets('uyarı 4 sn sonra kendiliğinden kapanır, silme gönderilir',
      (tester) async {
    await _ac(tester);
    await tester.tap(find.byKey(const Key('sil4')));
    await _bekle(tester, const Duration(seconds: 6));
    expect(find.text('Bildirim silindi'), findsNothing);
    expect(silinenler, [4]);
  });
}

Future<void> _kapat(WidgetTester tester) async {
  tester
      .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
      .hideCurrentSnackBar();
  await tester.pumpAndSettle();
}
