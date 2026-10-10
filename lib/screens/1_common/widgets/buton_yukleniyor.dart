// lib/screens/1_common/widgets/buton_yukleniyor.dart
//
// Buton içindeki ilerleme göstergesi. Rengini butonun ön plan renginden alır
// (Material butonları içeriği IconTheme ile sarar).
//
// Neden: göstergeler sabit beyaz yazılmıştı. Koyu temada ve açık ana renkli
// takım temalarında (Sarı-Lacivert, Siyah-Beyaz…) buton zemini açık renk
// olduğunda beyaz gösterge görünmüyordu.

import 'package:flutter/material.dart';

class ButonYukleniyorGostergesi extends StatelessWidget {
  final double kalinlik;

  const ButonYukleniyorGostergesi({super.key, this.kalinlik = 2});

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      strokeWidth: kalinlik,
      color: IconTheme.of(context).color,
    );
  }
}
