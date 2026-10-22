// =================== BASE URL ===================
const String baseUrlProd = "https://www.binay.fit/api";
const String baseUrlLocal = "http://10.0.2.2:8000/api";
const String baseUrl = baseUrlProd;
// const String baseUrl = baseUrlLocal;

/// Web panelinin kökü (API kökünden "/api" atılır). Mobilden web sayfası
/// açmak için, ör. duyurunun "Web panelinde aç" bağlantısı.
final String webKokUrl = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

// =================== AUTH ===================
String createToken = "$baseUrl/createToken";
String getMyMembers = "$baseUrl/getMyMembers";
String kayitFormVerileriUrl = "$baseUrl/kayitFormVerileri";
String uyeBasvuruUrl = "$baseUrl/uyeBasvuru";
String sifremiUnuttumUrl = "$baseUrl/sifremiUnuttum";
String uyeSifreDegistir = "$baseUrl/uyeSifreDegistir";
String uyeKullaniciSil = "$baseUrl/uyeKullaniciSil";

// =================== ÜYE ===================
String getUyeDersProgramiUrl = "$baseUrl/getUyeDersProgrami";
String getUyeUrunList = "$baseUrl/getUyeUrunList";
String getHaftalikDersBilgilerim = "$baseUrl/getHaftalikDersBilgilerim";
String getTelafiDersBilgileriUrl = "$baseUrl/getTelafiDersBilgileri";
String getAktifUyeListesiUrl = "$baseUrl/getAktifUyeListesi";
String getUyeHomeOzetUrl = "$baseUrl/getUyeHomeOzet";
String getUyeGecmisDerslerUrl = "$baseUrl/getUyeGecmisDersler";
// Üyenin kendi profil fotoğrafı (multipart, alan `foto`); üye token'dan.
const String uyeProfilFotografiUrl = "$baseUrl/uyeProfilFotografi";
const String uyeProfilFotografiSilUrl = "$baseUrl/uyeProfilFotografiSil";

// =================== ANTRENÖR ===================
String getAntrenorGunlukEtkinlikler = "$baseUrl/getAntrenorGunlukEtkinlikler";
String getAntrenorHaftalikEtkinlikler =
    "$baseUrl/getAntrenorHaftalikEtkinlikler";
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

// Antrenörün salt-okunur tüm programı + ders kayıt talebi
// (backend api/ders_kayit_talebi/metots.py)
const String antrenorHaftalikProgramUrl = "$baseUrl/antrenorHaftalikProgram";
const String dersKayitTalebiOlusturUrl = "$baseUrl/dersKayitTalebiOlustur";
const String dersKayitTalebiGeriCekUrl = "$baseUrl/dersKayitTalebiGeriCek";

// =================== ETKİNLİK ===================
String setDersTeyit = "$baseUrl/setDersTeyit";
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
// Havale/EFT: kulübün hesapları + üyenin dekontları (backend api/dekont/metots.py).
// Dekont yükleme multipart, alan `dosya`; işleme yalnız web'de.
const String uyeBankaHesaplariUrl = "$baseUrl/uyeBankaHesaplari";
const String uyeDekontlarimUrl = "$baseUrl/uyeDekontlarim";
const String uyeDekontYukleUrl = "$baseUrl/uyeDekontYukle";
const String uyeDekontGeriCekUrl = "$baseUrl/uyeDekontGeriCek";
const String uyeDekontDosyaUrl = "$baseUrl/uyeDekontDosya";
String odemeHesaplaUrl = "$baseUrl/odemeHesapla";
String odemeBaslatUrl = "$baseUrl/odemeBaslat";
String odemeDurumUrl = "$baseUrl/odemeDurum/";

// =================== QR & GEÇİŞ ===================
String qrKodDogrula = "$baseUrl/qrKodDogrula";
String cihazKaydetGuncelle = "$baseUrl/cihazKaydetGuncelle";
// Token gerektirmeyen izin bildirimi: iOS'ta bildirim izni verilmediğinde FCM
// token alınamadığı için cihazKaydetGuncelle'e hiç gidilemiyor.
String cihazIzinGuncelle = "$baseUrl/cihazIzinGuncelle";

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
String getPopupDuyuruUrl = "$baseUrl/getPopupDuyuru";

