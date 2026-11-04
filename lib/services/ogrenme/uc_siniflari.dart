// lib/services/ogrenme/uc_siniflari.dart
//
// Öğrenme modunda ağa çıkabilecek uçlar.
//
// Okumalar da POST ile yapıldığı için yöntem, yazmayı ayırt etmeye yetmiyor;
// ayrım uç adıyla yapılır (URL'de /api/'den sonraki parça, mağaza aracındaki
// sahte API ile aynı kural). Kapı fail-closed çalışır: yalnız okuma ve altyapı
// kümesindeki uç geçer, sınıflanmamış yeni bir uç dahil gerisi engellenir.
// Her uç tam olarak bir kümede durmalı (test/ogrenme/uc_sinif_mandal_test.dart);
// yeni uç eklendiğinde test onu sınıflandırmanı ister.

/// Veriyi değiştirmeyen uçlar. Bir uç buraya ancak backend view'ının kayıt
/// yazmadığı (okundu/görüldü işareti dahil) doğrulanınca girer.
const Set<String> okumaUclari = {
  'antrenorHaftalikProgram',
  'antrenorHakedisDersler',
  'antrenorHakedisOzet',
  'degerlendirmeListesi',
  'getAktifDuyurular',
  'getAktifUyeListesi',
  'getAntrenorCalismaGunleri',
  'getAntrenorEksikYoklamalar',
  'getAntrenorGunlukEtkinlikler',
  'getAntrenorGunlukOzet',
  'getAntrenorHaftalikEtkinlikler',
  'getAntrenorHomeCards',
  'getAntrenorOgrenciDetay',
  'getAntrenorOgrenciler',
  'getAntrenorSonrakiDers',
  'getDersDegerlendirme',
  'getDersDevirTalebiDetay',
  'getDersIcinAntrenorListesi',
  'getDersIptalTalebi',
  'getDersKatilimlari',
  'getDersOnayBilgisi',
  'getDersTumDegerlendirmeler',
  'getDuyuruDetay',
  'getHaftalikDersBilgilerim',
  'getKullaniciIptalTalepleri',
  'getMobilConfigs',
  'getMuhasebeOzet',
  'getMyMembers',
  'getNotifications',
  'getParaHareketi',
  'getPopupDuyuru',
  'getSurumNotuArsivi',
  'getSurumYenilikleri',
  'getTelafiDersBilgileri',
  'getTeyitDetay',
  'getUnreadNotificationCount',
  'getUyeDersProgrami',
  'getUyeGecmisDersler',
  'getUyeHomeOzet',
  'getUyeOdulDurumu',
  'getUyeTeyitBekleyenler',
  'getUyeUrunList',
  'getirEventAktif',
  'kayitFormVerileri',
  'listeleEventMisafirPass',
  'listeleTesisMisafirPass',
  'ofisBekleyenIsler',
  'ofisDersKayitTalepleri',
  'ofisDersYonetimiGun',
  'ofisPlanDisiBekleyenler',
  'ofisPlanDisiSecenekler',
  'ofisUyeDetay',
  'ofisUyeler',
  'uyeBankaHesaplari',
  'uyeDekontDosya',
  'uyeDekontlarim',
  'yoneticiAntrenorler',
  'yoneticiDashboard',
  'yoneticiDersler',
  'yoneticiDolulukHaritasi',
  'yoneticiDuyuruOkumaDurumu',
  'yoneticiEtkinlikFormVerileri',
  'yoneticiEtkinlikSilOnizleme',
  'yoneticiHaftalikProgram',
  'yoneticiHakedisAntrenorler',
  'yoneticiHakedisDersler',
  'yoneticiHakedisOzet',
  'yoneticiRaporlar',
  'yoneticiUyeDetay',
  'yoneticiUyeler',
};

/// İş verisine, bildirim hedefine ve hakedişe dokunmayan altyapı uçları:
/// cihaz kaydı (push) ve mobil log. Engellenselerdi push kaybolurdu.
const Set<String> altyapiUclari = {
  'cihazIzinGuncelle',
  'cihazKaydetGuncelle',
  'mobilLogKaydet',
};

/// Veri değiştiren ya da yan etkisi olan uçlar (okundu işareti, QR üretimi,
/// ödeme). Kapı bunları zaten engeller; burada yalnız her ucun bilinçli olarak
/// sınıflandığı görülsün diye sayılırlar.
const Set<String> yazmaUclari = {
  'createToken',
  'dersDevirTalebiCevapla',
  'dersDevirTalebiGeriCek',
  'dersDevirTalebiOlustur',
  'dersKayitTalebiGeriCek',
  'dersKayitTalebiOlustur',
  'dismissAntrenorHomeCard',
  'etkinlikIptalTalebiOlustur',
  'getirEventSelfPass',
  'getirTesisSelfPass',
  'iptalTalebiGeriCek',
  'n',
  'odemeBaslat',
  'odemeDurum',
  'odemeHesapla',
  'odulTalepEt',
  'ofisDersHakedis',
  'ofisDersKayitTalebiReddet',
  'ofisDersOnay',
  'ofisGunuOnayla',
  'ofisManuelTeyit',
  'ofisPaketDusum',
  'ofisPlanDisiKarar',
  'ofisTeyitHatirlat',
  'olusturEventMisafirPass',
  'olusturTesisMisafirPass',
  'qrKodDogrula',
  'setAntrenorCalismaGunleri',
  'setDersDegerlendirme',
  'setDersKatilimi',
  'setDersOnayBilgisi',
  'setDersTeyit',
  'setDuyuruOkundu',
  'setNotificationsDeleted',
  'setNotificationsRead',
  'setSurumYenilikGorundu',
  'setTeyitOkundu',
  'sifremiUnuttum',
  'silEventMisafirPass',
  'silTesisMisafirPass',
  'uyeBasvuru',
  'uyeDekontGeriCek',
  'uyeDekontYukle',
  'uyeKullaniciSil',
  'uyeProfilFotografi',
  'uyeProfilFotografiSil',
  'uyeSifreDegistir',
  'yoneticiDuyurular',
  'yoneticiEtkinlikIptal',
  'yoneticiEtkinlikIptalGeriAl',
  'yoneticiEtkinlikKaydet',
  'yoneticiEtkinlikSil',
};

/// URL'nin uç adı: `/api/` sonrasındaki ilk parça ("…/api/getTeyitDetay?x=1"
/// → "getTeyitDetay"). `/api/` yoksa son parça.
String ucAdi(String url) {
  final parcalar = Uri.parse(url).pathSegments.where((p) => p.isNotEmpty);
  final liste = parcalar.toList();
  final api = liste.indexOf('api');
  if (api >= 0 && api + 1 < liste.length) return liste[api + 1];
  return liste.isEmpty ? '' : liste.last;
}
