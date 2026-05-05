// =================== BASE URL ===================
const String baseUrlProd = "https://www.binay.fit/api";
const String baseUrlLocal = "http://10.0.2.2:8000/api";
const String baseUrl = baseUrlProd;
// const String baseUrl = baseUrlLocal;

// =================== AUTH ===================
String loginUrl = "$baseUrl/getToken";
String createToken = "$baseUrl/createToken";
String getMyMembers = "$baseUrl/getMyMembers";
String registerUrl = "${baseUrl.replaceFirst('/api', '/auths')}/register";
String forgotPasswordUrl =
    "${baseUrl.replaceFirst('/api', '/auths')}/forgot-password";
String uyeSifreDegistir = "$baseUrl/uyeSifreDegistir";
String uyeKullaniciSil = "$baseUrl/uyeKullaniciSil";

// =================== ÜYE ===================
String uyeKaydet = "$baseUrl/uyeKaydet";
String getOdemeBilgileri = "$baseUrl/getAidatOdemeGecmisi";
String getUyeDersProgramiUrl = "$baseUrl/getUyeDersProgrami";
String getUyedersTalepListesi = "$baseUrl/getUyedersTalepListesi";
String silUyedersTalebi = "$baseUrl/silUyedersTalebi";
String getUyeUrunList = "$baseUrl/getUyeUrunList";
String getHaftalikDersBilgilerim = "$baseUrl/getHaftalikDersBilgilerim";
String getUrunListesiVeUyePaketleri = "$baseUrl/getUrunListesiVeUyePaketleri";
String getTelafiDersBilgileriUrl = "$baseUrl/getTelafiDersBilgileri";
String getAktifUyeListesiUrl = "$baseUrl/getAktifUyeListesi";

// =================== ANTRENÖR ===================
String getAntrenorGunlukEtkinlikler = "$baseUrl/getAntrenorGunlukEtkinlikler";
String getAntrenorHaftalikEtkinlikler =
    "$baseUrl/getAntrenorHaftalikEtkinlikler";
String antrenorDersYapildiBilgisi = "$baseUrl/antrenorDersYapildiBilgisi";
String getAntrenorOgrenciler = "$baseUrl/getAntrenorOgrenciler";
String getAntrenorUygunSaatleri = "$baseUrl/getAntrenorUygunSaatleri";
String getAntrenorHomeCardsUrl = "$baseUrl/getAntrenorHomeCards";
String dismissAntrenorHomeCardUrl = "$baseUrl/dismissAntrenorHomeCard";
String getAntrenorSonrakiDersUrl = "$baseUrl/getAntrenorSonrakiDers";
String dersDevirTalebiOlusturUrl = "$baseUrl/dersDevirTalebiOlustur";
String dersDevirTalebiCevaplaUrl = "$baseUrl/dersDevirTalebiCevapla";
String dersDevirTalebiGeriCekUrl = "$baseUrl/dersDevirTalebiGeriCek";
String getDersIcinAntrenorListesiUrl = "$baseUrl/getDersIcinAntrenorListesi";
String getDersDevirTalebiDetayUrl = "$baseUrl/getDersDevirTalebiDetay";

// =================== ETKİNLİK ===================
String setDersYapildiBilgisi = "$baseUrl/setDersYapildiBilgisi";
String getDersYapildiBilgisi = "$baseUrl/getDersYapildiBilgisi";
String dersTalebiOlustur = "$baseUrl/dersTalebiOlustur";
String setDersTeyit = "$baseUrl/setDersTeyit";
String setDersTalep = "$baseUrl/setDersTalep";
String setGenelDersTalep = "$baseUrl/setGenelDersTalep";
String getKortveAntrenorList = "$baseUrl/getKortveAntrenorList";
String setTeyitOkundu = "$baseUrl/setTeyitOkundu";
String getTeyitDetay = "$baseUrl/getTeyitDetay";
String setDersKatilimiUrl = "$baseUrl/setDersKatilimi";
String getDersKatilimlariUrl = "$baseUrl/getDersKatilimlari";