// "Neler yeni?" sürüm notu popup'ı: kurulu sürümün, aktif profile ait notu.
String getSurumYenilikleriUrl = "$baseUrl/getSurumYenilikleri";
String setSurumYenilikGorunduUrl = "$baseUrl/setSurumYenilikGorundu";
String getSurumNotuArsiviUrl = "$baseUrl/getSurumNotuArsivi";
String yoneticiDuyurularUrl = "$baseUrl/yoneticiDuyurular";
String yoneticiDuyuruOkumaDurumuUrl = "$baseUrl/yoneticiDuyuruOkumaDurumu";

// Ders Onay
const String getDersOnayBilgisiUrl = "$baseUrl/getDersOnayBilgisi";
const String setDersOnayBilgisiUrl = "$baseUrl/setDersOnayBilgisi";

// Değerlendirme
const String getDersDegerlendirmeUrl = "$baseUrl/getDersDegerlendirme";
const String setDersDegerlendirmeUrl = "$baseUrl/setDersDegerlendirme";
const String getDersTumDegerlendirmelerUrl =
    "$baseUrl/getDersTumDegerlendirmeler";
// Yalnız yönetici: bir antrenörün puan + yorum + ders detayı.
const String degerlendirmeListesiUrl = "$baseUrl/degerlendirmeListesi";

// İptal Talebi
const String createIptalTalebiUrl = "$baseUrl/etkinlikIptalTalebiOlustur";
const String getKullaniciIptalTalepleriUrl =
    "$baseUrl/getKullaniciIptalTalepleri";
const String getDersIptalTalebiUrl = "$baseUrl/getDersIptalTalebi";
const String iptalTalebiGeriCekUrl = "$baseUrl/iptalTalebiGeriCek";

// =================== OFİS (ÖN BÜRO) ===================
// Ders yönetimi uçları yöneticiyle ORTAK (yoneticiEtkinlik*, yoneticiDersler);
// ofise özel olan yalnız üye uçları, çünkü tek fark alan kırpması: bu uçlar
// bakiye, para hareketi, adres, meslek, veli ve acil durum bilgisi döndürmez.
const String ofisUyelerUrl = "$baseUrl/ofisUyeler";
const String ofisUyeDetayUrl = "$baseUrl/ofisUyeDetay";
// Ofis Ana Sayfa + Dersler (web Ders Yönetimi) + plan dışı kararlar.
// Kurallar backend'de web ile ortak servislerde (api/ofis/ders_yonetimi.py).
const String ofisBekleyenIslerUrl = "$baseUrl/ofisBekleyenIsler";
const String ofisDersYonetimiGunUrl = "$baseUrl/ofisDersYonetimiGun";
const String ofisDersOnayUrl = "$baseUrl/ofisDersOnay";
const String ofisGunuOnaylaUrl = "$baseUrl/ofisGunuOnayla";
const String ofisDersHakedisUrl = "$baseUrl/ofisDersHakedis";
const String ofisPaketDusumUrl = "$baseUrl/ofisPaketDusum";
const String ofisManuelTeyitUrl = "$baseUrl/ofisManuelTeyit";
const String ofisTeyitHatirlatUrl = "$baseUrl/ofisTeyitHatirlat";
const String ofisPlanDisiBekleyenlerUrl = "$baseUrl/ofisPlanDisiBekleyenler";
const String ofisPlanDisiSeceneklerUrl = "$baseUrl/ofisPlanDisiSecenekler";
const String ofisPlanDisiKararUrl = "$baseUrl/ofisPlanDisiKarar";
// Ders kayıt talepleri: kayıt yoneticiEtkinlikKaydet'e talep_id ile gider
const String ofisDersKayitTalepleriUrl = "$baseUrl/ofisDersKayitTalepleri";
const String ofisDersKayitTalebiReddetUrl =
    "$baseUrl/ofisDersKayitTalebiReddet";

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
