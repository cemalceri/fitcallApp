// lib/screens/1_common/widgets/duyuru_gorseli.dart

import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitcall/common/tema.dart';
import 'package:fitcall/screens/1_common/widgets/duyuru_varsayilan_poster.dart';
import 'package:flutter/material.dart';

/// Duyurunun kapak görseli — açılış popup'ı ve ana sayfa şeridi ortak.
///
/// Görsel kırpılmadan sığdırılır (afiş üstündeki yazılar kesilmesin); kalan
/// boşluk aynı görselin bulanık kopyasıyla dolar. Boş [url] ya da yüklenemeyen
/// görsel → kodla çizilmiş varsayılan poster. Üstüne metin yazılmaz: beyaz bir
/// afişte beyaz başlık okunmuyordu, başlık her zaman görselin dışında durur.
class DuyuruGorseli extends StatelessWidget {
  final String url;

  const DuyuruGorseli({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const DuyuruVarsayilanPoster();
    final gorsel = CachedNetworkImageProvider(url);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Yüklenirken düz marka zemini (iskelet değil: tek görsel, kısa süre).
        const ColoredBox(color: Marka.mavi),
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Image(
            image: gorsel,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        ColoredBox(color: Colors.black.withValues(alpha: 0.25)),
        Image(
          image: gorsel,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const DuyuruVarsayilanPoster(),
        ),
      ],
    );
  }
}
