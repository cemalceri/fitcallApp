// ignore_for_file: use_build_context_synchronously
import 'package:fitcall/services/navigation_helper.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/models/4_auth/uye_kullanici_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/auth_service.dart';
import 'package:fitcall/services/core/fcm_service.dart';

class ProfilSecPage extends StatefulWidget {
  final List<KullaniciProfilModel> kullaniciProfilList;
  const ProfilSecPage(this.kullaniciProfilList, {super.key});

  @override
  State<ProfilSecPage> createState() => _ProfilSecPageState();
}

class _ProfilSecPageState extends State<ProfilSecPage> {
  bool _yonlendirildi = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_yonlendirildi && widget.kullaniciProfilList.length == 1) {
      _yonlendirildi = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _profilSecildi(widget.kullaniciProfilList.first);
      });
    }
  }

  Future<void> _profilSecildi(KullaniciProfilModel p) async {
    try {
      LoadingSpinner.show(context, message: 'Giriş yapılıyor...');
      final rol = await AuthService.loginUser(p);
      await sendFCMDevice(isMainAccount: p.anaHesap);

      if (!mounted) return;
      await NavigationHelper.redirectAfterLogin(context, rol);
    } on ApiException catch (e) {
      ShowMessage.error(context, e.message);
    } finally {
      LoadingSpinner.hide(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Profil Seç'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: widget.kullaniciProfilList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (_, i) {
            final p = widget.kullaniciProfilList[i];
            final ad = p.uye?.adi ?? p.antrenor?.adi ?? p.user.firstName;
            final soy = p.uye?.soyadi ?? p.antrenor?.soyadi ?? p.user.lastName;
            final tamAd = '$ad $soy';

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _profilSecildi(p),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4e54c8), Color(0xFF8f94fb)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child:
                        const Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tamAd,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (p.anaHesap == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Ana Hesap',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
