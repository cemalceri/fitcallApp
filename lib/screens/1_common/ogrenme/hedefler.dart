// lib/screens/1_common/ogrenme/hedefler.dart
//
// `OgrenmeHedefi` kimlikleri. Ekran da rehber de aynı sabiti kullanır; yazım
// hatası derlemede yakalanır.

abstract final class Hedef {
  /// Hafta şeridinde dersi olan, bugün ya da sonraki bir gün.
  static const takvimDersliGun = 'takvim.dersliGun';

  /// Takvimdeki gelecek, iptal edilmemiş ders bloğu.
  static const takvimDers = 'takvim.ders';

  /// Ders detayındaki "katılamayacağım" açıklama kutusu.
  static const takvimAciklama = 'takvim.aciklama';

  /// Başlıktaki "?" (tanıtım turunun son adımı).
  static const ogrenmeButonu = 'ogrenme.buton';

  /// Ana sayfa başlığındaki profil değiştirme butonu (yalnız ikon).
  static const profilDegistir = 'profilDegistir';

  /// Üye ana sayfası: özet şeridi ve sonraki ders kartı.
  static const uyeOzet = 'uye.ozet';
  static const uyeSonrakiDers = 'uye.sonrakiDers';

  /// QR Oluştur: misafir davetindeki ad kutusu ve süre seçenekleri.
  static const qrMisafirAdi = 'qr.misafirAdi';
  static const qrSure = 'qr.sure';

  /// Havale / EFT: banka hesabı kartındaki IBAN satırı.
  static const havaleIban = 'havale.iban';

  /// Antrenör takvimi: yoklaması girilebilecek bitmiş ders ve devredilebilir
  /// gelecek ders (bloğu ya da ajanda satırı).
  static const antrenorBitmisDers = 'antrenor.bitmisDers';
  static const antrenorGelecekDers = 'antrenor.gelecekDers';

  /// Yoklaması hiç girilmemiş, kilitsiz bitmiş ders: hızlı onay kartı
  /// ("Ders yapıldı, herkes geldi") yalnız onda çıkar.
  static const antrenorYoklamasizDers = 'antrenor.yoklamasizDers';

  /// Eksik Yoklamalar listesindeki ilk ders.
  static const eksikYoklamaDers = 'antrenor.eksikYoklamaDers';

  /// Yoklama penceresi: ilk katılımcı satırı, neden seçenekleri, alttaki
  /// «Kaydet» (not penceresinin «Kaydet»inden ayrı).
  static const yoklamaKatilimci = 'yoklama.katilimci';
  static const yoklamaNeden = 'yoklama.neden';
  static const yoklamaKaydet = 'yoklama.kaydet';

  /// Plan dışı üye: seçim listesindeki ilk üye, not kutusu ve notun «Kaydet»i.
  static const planDisiUye = 'yoklama.planDisiUye';
  static const katilimNot = 'yoklama.not';
  static const katilimNotKaydet = 'yoklama.notKaydet';

  /// Devir: antrenör seçim kutusu ve devralabilen ilk hoca.
  static const devirAntrenorKutusu = 'devir.antrenorKutusu';
  static const devirAday = 'devir.aday';

  /// Antrenör ana sayfası: günlük kokpit ve sonraki ders kartı.
  static const antrenorKokpit = 'antrenor.kokpit';
  static const antrenorSonrakiDers = 'antrenor.sonrakiDers';

  /// Ofis ana sayfası: bugünkü dersler kartı.
  static const ofisBugun = 'ofis.bugun';

  /// Ofis Dersler: onay ya da katılım cevabı bekleyen ders satırı; ders
  /// sayfasında hocanın bildirimi ve üyenin «Katılacak» düğmesi.
  static const ofisOnayDers = 'ofis.onayDers';

  /// Bitmiş ve paketinden hak düşülebilecek üyesi olan ders.
  static const ofisPaketDusumDers = 'ofis.paketDusumDers';
  static const ofisCevapDers = 'ofis.cevapDers';
  static const ofisAntrenorBildirimi = 'ofis.antrenorBildirimi';
  static const ofisKatilacak = 'ofis.katilacak';