// =================== BİLDİRİM ===================
String getNotifications = "$baseUrl/getNotifications";
String setNotificationsRead = "$baseUrl/setNotificationsRead";
String getUnreadNotificationCount = "$baseUrl/getUnreadNotificationCount";
String getBildirimById = "$baseUrl/getBildirimById";
String notificationAction = "$baseUrl/n/"; // + token

// =================== MUHASEBE ===================
String getMuhasebeOzet = "$baseUrl/getMuhasebeOzet";
String getParaHareketi = "$baseUrl/getParaHareketi";
String odemeHesaplaUrl = "$baseUrl/odemeHesapla";
String odemeBaslatUrl = "$baseUrl/odemeBaslat";
String odemeDurumUrl = "$baseUrl/odemeDurum/";

// =================== QR & GEÇİŞ ===================
String qrInOrOut = "$baseUrl/qrInOrOut";
String qrKodDogrula = "$baseUrl/qrKodDogrula";
String cihazKaydetGuncelle = "$baseUrl/cihazKaydetGuncelle";

// =================== EVENT QR ===================
String getirEventAktif = "$baseUrl/getirEventAktif";
String getirEventSelfPass = "$baseUrl/getirEventSelfPass";
String listeleEventMisafirPass = "$baseUrl/listeleEventMisafirPass";
String olusturEventMisafirPass = "$baseUrl/olusturEventMisafirPass";
String silEventMisafirPass = "$baseUrl/silEventMisafirPass";

// =================== TESİS QR ===================
String getirTesisSelfPass = "$baseUrl/getirTesisSelfPass";
String listeleTesisMisafirPass = "$baseUrl/listeleTesisMisafirPass";
String olusturTesisMisafirPass = "$baseUrl/olusturTesisMisafirPass";
String silTesisMisafirPass = "$baseUrl/silTesisMisafirPass";

// =================== DİĞER ===================
String getGaleriImages = "$baseUrl/getGaleriImages";
String getDuyurular = "$baseUrl/getDuyurular";
String getMobilConfigs = "$baseUrl/getMobilConfigs";
String mobilLogKaydet = "$baseUrl/mobilLogKaydet";
String getAktifDuyurularUrl = "$baseUrl/getAktifDuyurular";
String getDuyuruDetayUrl = "$baseUrl/getDuyuruDetay";
String setDuyuruOkunduUrl = "$baseUrl/setDuyuruOkundu";

// Ders Onay
const String getDersOnayBilgisiUrl = "$baseUrl/getDersOnayBilgisi";
const String setDersOnayBilgisiUrl = "$baseUrl/setDersOnayBilgisi";

// Değerlendirme
const String getDersDegerlendirmeUrl = "$baseUrl/getDersDegerlendirme";
const String setDersDegerlendirmeUrl = "$baseUrl/setDersDegerlendirme";
const String getDersTumDegerlendirmelerUrl =
    "$baseUrl/getDersTumDegerlendirmeler";

// İptal Talebi
const String createIptalTalebiUrl = "$baseUrl/etkinlikIptalTalebiOlustur";
const String getIptalTalepleriUrl = "$baseUrl/getEtkinlikIptalTalepleri";
const String setIptalTalebiIslemUrl =
    "$baseUrl/setYoneticiIptalTalebiOnaylaReddet";
const String getKullaniciIptalTalepleriUrl =
    "$baseUrl/getKullaniciIptalTalepleri";
const String getDersIptalTalebiUrl = "$baseUrl/getDersIptalTalebi";
const String iptalTalebiGeriCekUrl = "$baseUrl/iptalTalebiGeriCek";

// =================== YÖNETİCİ ===================
const String yoneticiDashboard = "$baseUrl/yoneticiDashboard";
const String yoneticiRaporlar = "$baseUrl/yoneticiRaporlar";
const String yoneticiUyeler = "$baseUrl/yoneticiUyeler";
const String yoneticiAntrenorler = "$baseUrl/yoneticiAntrenorler";
const String yoneticiDersler = "$baseUrl/yoneticiDersler";
const String yoneticiDersDetay = "$baseUrl/yoneticiDersDetay";
