import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// KVKK Aydınlatma Metni – tam ekran alt sayfa olarak gösterilen widget
Future<void> showKvkkAydinlatmaModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const _KvkkAydinlatmaSheet(),
  );
}

class _KvkkAydinlatmaSheet extends StatelessWidget {
  const _KvkkAydinlatmaSheet();

  Future<void> _open(Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // sessiz düş
      }
    } catch (_) {/* no-op */}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    Widget h6(String s) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(s,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        );

    Widget bullet(String s) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Text(s)),
            ],
          ),
        );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('KVKK Aydınlatma Metni',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    'Binay Tenis Akademi – Kişisel Verilerin Korunması Aydınlatma Metni',
                    style:
                        text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bu Aydınlatma Metni, 6698 sayılı Kişisel Verilerin Korunması Kanunu (“KVKK”) uyarınca veri sorumlusu sıfatıyla Binay Tenis Akademi tarafından hazırlanmıştır.',
                  ),
                  h6('1) Veri Sorumlusu'),
                  Text('Unvan: Binay Tenis Akademi'),
                  Text('Adres: İncek, Tenis Sk. No:4, 06830 Gölbaşı/Ankara'),
                  Text('Telefon: 0542 246 29 82'),
                  InkWell(
                    onTap: () =>
                        _open(Uri.parse('mailto:binayakademi@gmail.com')),
                    child: Text('E-posta: binayakademi@gmail.com',
                        style: text.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        )),
                  ),
                  h6('2) İşlenen Kişisel Veri Kategorileri'),
                  bullet('Kimlik: Ad, soyad, (varsa) T.C. kimlik no'),
                  bullet('İletişim: Telefon, e-posta, adres'),
                  bullet('Demografik: Cinsiyet, doğum tarihi, doğum yeri'),
                  bullet('Acil Durum: Acil durum kişi bilgisi ve telefonu'),
                  bullet(
                      'Veli/Anne-Baba (18 yaş altı): Ad-soyad, telefon, e-posta, meslek'),
                  bullet('Eğitim: (Varsa) Okul bilgisi'),
                  bullet(
                      'Müşteri İşlem: Başvuru/üyelik kayıtları, tercih/katılım bilgileri'),
                  bullet('Görsel (opsiyonel): Profil fotoğrafı'),
                  h6('3) Toplanma Yöntemi ve Hukuki Sebep'),
                  Text(
                      'Veriler; web başvuru formu, telefon/e-posta ve sözleşme/üyelik süreçleri sırasında elektronik/manuel yollarla toplanır.'),
                  bullet(
                      'KVKK m.5/2-c: Sözleşmenin kurulması/ifası için gerekli'),
                  bullet(
                      'KVKK m.5/2-ç: Hukuki yükümlülüklerin yerine getirilmesi (mali/denetim)'),
                  bullet(
                      'KVKK m.5/2-f: Meşru menfaat (kulüp işleyişi, güvenlik, iletişim)'),
                  bullet('Açık rıza (m.5/1): Gerekli olduğunda ayrıca alınır.'),
                  Text(
                      'Özel nitelikli kişisel veri (sağlık vb.) işlemiyoruz; ihtiyaç doğarsa açık rıza olmadan işlenmez.',
                      style: text.bodySmall
                          ?.copyWith(fontStyle: FontStyle.italic)),
                  h6('4) İşleme Amaçları'),
                  bullet(
                      'Üyelik başvurusunun alınması, doğrulanması ve sonuçlandırılması'),
                  bullet(
                      '18 yaş altı için veli iletişim ve bilgilendirme süreçleri'),
                  bullet(
                      'Program/etkinlik/rezervasyon planlama ve bilgilendirme'),
                  bullet(
                      'Hukuki ve mali yükümlülüklerin yerine getirilmesi, kayıtların saklanması'),
                  bullet(
                      'İletişim, talep/şikâyet yönetimi ve operasyonel süreçler'),
                  h6('5) Aktarım Yapılan Taraflar ve Amaçları'),
                  Text(
                      'Yasal zorunluluklar ve sözleşmesel gereklilikler dâhilinde; kamu kurumları, bağımsız denetçiler; bilişim/hosting, SMS/e-posta sağlayıcıları; hukuki/finansal danışmanlar ve iş ortaklarıyla sınırlı amaçlarla paylaşılabilir.'),
                  h6('6) Saklama Süreleri'),
                  Text(
                      'Veriler, üyelik/ilişki süresince ve mevzuattaki zamanaşımı/saklama süreleri boyunca (ör. TTK ve vergi mevzuatı uyarınca 10 yıla kadar) muhafaza edilir; süresi dolduğunda silinir, yok edilir veya anonimleştirilir.'),
                  h6('7) İlgili Kişi Hakları (KVKK m.11)'),
                  bullet('İşlenip işlenmediğini öğrenme ve bilgi talep etme'),
                  bullet('Amaca uygunluk ve aktarılan tarafları öğrenme'),
                  bullet('Eksik/yanlışsa düzeltilmesini isteme'),
                  bullet(
                      'Mevzuata uygun şekilde silinmesini/yok edilmesini isteme'),
                  bullet('Üçüncü kişilere bildirilmesini talep etme'),
                  bullet('Otomatik işleme sonuçlarına itiraz'),
                  bullet('Zarar doğarsa giderilmesini talep'),
                  h6('8) Başvuru Yöntemi'),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Taleplerinizi '),
                      InkWell(
                        onTap: () =>
                            _open(Uri.parse('mailto:binayakademi@gmail.com')),
                        child: Text('binayakademi@gmail.com',
                            style: text.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            )),
                      ),
                      const Text(
                          ' adresine veya “İncek, Tenis Sk. No:4, 06830 Gölbaşı/Ankara” adresine iletebilirsiniz.'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yürürlük Tarihi: 18.09.2025  •  Metin, mevzuat ve iç süreçlere göre güncellenebilir; güncel sürüm web sitemizde yayımlanır.',
                    style: text.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kapat'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