  /// Ofis ders formu (talepten açılınca): talep notu, ürün, katılımcı
  /// kutusu; üye seçim sayfasının tamamı.
  static const formTalepNotu = 'form.talepNotu';
  static const formUrun = 'form.urun';
  static const formUyeler = 'form.uyeler';
  static const uyeSecimi = 'form.uyeSecimi';

  /// Plan dışı karar: kişi satırı ve karar sayfasındaki alanlar.
  static const planDisiKisi = 'planDisi.kisi';
  static const planDisiUstlenen = 'planDisi.ustlenen';
  static const planDisiTutar = 'planDisi.tutar';
  static const planDisiAciklama = 'planDisi.aciklama';

  /// Yönetici ana sayfası: bugünün özeti, dönem kutusu ve seçicisi, "Şu an"
  /// grubu, ciro / tahsilat kartları, haftalık grafik ve düğmesi.
  static const yoneticiBugun = 'pano.bugun';
  static const yoneticiDonem = 'pano.donem';
  static const panoDonemSecici = 'pano.donemSecici';
  static const yoneticiSuAn = 'pano.suAn';
  static const yoneticiCiro = 'pano.ciro';
  static const yoneticiTahsilat = 'pano.tahsilat';
  static const grafikAlani = 'pano.grafik';
  static const grafikTahsilat = 'pano.grafikTahsilat';

  /// Raporlar: kort kutusunun dönem seçicisi, ilk kort satırı, ısı haritası.
  static const raporKortSecici = 'rapor.kortSecici';
  static const raporKortSatiri = 'rapor.kortSatiri';
  static const raporIsiHaritasi = 'rapor.isiHaritasi';

  /// Yönetici Üyeler: liste satırı, «Borçlu» kartı, «Filtrele»; filtre
  /// sayfasının Durum / Derse gelmeyenler bölümleri ve alttaki düğme; borç
  /// dökümünün iki listesi.
  static const uyeSatiri = 'uyeler.satir';
  static const uyeBorcluKart = 'uyeler.borclu';
  static const uyeFiltrele = 'uyeler.filtrele';
  static const filtreDurum = 'filtre.durum';
  static const filtreDers = 'filtre.ders';
  static const filtreUygula = 'filtre.uygula';
  static const borcHareketleri = 'borc.hareketler';
  static const borcAylik = 'borc.aylik';

  /// Değerlendirmeler: puan süzgeci, satır, detaydaki diğer katılımcılar.
  static const degerlendirmeSuzgec = 'degerlendirme.suzgec';
  static const degerlendirmeSatiri = 'degerlendirme.satir';
  static const digerKatilimcilar = 'degerlendirme.digerleri';

  /// Hakediş: ay hücresi ve başlığı, hoca satırı, panodaki «Bekliyor»
  /// kutusu ve grup satırı, ders kartı.
  static const hakedisAy = 'hakedis.ay';
  static const hakedisAyBasligi = 'hakedis.ayBasligi';
  static const hakedisAntrenor = 'hakedis.antrenor';
  static const hakedisBekliyor = 'hakedis.bekliyor';
  static const hakedisGrup = 'hakedis.grup';
  static const hakedisDers = 'hakedis.ders';

  /// Haftalık program: rehberin işaret ettiği gün ve ders bloğu.
  static const programGun = 'program.gun';
  static const programDers = 'program.ders';

  /// Ofis iptal penceresi: sebep listesi, işlem şekli, son «Dersi iptal et»
  /// (işlem menüsündeki aynı yazılı satırdan ayrı).
  static const iptalSebebi = 'iptal.sebep';
  static const iptalIslemSekli = 'iptal.islemSekli';
  static const iptalOnay = 'iptal.onay';

  /// Antrenörün ders kayıt talebi formu: gün/kort/saat alanları, açıklama.
  static const talepZamani = 'talep.zamani';
  static const talepAciklama = 'talep.aciklama';

