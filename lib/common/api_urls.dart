// =================== BASE URL ===================
const String baseUrlProd = "https://www.binay.fit/api";
const String baseUrlLocal = "http://10.0.2.2:8000/api";
const String baseUrl = baseUrlProd;
//const String baseUrl = baseUrlLocal;

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
String getUyeDersProgrami = "$baseUrl/getUyeDersProgrami";
String getUyedersTalepListesi = "$baseUrl/getUyedersTalepListesi";
String silUyedersTalebi = "$baseUrl/silUyedersTalebi";
String getUyeUrunList = "$baseUrl/getUyeUrunList";
String getHaftalikDersBilgilerim = "$baseUrl/getHaftalikDersBilgilerim";
String getUrunListesiVeUyePaketleri = "$baseUrl/getUrunListesiVeUyePaketleri";
String setUyeDersIptal = "$baseUrl/setUyeDersIptal";

// =================== ANTRENÖR ===================
String getAntrenorGunlukEtkinlikler = "$baseUrl/getAntrenorGunlukEtkinlikler";
String getAntrenorHaftalikEtkinlikler =
    "$baseUrl/getAntrenorHaftalikEtkinlikler";
String antrenorDersYapildiBilgisi = "$baseUrl/antrenorDersYapildiBilgisi";
String getAntrenorOgrenciler = "$baseUrl/getAntrenorOgrenciler";
String getAntrenorUygunSaatleri = "$baseUrl/getAntrenorUygunSaatleri";
String setAntrenorDersIptal = "$baseUrl/setAntrenorDersIptal";

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

// =================== BİLDİRİM ===================
String getNotifications = "$baseUrl/getNotifications";
String setNotificationsRead = "$baseUrl/setNotificationsRead";
String getUnreadNotificationCount = "$baseUrl/getUnreadNotificationCount";
String getBildirimById = "$baseUrl/getBildirimById";
String notificationAction = "$baseUrl/n/"; // + token

// =================== MUHASEBE ===================
String getMuhasebeOzet = "$baseUrl/getMuhasebeOzet";
String getParaHareketi = "$baseUrl/getParaHareketi";

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

// Ders Onay
const String getDersOnayBilgisiUrl = "$baseUrl/getDersOnayBilgisi";
const String setDersOnayBilgisiUrl = "$baseUrl/setDersOnayBilgisi";

// Değerlendirme
const String getDersDegerlendirmeUrl = "$baseUrl/getDersDegerlendirme";
const String setDersDegerlendirmeUrl = "$baseUrl/setDersDegerlendirme";
const String getDersTumDegerlendirmelerUrl =
    "$baseUrl/getDersTumDegerlendirmeler";

// İptal Talebi
const String createIptalTalebiUrl = "$baseUrl/EtkinlikIptalTalebiOlustur";
const String getIptalTalepleriUrl = "$baseUrl/getEtkinlikIptalTalepleri";
const String setIptalTalebiIslemUrl =
    "$baseUrl/setYoneticiIptalTalebiOnaylaReddet";
const String getKullaniciIptalTalepleriUrl =
    "$baseUrl/getKullaniciIptalTalepleri";
