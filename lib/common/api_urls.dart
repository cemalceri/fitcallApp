// =================== BASE URL TANIMLARI ===================
const String baseUrlProd = "https://www.binay.fit/api";
const String baseUrlDev = "http://10.0.2.2:8000/api";

const String baseUrl = baseUrlDev;
// const String baseUrl = baseUrlProd;

// =================== ENDPOINTLER ===================
String loginUrl = "$baseUrl/getToken";
String createToken = "$baseUrl/createToken"; // (bearer token)
String getOdemeBilgileri = "$baseUrl/getAidatOdemeGecmisi"; // (bearer token)
String getDersProgrami = "$baseUrl/getUyeDersProgrami"; // (bearer token)
String uyeKaydet = "$baseUrl/uyeKaydet"; // (bearer token)
String setDersYapildiBilgisi = "$baseUrl/setDersYapildiBilgisi";
String qrInOrOut = "$baseUrl/qrInOrOut";
String getAntrenorHaftalikEtkilikler =
    "$baseUrl/getAntrenorHaftalikEtkilikler"; // (bearer token)
String antrenorDersYapildiDurumu = "$baseUrl/antrenorDersYapildiDurumu";
String getAntrenorOgrenciler = "$baseUrl/getAntrenorOgrenciler";
String cihazKaydetGuncelle = "$baseUrl/cihazKaydetGuncelle";
String getGaleriImages = "$baseUrl/getGaleriImages";
String getDuyurular = "$baseUrl/getDuyurular";
String dersTalebiOlustur = "$baseUrl/dersTalebiOlustur";
String getUyedersTalepListesi = "$baseUrl/getUyedersTalepListesi";
String silUyedersTalebi = "$baseUrl/silUyedersTalebi";
String getUygunSaatler = "$baseUrl/getUygunSaatler";
String setQRKodBilgisi = "$baseUrl/setQRKodBilgisi";
String getQRKodBilgisi = "$baseUrl/getQRKodBilgisi";
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
