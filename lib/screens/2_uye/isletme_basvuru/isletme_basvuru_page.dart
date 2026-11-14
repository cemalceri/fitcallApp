// lib/screens/2_uye/isletme_basvuru/isletme_basvuru_page.dart
//
// Ayarlar > "Başka işletmeye üyelik" (yalnız üye ana hesabı). Üye aynı
// hesapla kulüp içindeki başka bir işletmeye (ör. Pilates) başvurur; bilgiler
// aktif profilden aktarılır. Ofis onaylayınca yeni profil hesaba bağlanır,
// onaylanan satıra dokununca profil seçimine geçilir. Bildirimden
// ('isletme_basvurulari') da açılır.

import 'package:fitcall/models/2_uye/isletme_basvuru_models.dart';
import 'package:fitcall/screens/1_common/widgets/kvkk.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/2_uye/isletme_basvuru/widgets/isletme_basvuru_gorunumu.dart';
import 'package:fitcall/screens/4_auth/profil_sec.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/uye/isletme_basvuru_service.dart';
import 'package:material_ui/material_ui.dart';

class IsletmeBasvuruPage extends StatefulWidget {
  const IsletmeBasvuruPage({super.key});

  @override
  State<IsletmeBasvuruPage> createState() => _IsletmeBasvuruPageState();
}

class _IsletmeBasvuruPageState extends State<IsletmeBasvuruPage> {
  IsletmeBasvuruVerisi? _veri;
  String? _hata;
  int? _seciliId;
  bool _kvkkOnay = false;
  bool _gonderiliyor = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  /// Seçim artık geçerli değilse düşer; tek seçenek varsa o seçili gelir.
  void _veriyiKoy(IsletmeBasvuruVerisi veri) {
    final secilebilir = veri.secilebilirIsletmeler;
    if (!secilebilir.any((i) => i.id == _seciliId)) {
      _seciliId = secilebilir.length == 1 ? secilebilir.first.id : null;
    }
    _veri = veri;
  }

  Future<void> _yukle() async {
    setState(() => _hata = null);
    try {
      final veri = await IsletmeBasvuruService.getir();
      if (mounted) setState(() => _veriyiKoy(veri));
    } on ApiException catch (e) {
      if (mounted) setState(() => _hata = e.message);
    } catch (_) {
      if (mounted) setState(() => _hata = 'Başvurular yüklenemedi.');
    }
  }

  Future<void> _basvur() async {
    final id = _seciliId;
    if (id == null || !_kvkkOnay) return;
    setState(() => _gonderiliyor = true);
    try {
      final (veri, mesaj) = await IsletmeBasvuruService.basvur(id);
      if (!mounted) return;
      setState(() {
        _seciliId = null;
        _kvkkOnay = false;
        _veriyiKoy(veri);
      });
      ShowMessage.success(context, mesaj);
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } catch (_) {
      if (mounted) ShowMessage.error(context, 'Başvuru gönderilemedi.');
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  void _profileGec(IsletmeBasvurusu _) {
    final profiller = _veri?.profiller ?? const [];
    if (profiller.isEmpty) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ProfilSecPage(profiller)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Başka işletmeye üyelik')),
      body: SafeArea(
        top: false,
        child: IsletmeBasvuruGorunumu(
          veri: _veri,
          hata: _hata,
          seciliIsletmeId: _seciliId,
          kvkkOnay: _kvkkOnay,
          gonderiliyor: _gonderiliyor,
          onYenile: _yukle,
          onYenidenDene: _yukle,
          onSec: (id) => setState(() => _seciliId = id),
          onKvkk: (d) => setState(() => _kvkkOnay = d),
          onKvkkMetni: () => showKvkkAydinlatmaModal(context),
          onBasvur: _basvur,
          onOnaylanan: _profileGec,
        ),
      ),
    );
  }
}
