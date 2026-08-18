// lib/common/cihaz_takvimi.dart
//
// Dersi telefonun kendi takvim uygulamasına ekleme — üye ve antrenör için TEK
// yer. (Uygulama içindeki ders takvimi bu değil, o `screens/*/takvim/`.)
//
// Add2Calendar tarihi epoch milisaniye olarak gönderir, yani GERÇEK an ister.
// Uygulamadaki tarihler kulüp duvar saati olduğu için önce `kulupAnI()` ile
// gerçek ana çevriliyor ve saat dilimi açıkça yazılıyor; aksi halde saat dilimi
// Europe/Istanbul olmayan bir telefonun takviminde ders yanlış zamana düşer
// (hatırlatıcı da yanlış saatte çalar).

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:flutter/services.dart';

/// Dersi cihaz takvimine ekler (takvim uygulamasının kendi ekranı açılır).
Future<void> dersiCihazTakvimineEkle(EtkinlikModel ders) async {
  HapticFeedback.lightImpact();

  final aciklamaParcalari = [
    if ((ders.antrenorAdi ?? '').isNotEmpty) 'Antrenör: ${ders.antrenorAdi}',
    if ((ders.urunAdi ?? '').isNotEmpty) 'Program: ${ders.urunAdi}',
  ];

  await Add2Calendar.addEvent2Cal(
    Event(
      title: 'Tenis Dersi — ${ders.kortAdi}',
      description: aciklamaParcalari.join('\n'),
      location: ders.kortAdi,
      startDate: kulupAnI(ders.baslangicTarihSaat),
      endDate: kulupAnI(ders.bitisTarihSaat),
      timeZone: 'Europe/Istanbul',
      iosParams: const IOSParams(reminder: Duration(hours: 1)),
    ),
  );
}