  /// Ortak yükleme göstergesi: ekranda varken "Oku" yerine "Yükleniyor".
  static const yukleniyor = 'yukleniyor';

  // Rehber v3 kimlikleri, rol başına bölüm. Kimlik metni rolle başlar
  // ("uye.", "antrenor.", "ofis.", "yonetici.", "genel.", "duyuru.").

  // ── Üye ──

  /// Ana sayfa: Borç/Bakiye kutusu (etiketi değiştiği için yazıyla aranamaz),
  /// Bekleyen İşlemler, kahve ödülü kartı ve ⓘ düğmesi, duyurular, zil.
  static const uyeOzetBakiye = 'uye.ozetBakiye';
  static const uyeBekleyen = 'uye.bekleyen';
  static const uyeOdul = 'uye.odul';
  static const uyeOdulBilgi = 'uye.odulBilgi';
  static const uyeDuyuru = 'uye.duyuru';
  static const uyeDuyuruKarti = 'uye.duyuruKarti';
  static const uyeBildirimZili = 'uye.bildirimZili';

  /// Kabuk: alt çubuk (sol menü düğmesi `genelKabukMenu`, Ortak bölümünde).
  static const uyeAltBar = 'uye.altBar';

  /// Takvim: görünüm düğmesi, hafta okları, «Bugün», iptal edilen ders ve günü.
  static const uyeTakvimGorunum = 'uye.takvimGorunum';
  static const uyeHaftaOnceki = 'uye.haftaOnceki';
  static const uyeHaftaSonraki = 'uye.haftaSonraki';
  static const uyeHaftaBugun = 'uye.haftaBugun';
  static const uyeIptalDers = 'uye.iptalDers';
  static const uyeIptalGunu = 'uye.iptalGunu';

  /// Hareketler: bakiye kartı ve ilk hareket satırı.
  static const uyeHareketBakiye = 'uye.hareketBakiye';
  static const uyeHareketSatiri = 'uye.hareketSatiri';

  /// Havale / EFT: Dekontlarım sekmesi, IBAN kopyalama, ilk dekont satırı.
  static const uyeHavaleDekontlar = 'uye.havaleDekontlar';
  static const uyeIbanKopyala = 'uye.ibanKopyala';
  static const uyeDekontSatiri = 'uye.dekontSatiri';

  /// Hesabım: başlıktaki fotoğraf ve bilgi penceresi.
  static const uyeProfilFoto = 'uye.profilFoto';
  static const uyeBilgiSayfasi = 'uye.bilgiSayfasi';

  /// Üyelik & Paket: ilk kart.
  static const uyeUrunKart = 'uye.urunKart';

  /// Telafi Derslerim: özet kartı ve ilk telafi kartı.
  static const uyeTelafiOzet = 'uye.telafiOzet';
  static const uyeTelafiKart = 'uye.telafiKart';

  /// Geçmiş Dersler: ilk satır; değerlendirme penceresinde yıldızlar ve yorum.
  static const uyeGecmisDers = 'uye.gecmisDers';
  static const uyeDegerlendirmePuan = 'uye.degerlendirmePuan';
  static const uyeDegerlendirmeYorum = 'uye.degerlendirmeYorum';

  /// Ders Katılım Onayı: ilk bekleyen ders kartı.
  static const uyeTeyitKarti = 'uye.teyitKarti';

  /// Event / Davet: giriş kodu bölümü.
  static const uyeEventKod = 'uye.eventKod';

  // ── Antrenör ──

  /// Takvim: hafta şeridi, kilitli / devir rozetli / yoklaması girilmiş ders,
  /// üstteki görünüm ve "Tüm program" düğmeleri.
  static const antrenorGunSeridi = 'antrenor.gunSeridi';
  static const antrenorKilitliDers = 'antrenor.kilitliDers';
  static const antrenorDevirliDers = 'antrenor.devirliDers';
  static const antrenorYoklamaGirilmisDers = 'antrenor.yoklamaGirilmisDers';
  static const antrenorGorunumDugmesi = 'antrenor.gorunumDugmesi';
  static const antrenorTumProgramDugmesi = 'antrenor.tumProgramDugmesi';

