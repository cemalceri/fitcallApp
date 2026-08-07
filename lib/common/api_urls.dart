// =================== BASE URL ===================
const String baseUrlProd = "https://www.binay.fit/api";
const String baseUrlLocal = "http://10.0.2.2:8000/api";
const String baseUrl = baseUrlProd;
// const String baseUrl = baseUrlLocal;

// =================== AUTH ===================
String createToken = "$baseUrl/createToken";
String getMyMembers = "$baseUrl/getMyMembers";
String registerUrl = "${baseUrl.replaceFirst('/api', '/auths')}/register";
String forgotPasswordUrl =
    "${baseUrl.replaceFirst('/api', '/auths')}/forgot-password";
String uyeSifreDegistir = "$baseUrl/uyeSifreDegistir";
String uyeKullaniciSil = "$baseUrl/uyeKullaniciSil";

// =================== ÜYE ===================
String getUyeDersProgramiUrl = "$baseUrl/getUyeDersProgrami";
String getUyeUrunList = "$baseUrl/getUyeUrunList";
String getHaftalikDersBilgilerim = "$baseUrl/getHaftalikDersBilgilerim";
String getUrunListesiVeUyePaketleri = "$baseUrl/getUrunListesiVeUyePaketleri";
String getTelafiDersBilgileriUrl = "$baseUrl/getTelafiDersBilgileri";
String getAktifUyeListesiUrl = "$baseUrl/getAktifUyeListesi";
String getUyeHomeOzetUrl = "$baseUrl/getUyeHomeOzet";
String getUyeGecmisDerslerUrl = "$baseUrl/getUyeGecmisDersler";

// =================== ANTRENÖR ===================
String getAntrenorGunlukEtkinlikler = "$baseUrl/getAntrenorGunlukEtkinlikler";
String getAntrenorHaftalikEtkinlikler =
    "$baseUrl/getAntrenorHaftalikEtkinlikler";
String antrenorDersYapildiBilgisi = "$baseUrl/antrenorDersYapildiBilgisi";
String getAntrenorOgrenciler = "$baseUrl/getAntrenorOgrenciler";
String getAntrenorHomeCardsUrl = "$baseUrl/getAntrenorHomeCards";
String dismissAntrenorHomeCardUrl = "$baseUrl/dismissAntrenorHomeCard";
String getAntrenorSonrakiDersUrl = "$baseUrl/getAntrenorSonrakiDers";
String dersDevirTalebiOlusturUrl = "$baseUrl/dersDevirTalebiOlustur";
String dersDevirTalebiCevaplaUrl = "$baseUrl/dersDevirTalebiCevapla";
String dersDevirTalebiGeriCekUrl = "$baseUrl/dersDevirTalebiGeriCek";
String getDersIcinAntrenorListesiUrl = "$baseUrl/getDersIcinAntrenorListesi";
String getDersDevirTalebiDetayUrl = "$baseUrl/getDersDevirTalebiDetay";
String getAntrenorGunlukOzetUrl = "$baseUrl/getAntrenorGunlukOzet";
String getAntrenorEksikYoklamalarUrl = "$baseUrl/getAntrenorEksikYoklamalar";
String getAntrenorOgrenciDetayUrl = "$baseUrl/getAntrenorOgrenciDetay";
String getAntrenorCalismaGunleriUrl = "$baseUrl/getAntrenorCalismaGunleri";
String setAntrenorCalismaGunleriUrl = "$baseUrl/setAntrenorCalismaGunleri";

// Antrenörün kendi hakediş saatleri — antrenör id'si TAŞIMAZ, backend token'dan çözer
const String antrenorHakedisOzetUrl = "$baseUrl/antrenorHakedisOzet";
const String antrenorHakedisDerslerUrl = "$baseUrl/antrenorHakedisDersler";

// =================== ETKİNLİK ===================
String setDersTeyit = "$baseUrl/setDersTeyit";
String setDersTalep = "$baseUrl/setDersTalep";
String setTeyitOkundu = "$baseUrl/setTeyitOkundu";
String getTeyitDetay = "$baseUrl/getTeyitDetay";
String getUyeTeyitBekleyenlerUrl = "$baseUrl/getUyeTeyitBekleyenler";
String setDersKatilimiUrl = "$baseUrl/setDersKatilimi";
String getDersKatilimlariUrl = "$baseUrl/getDersKatilimlari";

// =================== BİLDİRİM ===================
String getNotifications = "$baseUrl/getNotifications";
String setNotificationsRead = "$baseUrl/setNotificationsRead";
String setNotificationsDeleted = "$baseUrl/setNotificationsDeleted";
String getUnreadNotificationCount = "$baseUrl/getUnreadNotificationCount";
String notificationAction = "$baseUrl/n/"; // + token

// =================== MUHASEBE ===================
String getMuhasebeOzet = "$baseUrl/getMuhasebeOzet";
String getParaHareketi = "$baseUrl/getParaHareketi";
String odemeHesaplaUrl = "$baseUrl/odemeHesapla";
String odemeBaslatUrl = "$baseUrl/odemeBaslat";
String odemeDurumUrl = "$baseUrl/odemeDurum/";

// =================== QR & GEÇİŞ ===================
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

// =================== ÖDÜL (TURNİKE SADAKAT SAYACI) ===================
String getUyeOdulDurumuUrl = "$baseUrl/getUyeOdulDurumu";
String odulTalepEtUrl = "$baseUrl/odulTalepEt";

// =================== DİĞER ===================
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
const String getKullaniciIptalTalepleriUrl =
    "$baseUrl/getKullaniciIptalTalepleri";
const String getDersIptalTalebiUrl = "$baseUrl/getDersIptalTalebi";
const String iptalTalebiGeriCekUrl = "$baseUrl/iptalTalebiGeriCek";

// =================== YÖNETİCİ ===================
const String yoneticiDashboard = "$baseUrl/yoneticiDashboard";
const String yoneticiRaporlar = "$baseUrl/yoneticiRaporlar";
const String yoneticiUyeler = "$baseUrl/yoneticiUyeler";
const String yoneticiUyeDetay = "$baseUrl/yoneticiUyeDetay";
const String yoneticiAntrenorler = "$baseUrl/yoneticiAntrenorler";
const String yoneticiDersler = "$baseUrl/yoneticiDersler";
const String yoneticiDolulukHaritasi = "$baseUrl/yoneticiDolulukHaritasi";

// Yönetici - ders (etkinlik) yönetimi
const String yoneticiHaftalikProgramUrl = "$baseUrl/yoneticiHaftalikProgram";
const String yoneticiEtkinlikFormVerileriUrl =
    "$baseUrl/yoneticiEtkinlikFormVerileri";
const String yoneticiEtkinlikKaydetUrl = "$baseUrl/yoneticiEtkinlikKaydet";
const String yoneticiEtkinlikIptalUrl = "$baseUrl/yoneticiEtkinlikIptal";
const String yoneticiEtkinlikIptalGeriAlUrl =
    "$baseUrl/yoneticiEtkinlikIptalGeriAl";
const String yoneticiEtkinlikSilOnizlemeUrl =
    "$baseUrl/yoneticiEtkinlikSilOnizleme";
const String yoneticiEtkinlikSilUrl = "$baseUrl/yoneticiEtkinlikSil";

// Yönetici - antrenör hakediş saatleri
const String yoneticiHakedisAntrenorlerUrl =
    "$baseUrl/yoneticiHakedisAntrenorler";
const String yoneticiHakedisOzetUrl = "$baseUrl/yoneticiHakedisOzet";
const String yoneticiHakedisDerslerUrl = "$baseUrl/yoneticiHakedisDersler";
