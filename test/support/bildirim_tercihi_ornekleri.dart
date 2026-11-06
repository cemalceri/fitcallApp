// Bildirim tercihleri test verisi (sunucudaki UYE_BILDIRIM_GRUPLARI metinleri).

import 'package:fitcall/models/2_uye/bildirim_tercihi_models.dart';

Map<String, dynamic> bildirimTercihleriJson({
  int profilSayisi = 1,
  Set<String> kapali = const {},
}) =>
    {
      'uye_profil_sayisi': profilSayisi,
      'gruplar': [
        {
          'kod': 'ders_teyit',
          'baslik': 'Ders hatırlatma ve teyit',
          'aciklama':
              'Derse katılıp katılmayacağın sorusu ve ders hatırlatmaları.',
          'acik': !kapali.contains('ders_teyit'),
          'kapatma_uyarisi':
              'Katılım sorusu telefonuna gelmez; cevabını uygulamadaki '
                  "Bildirimlerim'den vermen gerekir. Cevap vermezsen ofis "
                  'seni arayabilir.',
        },
        {
          'kod': 'ders_degisiklik',
          'baslik': 'Ders değişiklikleri',
          'aciklama': 'Ders iptali ve hocanın değişmesi.',
          'acik': !kapali.contains('ders_degisiklik'),
          'kapatma_uyarisi':
              'Dersin iptal edildiğinde ya da hocan değiştiğinde telefonuna '
                  'haber gelmez; iptal edilen derse boşuna gelebilirsin.',
        },
        {
          'kod': 'odeme_paket',
          'baslik': 'Ödeme, paket ve haklar',
          'aciklama': 'Ödeme alındı, paket tanımlandı, bitiyor ya da bitti, '
              'geciken ödeme ve telafi hakları.',
          'acik': !kapali.contains('odeme_paket'),
          'kapatma_uyarisi': null,
        },
        {
          'kod': 'talep',
          'baslik': 'Talepler ve başvurular',
          'aciklama':
              'Ders ve kort talebine ofisin cevabı, işletme başvurusunun sonucu.',
          'acik': !kapali.contains('talep'),
          'kapatma_uyarisi': '',
        },
      ],
    };

BildirimTercihleri ornekBildirimTercihleri({
  int profilSayisi = 1,
  Set<String> kapali = const {},
}) =>
    BildirimTercihleri.fromJson(
        bildirimTercihleriJson(profilSayisi: profilSayisi, kapali: kapali));