  /// Yoklama penceresi: kilit kutusu; misafir sayfasındaki ad kutusu.
  static const antrenorYoklamaKilit = 'antrenor.yoklamaKilit';
  static const antrenorMisafirAd = 'antrenor.misafirAd';

  /// Gelecek ders detayı: katılımcı cevapları.
  static const antrenorDetayKatilimcilar = 'antrenor.detayKatilimcilar';

  /// Ana sayfa: menü düğmesi ve eksik yoklama uyarısı.
  static const antrenorMenuDugmesi = 'antrenor.menuDugmesi';
  static const antrenorEksikUyari = 'antrenor.eksikUyari';

  /// Hakediş panosu (antrenör rehberi): başlık, alacak kutusu, oran çubuğu,
  /// rol kartı ve «Hakediş dışı» grup satırı.
  static const antrenorHakedisBasligi = 'antrenor.hakedisBasligi';
  static const antrenorHakedisAlacak = 'antrenor.hakedisAlacak';
  static const antrenorHakedisOran = 'antrenor.hakedisOran';
  static const antrenorHakedisRol = 'antrenor.hakedisRol';
  static const antrenorHakedisDisiGrup = 'antrenor.hakedisDisiGrup';

  /// Çalışma saatleri: bilgi notu, ilk günün anahtarı ve saat düğmesi.
  static const antrenorCalismaNotu = 'antrenor.calismaNotu';
  static const antrenorCalismaAnahtar = 'antrenor.calismaAnahtar';
  static const antrenorCalismaSaat = 'antrenor.calismaSaat';

  /// Öğrencilerim: ilk satır, arama kutusu, seviye çipleri, sayı kartları.
  static const antrenorOgrenciSatiri = 'antrenor.ogrenciSatiri';
  static const antrenorOgrenciArama = 'antrenor.ogrenciArama';
  static const antrenorOgrenciSeviye = 'antrenor.ogrenciSeviye';
  static const antrenorOgrenciSayilar = 'antrenor.ogrenciSayilar';

  /// Öğrenci detayı: katılım ve iletişim kartları.
  static const antrenorOgrenciKatilim = 'antrenor.ogrenciKatilim';
  static const antrenorOgrenciIletisim = 'antrenor.ogrenciIletisim';

  /// Bildirimler: devir teklifli bildirim satırı.
  static const antrenorBildirimDevir = 'antrenor.bildirimDevir';

  // ── Ofis ──

  /// Gezinme: alt bar, ☰ menü düğmesi, bildirim zili.
  static const ofisAltBar = 'ofis.altBar';
  static const ofisMenu = 'ofis.menu';
  static const ofisZil = 'ofis.zil';

  /// Onay bekleyen dersler listesindeki gün satırı.
  static const ofisOnayGunu = 'ofis.onayGunu';

  /// Program: gün şeridi, hafta başlığı, ızgara, ızgaradaki bir boş saat;
  /// iptalli ders / gün; talep bloğu ve talep olan gün.
  static const programGunSeridi = 'ofis.programGunSeridi';
  static const programBaslik = 'ofis.programBaslik';
  static const programIzgara = 'ofis.programIzgara';
  static const programBosSaat = 'ofis.programBosSaat';
  static const programIptalGun = 'ofis.programIptalGun';
  static const programIptalDers = 'ofis.programIptalDers';
  static const programIptalKunyesi = 'ofis.programIptalKunyesi';
  static const programTalepGunu = 'ofis.programTalepGunu';
  static const programTalep = 'ofis.programTalep';

  /// Ders formu: tarih + saat bloğu, kort, antrenör; silme penceresinin
  /// etki sayıları.
  static const formZaman = 'ofis.formZaman';
  static const formKort = 'ofis.formKort';
  static const formAntrenor = 'ofis.formAntrenor';
  static const silEtkisi = 'ofis.silEtkisi';

