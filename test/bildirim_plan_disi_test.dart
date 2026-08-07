// Plan dışı katılımcı bildiriminin (OFIS_PLAN_DISI_KATILIM) mobil gösterimi.
//
// Bildirim ofise gidiyor: antrenör derse plan dışı üye/misafir eklediğinde ya
// da eklediğini sildiğinde backend üretiyor. Burada test edilen, bildirimin
// listede kendi ikon/rengiyle görünmesi ve detayında kimlerin eklenip
// çıkarıldığının gövde metnine ek olarak ayrıştırılmış biçimde okunması.

import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/screens/1_common/1_notification/pages/bildirim_detay_sheet.dart';
import 'package:fitcall/screens/1_common/1_notification/widgets/bildirim_ortak_widgetlari.dart';
import 'package:fitcall/screens/1_common/1_notification/widgets/plan_disi_bildirim_ozeti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _veri({
  String eklenenler = 'Ayşe Demir (üye), Mehmet Kaya (misafir)',
  String cikarilanlar = '',
}) =>
    {
      'etkinlik_id': 42,
      'tarih': '07.08.2026',
      'saat': '14:00',
      'kort_adi': 'Merkez Kort',
      'antrenor_adi': 'Ahmet Hoca',
      'eklenenler': eklenenler,
      'cikarilanlar': cikarilanlar,
    };

NotificationModel _bildirim({
  String tip = NotificationType.ofisPlanDisiKatilim,
  Map<String, dynamic>? displayData,
}) =>
    NotificationModel(
      id: 1,
      notificationType: tip,
      title: 'Plan Dışı Katılımcı',
      body: 'Ahmet Hoca, 7 Ağustos 2026 Cuma saat 14:00 Merkez Kort kortundaki '
          'ders için plan dışı Ayşe Demir (üye) ekledi.',
      actionType: ActionType.navigateToScreen,
      displayData: displayData,
      isRead: false,
      timestamp: DateTime(2026, 8, 7, 14, 5),
    );

Future<void> _bas(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
  await tester.pump();
}

void main() {
  group('PlanDisiBildirimOzeti', () {
    testWidgets('eklenen kişileri ayrı satırlarda listeler', (tester) async {
      await _bas(tester, PlanDisiBildirimOzeti(displayData: _veri()));

      expect(find.text('Derse eklendi'), findsOneWidget);
      expect(find.text('Ayşe Demir (üye)'), findsOneWidget);
      expect(find.text('Mehmet Kaya (misafir)'), findsOneWidget);
      // Ders künyesi de görünür
      expect(find.text('07.08.2026'), findsOneWidget);
      expect(find.text('Merkez Kort'), findsOneWidget);
    });

    testWidgets('çıkarılan yoksa o bölüm hiç render edilmez', (tester) async {
      await _bas(tester, PlanDisiBildirimOzeti(displayData: _veri()));

      expect(find.text('Dersten çıkarıldı'), findsNothing);
    });

    testWidgets('ekleme ve çıkarma birlikte gösterilir', (tester) async {
      await _bas(
        tester,
        PlanDisiBildirimOzeti(
          displayData: _veri(
            eklenenler: 'Mehmet Kaya (misafir)',
            cikarilanlar: 'Ayşe Demir (üye)',
          ),
        ),
      );

      expect(find.text('Derse eklendi'), findsOneWidget);
      expect(find.text('Dersten çıkarıldı'), findsOneWidget);
      expect(find.text('Mehmet Kaya (misafir)'), findsOneWidget);
      expect(find.text('Ayşe Demir (üye)'), findsOneWidget);
    });

    testWidgets('kişi listesi boşsa hiçbir şey çizmez', (tester) async {
      await _bas(
        tester,
        PlanDisiBildirimOzeti(
          displayData: _veri(eklenenler: '', cikarilanlar: ''),
        ),
      );

      expect(find.text('Derse eklendi'), findsNothing);
      expect(find.text('Dersten çıkarıldı'), findsNothing);
      expect(find.text('Merkez Kort'), findsNothing);
    });

    testWidgets('eksik display_data ile çökmez', (tester) async {
      await _bas(tester, const PlanDisiBildirimOzeti(displayData: {}));

      expect(tester.takeException(), isNull);
    });
  });

  group('BildirimDetaySheet', () {
    testWidgets('plan dışı bildiriminde özet bölümü açılır', (tester) async {
      await _bas(
        tester,
        BildirimDetaySheetWidget(
          notification: _bildirim(displayData: _veri()),
        ),
      );

      expect(find.byType(PlanDisiBildirimOzeti), findsOneWidget);
      expect(find.text('Derse eklendi'), findsOneWidget);
    });

    testWidgets('display_data yoksa özet aranmaz', (tester) async {
      await _bas(
        tester,
        BildirimDetaySheetWidget(notification: _bildirim()),
      );

      expect(find.byType(PlanDisiBildirimOzeti), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('başka tipte bildirimde özet gösterilmez', (tester) async {
      await _bas(
        tester,
        BildirimDetaySheetWidget(
          notification: _bildirim(
            tip: NotificationType.genel,
            displayData: _veri(),
          ),
        ),
      );

      expect(find.byType(PlanDisiBildirimOzeti), findsNothing);
    });
  });

  group('Bildirim ikon/renk eşlemesi', () {
    test('plan dışı bildiriminin kendi ikonu ve turuncu rengi var', () {
      const tip = NotificationType.ofisPlanDisiKatilim;

      expect(BildirimGorselYardimci.ikonGetir(tip),
          Icons.person_add_alt_1_rounded);
      expect(BildirimGorselYardimci.renkGetir(tip),
          BildirimRenkleri.uyariTuruncu);
    });

    test('tanınmayan tip varsayılan ikona düşer', () {
      expect(BildirimGorselYardimci.ikonGetir('BILINMEYEN_TIP'),
          Icons.notifications_rounded);
    });
  });
}
