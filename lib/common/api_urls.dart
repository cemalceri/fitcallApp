// =================== BASE URL TANIMLARI ===================
const String baseUrlProd = "https://www.binay.fit/api";
const String baseUrlDev = "http://10.0.2.2:8000/api";

//const String baseUrl = baseUrlDev;
const String baseUrl = baseUrlProd;

// =================== ENDPOINTLER ===================
String loginUrl = "$baseUrl/getToken";
String createToken = "$baseUrl/createToken";
String getOdemeBilgileri = "$baseUrl/getAidatOdemeGecmisi";
String getDersProgrami = "$baseUrl/getUyeDersProgrami";
String uyeKaydet = "$baseUrl/uyeKaydet";
String setDersYapildiBilgisi = "$baseUrl/setDersYapildiBilgisi";
String qrInOrOut = "$baseUrl/qrInOrOut";
String getAntrenorGunlukEtkinlikler = "$baseUrl/getAntrenorGunlukEtkinlikler";
String getAntrenorHaftalikEtkinlikler =
    "$baseUrl/getAntrenorHaftalikEtkinlikler";
String antrenorDersYapildiBilgisi = "$baseUrl/antrenorDersYapildiBilgisi";
String getAntrenorOgrenciler = "$baseUrl/getAntrenorOgrenciler";
String cihazKaydetGuncelle = "$baseUrl/cihazKaydetGuncelle";
String getGaleriImages = "$baseUrl/getGaleriImages";
String getDuyurular = "$baseUrl/getDuyurular";
String dersTalebiOlustur = "$baseUrl/dersTalebiOlustur";
String getUyedersTalepListesi = "$baseUrl/getUyedersTalepListesi";
String silUyedersTalebi = "$baseUrl/silUyedersTalebi";
String getUygunSaatler = "$baseUrl/getUygunSaatler";
String setQRKodBilgisi = "$baseUrl/setQRKodBilgisi";
String qrKodDogrula = "$baseUrl/qrKodDogrula";
String getNotifications = "$baseUrl/getNotifications";
String setUyeDersIptal = "$baseUrl/setUyeDersIptal";
String getMuhasebeOzet = "$baseUrl/getMuhasebeOzet";
String getParaHareketi = "$baseUrl/getParaHareketi";
String setDersTeyit = "$baseUrl/setDersTeyit";
String getBildirimById = "$baseUrl/getBildirimById";
String setDersTalep = "$baseUrl/setDersTalep";
String setGenelDersTalep = "$baseUrl/setGenelDersTalep";
String getKortveAntrenorList = "$baseUrl/getKortveAntrenorList";
String setNotificationsRead = "$baseUrl/setNotificationsRead";
String getUnreadNotificationCount = "$baseUrl/getUnreadNotificationCount";
String getUyeUrunList = "$baseUrl/getUyeUrunList";
String getHaftalikDersBilgilerim = "$baseUrl/getHaftalikDersBilgilerim";
String getMyMembers = "$baseUrl/getMyMembers";
String getUrunListesiVeUyePaketleri = "$baseUrl/getUrunListesiVeUyePaketleri";
String setAntrenorDersIptal = "$baseUrl/setAntrenorDersIptal";
String getMobilConfigs = "$baseUrl/getMobilConfigs";
// Event QR
String getirEventAktif = "$baseUrl/getirEventAktif";
String getirEventSelfPass = "$baseUrl/getirEventSelfPass";
String listeleEventMisafirPass = "$baseUrl/listeleEventMisafirPass";
String olusturEventMisafirPass = "$baseUrl/olusturEventMisafirPass";
String silEventMisafirPass = "$baseUrl/silEventMisafirPass";

// Tesis (içerideki) QR
String getirTesisSelfPass = "$baseUrl/getirTesisSelfPass";
String listeleTesisMisafirPass = "$baseUrl/listeleTesisMisafirPass";
String olusturTesisMisafirPass = "$baseUrl/olusturTesisMisafirPass";
String silTesisMisafirPass = "$baseUrl/silTesisMisafirPass";
// Tarama
String taraPass = "$baseUrl/taraPass";
