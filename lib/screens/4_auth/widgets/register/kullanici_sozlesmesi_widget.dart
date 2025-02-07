import 'package:flutter/material.dart';

class UserAgreementWidget extends StatelessWidget {
  const UserAgreementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Bu Kullanıcı Sözleşmesi ("Sözleşme"), [Şirket Adı] ("Şirket") tarafından sunulan mobil uygulama ("Uygulama") kullanımıyla ilgili hüküm ve koşulları belirlemektedir. Uygulamayı kullanarak, aşağıdaki koşulları kabul etmiş sayılırsınız:',
          style: TextStyle(fontSize: 16.0),
        ),
        const SizedBox(height: 16.0),
        _buildListItem('Veri Saklama ve İşleme', [
          'Uygulama, kullanıcıların kişisel bilgilerini saklayabilir ve işleyebilir. Kişisel bilgiler, adınız, e-posta adresiniz, telefon numaranız, coğrafi konum bilgileriniz ve benzeri verileri içerebilir. Bu bilgiler, Uygulamanın hizmetlerini sunmak, geliştirmek, analiz etmek ve kişiselleştirilmiş içerik sağlamak için kullanılabilir.'
        ]),
        const SizedBox(height: 16.0),
        _buildListItem('Gizlilik ve Güvenlik', [
          'Şirket, kullanıcıların kişisel bilgilerini gizli tutmak için gerekli önlemleri alır. Bu bilgiler, yasal gereklilikler dışında üçüncü taraflarla paylaşılmaz veya satılmaz. Ayrıca, uygun güvenlik önlemleriyle kullanıcı verilerinin yetkisiz erişim, değiştirme veya yok edilmesini önleriz.'
        ]),
        const SizedBox(height: 16.0),
        _buildListItem('Veri Kullanımı ve Analizi', [
          'Uygulama, kullanıcıların davranışlarını analiz etmek için çerezler ve benzeri teknolojiler kullanabilir. Bu veriler, kullanıcı deneyimini iyileştirmek, hizmetlerimizi optimize etmek ve pazarlama faaliyetlerini yönlendirmek için kullanılabilir. Ancak, kişisel verilerinizi doğrudan tanımlamak için bu verileri kullanmayız.'
        ]),
        const SizedBox(height: 16.0),
        _buildListItem('Kullanıcı Hakları', [
          'Kullanıcılar, kişisel verilerinin işlenmesiyle ilgili belirli haklara sahiptir. Bu haklar arasında, veri erişimi, düzeltme, silme ve işlemeye itiraz etme hakkı bulunmaktadır. Bu hakları kullanmak için lütfen [Şirket Adı] ile iletişime geçiniz.'
        ]),
        const SizedBox(height: 16.0),
        _buildListItem('Değişiklikler', [
          'Şirket, bu Kullanıcı Sözleşmesi\'ni zaman zaman güncelleme hakkını saklı tutar. Güncellenmiş Sözleşme, Uygulama üzerinden yayımlandıktan sonra geçerli olacaktır. Kullanıcılar, değişiklikleri gözden geçirmekten sorumludur ve Uygulamanın kullanımına devam etmek, değişiklikleri kabul ettiğiniz anlamına gelir.'
        ]),
        const SizedBox(height: 16.0),
        _buildListItem('Kabul', [
          'Uygulamayı kullanarak bu Sözleşme\'yi kabul etmiş sayılırsınız. Bu Sözleşme\'yi kabul etmiyorsanız, Uygulamayı kullanmamalısınız.'
        ]),
        const SizedBox(height: 16.0),
        const Text(
          'Bu Kullanıcı Sözleşmesi, [Tarih] tarihinden itibaren geçerlidir.',
          style: TextStyle(fontSize: 16.0),
        ),
      ],
    );
  }

  Widget _buildListItem(String title, List<String> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content
              .map((item) => Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text('• $item'),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
