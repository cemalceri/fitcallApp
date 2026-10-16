// App Store ekran görüntüsü boyutları.
//
// Her cihaz kendi mantıksal çözünürlüğünde, kendi güvenli alan boşluklarıyla
// çizilir; büyütme/küçültme yapılmaz. Piksel ölçüleri App Store Connect'in
// kabul ettiği boyutlardır.

import 'package:flutter/widgets.dart';

enum DurumCubuguTipi { dinamikAda, centik, ipad }

class MagazaCihazi {
  final String kod;
  final String ad;
  final Size mantiksal;
  final double pikselOrani;
  final EdgeInsets guvenliAlan;
  final DurumCubuguTipi cubuk;

  const MagazaCihazi({
    required this.kod,
    required this.ad,
    required this.mantiksal,
    required this.pikselOrani,
    required this.guvenliAlan,
    required this.cubuk,
  });

  Size get piksel => mantiksal * pikselOrani;

  bool get tablet => cubuk == DurumCubuguTipi.ipad;
}

/// iPhone 16 Pro Max — App Store Connect "6.9-inch" (1320 × 2868).
const iphone69 = MagazaCihazi(
  kod: 'iphone_6.9',
  ad: 'iPhone 6.9"',
  mantiksal: Size(440, 956),
  pikselOrani: 3,
  guvenliAlan: EdgeInsets.only(top: 62, bottom: 34),
  cubuk: DurumCubuguTipi.dinamikAda,
);

/// iPhone 16 Pro — App Store Connect "iPhone with Dynamic Island (medium
/// display)", 6.1"/6.3" (1206 × 2622). 2026-10'dan beri zorunlu grup bu.
const iphone63 = MagazaCihazi(
  kod: 'iphone_6.3',
  ad: 'iPhone 6.3"',
  mantiksal: Size(402, 874),
  pikselOrani: 3,
  guvenliAlan: EdgeInsets.only(top: 62, bottom: 34),
  cubuk: DurumCubuguTipi.dinamikAda,
);

/// iPhone 11 Pro Max — App Store Connect "6.5-inch" (1242 × 2688).
const iphone65 = MagazaCihazi(
  kod: 'iphone_6.5',
  ad: 'iPhone 6.5"',
  mantiksal: Size(414, 896),
  pikselOrani: 3,
  guvenliAlan: EdgeInsets.only(top: 44, bottom: 34),
  cubuk: DurumCubuguTipi.centik,
);

/// iPad Pro 13" (M4) — App Store Connect "13-inch iPad" (2064 × 2752).
const ipad13 = MagazaCihazi(
  kod: 'ipad_13',
  ad: 'iPad 13"',
  mantiksal: Size(1032, 1376),
  pikselOrani: 2,
  guvenliAlan: EdgeInsets.only(top: 24, bottom: 20),
  cubuk: DurumCubuguTipi.ipad,
);

const tumCihazlar = [iphone63, iphone69, iphone65, ipad13];
