import 'package:fitcall/v2/modules/auth/screens/qr_scanner_screen.dart';
import 'package:fitcall/v2/router/routes.dart'; // routeEnums burada
import 'package:flutter/material.dart';
import 'package:fitcall/v2/modules/auth/models/kullanici_profil_model.dart';

class ProfilSecimScreen extends StatelessWidget {
  const ProfilSecimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginResp =
        ModalRoute.of(context)!.settings.arguments as LoginResponse;
    final uyeler = loginResp.uyeler;
    final antrenorler = loginResp.antrenorler;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title:
            const Text('Hesap Seçimi', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
      ),

      //------------------------------------------------------------------ body
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Başlık
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.switch_account, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        'Üye Hesapları',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Kart kutusu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (uyeler.isNotEmpty) ...[
                        _buildGrid(uyeler, context, true),
                        const SizedBox(height: 24),
                      ],
                      if (antrenorler.isNotEmpty) ...[
                        const Text(
                          'Antrenör Hesapları',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildGrid(antrenorler, context, false),
                      ],
                      if (uyeler.isEmpty && antrenorler.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'Görüntülenecek hesap bulunamadı.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      //-------------------------------------------------- QR butonu
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QrScannerScreen()),
          );
          if (result != null) {
            Navigator.pushReplacementNamed(
              context,
              routeEnums[SayfaAdi.profilSecimV2]!,
              arguments: result,
            );
          }
        },
        child: const Icon(Icons.qr_code_scanner, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(height: 56 + MediaQuery.of(context).padding.bottom),
      ),
    );
  }

  //------------------------------------------------------------------- grid
  /// [isUye] = true → üye, false → antrenör
  Widget _buildGrid(List<dynamic> list, BuildContext context, bool isUye) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, idx) {
        final item = list[idx];
        final adSoyad = '${item.adi} ${item.soyadi}';
        final initials = adSoyad
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0])
            .take(2)
            .join();

        return InkWell(
          onTap: () {
            final targetRoute = isUye
                ? routeEnums[SayfaAdi.uyeAnasayfaV2]! // '/uye-home'
                : routeEnums[SayfaAdi.antrenorAnasayfaV2]!; // '/antrenor-home'

            Navigator.pushReplacementNamed(
              context,
              targetRoute,
              arguments: {'id': item.id, 'model': item}, // ihtiyaca göre
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.withOpacity(0.3)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.teal.withOpacity(0.3),
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  adSoyad,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