  /// Dersler: gün gezinmesi, süzgeç çipleri, genel ders satırı, toplu onay
  /// kartı, karar verilmiş ders satırı; ders sayfasında hakediş bölümü ve
  /// «Yapılmadı» penceresinin neden seçenekleri.
  static const dersGunSecici = 'ofis.dersGunSecici';
  static const dersSuzgec = 'ofis.dersSuzgec';
  static const dersSatiri = 'ofis.dersSatiri';
  static const dersTopluOnay = 'ofis.dersTopluOnay';
  static const ofisKararliDers = 'ofis.kararliDers';
  static const ofisHakedis = 'ofis.hakedis';
  static const yapilmadiNeden = 'ofis.yapilmadiNeden';

  /// Ders kayıt talebi: red nedeni kutusu. Plan dışı karar: paket seçimi.
  static const talepRedNedeni = 'ofis.talepRedNedeni';
  static const planDisiPaket = 'ofis.planDisiPaket';

  /// Talepler: öneri yapılabilen / kaydedilebilen ilk üye talebi; öneri
  /// formunda gün-saat alanları ve üyeye not.
  static const ofisTalepOnerilebilir = 'ofis.talepOnerilebilir';
  static const ofisTalepKaydedilir = 'ofis.talepKaydedilir';
  static const ofisOneriZamani = 'ofis.oneriZamani';
  static const ofisOneriNotu = 'ofis.oneriNotu';

  /// Üye Taleplerim: öneri bekleyen ilk talep ve detaydaki öneri kutusu,
  /// geri çekilebilir ilk talep. Sihirbaz: tür seçenekleri, haritada ilk
  /// uygun kare, saat adımının «Devam»ı (yazısında seçilen saat var).
  static const uyeTalepOnerili = 'uye.talepOnerili';
  static const uyeTalepOneri = 'uye.talepOneri';
  static const uyeTalepGeriCekilir = 'uye.talepGeriCekilir';
  static const uyeTalepTurleri = 'uye.talepTurleri';
  static const uyeTalepKare = 'uye.talepKare';
  static const uyeTalepSaatDevam = 'uye.talepSaatDevam';

  /// Üyeler: arama kutusu, durum seçici, liste satırı; üye detayında bölümler.
  static const ofisUyeArama = 'ofis.uyeArama';
  static const ofisUyeFiltre = 'ofis.uyeFiltre';
  static const ofisUyeSatiri = 'ofis.uyeSatiri';
  static const ofisUyeBilgi = 'ofis.uyeBilgi';
  static const ofisUyePaketler = 'ofis.uyePaketler';
  static const ofisUyeYaklasan = 'ofis.uyeYaklasan';
  static const ofisUyeGecmis = 'ofis.uyeGecmis';

  // ── Yönetici ──

  /// Ana sayfa: Ders / İptal / Aktif Üye / Toplam Alacak kartları, menü
  /// düğmesi, "Bugün" kısayolları.
  static const yoneticiDers = 'yonetici.ders';
  static const yoneticiIptal = 'yonetici.iptal';
  static const yoneticiAktifUye = 'yonetici.aktifUye';
  static const yoneticiAlacak = 'yonetici.alacak';
  static const yoneticiMenu = 'yonetici.menu';
  static const yoneticiHizli = 'yonetici.hizli';
  static const yoneticiBugunDersleri = 'yonetici.bugunDersleri';

  /// Raporlar: ciro grubunun seçicisi, özet kartlar, iki tablo, ilk antrenör.
  static const raporCiroSecici = 'yonetici.raporCiroSecici';
  static const raporOzetKartlar = 'yonetici.raporOzetKartlar';
  static const raporCiroTablosu = 'yonetici.raporCiroTablosu';
  static const raporTahsilatTablosu = 'yonetici.raporTahsilatTablosu';
  static const raporAntrenorSatiri = 'yonetici.raporAntrenorSatiri';

  /// Üyeler: arama, Sırala düğmesi, kart şeridi, «Yeni» kartı; sıralama
  /// sayfasında borç satırı; filtre sayfasında borç / kesinleşme / ödeme.
  static const uyeArama = 'yonetici.uyeArama';
  static const uyeSirala = 'yonetici.uyeSirala';
  static const uyeKartlari = 'yonetici.uyeKartlari';
  static const uyeYeniKart = 'yonetici.uyeYeniKart';
  static const siralamaBorc = 'yonetici.siralamaBorc';
  static const filtreBorc = 'yonetici.filtreBorc';
  static const filtreKesin = 'yonetici.filtreKesin';
  static const filtreOdeme = 'yonetici.filtreOdeme';

  /// Üye detayı bölümleri.
  static const uyeDetayHizli = 'yonetici.uyeDetayHizli';
  static const uyeDetayBakiye = 'yonetici.uyeDetayBakiye';
  static const uyeDetayBilgiler = 'yonetici.uyeDetayBilgiler';
  static const uyeDetayPaketler = 'yonetici.uyeDetayPaketler';
  static const uyeDetayYaklasan = 'yonetici.uyeDetayYaklasan';
  static const uyeDetayGecmis = 'yonetici.uyeDetayGecmis';

  /// Antrenörler: ilk satır, puan hücresi, kart şeridi.
  static const antrenorSatiri = 'yonetici.antrenorSatiri';
  static const antrenorPuan = 'yonetici.antrenorPuan';
  static const antrenorKartlari = 'yonetici.antrenorKartlari';

  /// Hakediş seçim sayfası:
  /// arama ve durum süzgeci.
  static const hakedisArama = 'yonetici.hakedisArama';
  static const hakedisFiltre = 'yonetici.hakedisFiltre';

  /// Dersler (salt okunur): sonraki gün oku, sayı kartları, ilk satır.
  static const yoneticiDersSonrakiGun = 'yonetici.dersSonrakiGun';
  static const yoneticiDersKartlari = 'yonetici.dersKartlari';
  static const yoneticiDersSatiri = 'yonetici.dersSatiri';

  // ── Ortak sayfalar: QR, Bildirimler, Ayarlar ──

  /// Kabuk başlıklarındaki sol menü (☰) düğmesi.
  static const genelKabukMenu = 'genel.kabukMenu';

  /// QR Oluştur: kişisel kod, yenile düğmesi, ilk misafir kartı ve silme ikonu.
  static const genelQrKisisel = 'genel.qrKisisel';
  static const genelQrYenile = 'genel.qrYenile';
  static const genelQrDavetKarti = 'genel.qrDavetKarti';
  static const genelQrDavetSil = 'genel.qrDavetSil';

  /// Bildirimler: ilk satır ve ⋮ menüsü.
  static const genelBildirimSatiri = 'genel.bildirimSatiri';
  static const genelBildirimMenu = 'genel.bildirimMenu';

  /// Ayarlar: tema bölümü; Şifreyi Değiştir sayfasında alanlar.
  static const genelAyarTema = 'genel.ayarTema';
  static const genelSifreAlanlari = 'genel.sifreAlanlari';

  // ── Duyurular ──

  /// Liste: ilk duyuru satırı. Okuma durumu: özet kartı,
  /// kaynak dağılımı, arama, iki segment etiketi, ilk hesap satırı, web simgesi.
  static const duyuruSatiri = 'duyuru.satir';
  static const okumaOzet = 'duyuru.okumaOzet';
  static const okumaKaynaklar = 'duyuru.okumaKaynaklar';
  static const okumaArama = 'duyuru.okumaArama';
  static const okumaGordu = 'duyuru.okumaGordu';
  static const okumaGormedi = 'duyuru.okumaGormedi';
  static const okumaListe = 'duyuru.okumaListe';
  static const okumaWeb = 'duyuru.okumaWeb';
  static const duyuruIcerik = 'duyuru.icerik';
}
