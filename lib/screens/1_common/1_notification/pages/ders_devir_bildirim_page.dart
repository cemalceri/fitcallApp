// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/3_antrenor/ders_devir_talebi_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/3_antrenor/takvim/widgets/takvim_constants.dart';
import 'package:fitcall/services/antrenor/antrenor_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color _bgGray = Color(0xFFF9FAFB);
const Color _textPrimary = Color(0xFF1A1A1A);
const Color _textSecondary = Color(0xFF6B7280);
const Color _successGreen = Color(0xFF10B981);
const Color _errorRed = Color(0xFFEF4444);

class DersDevirBildirimPage extends StatefulWidget {
  /// Login'li bildirim listesinden açılınca dolu (auth'lu çağrı yapılır)
  final int? talepId;

  /// FCM bildiriminden / login'siz açılınca dolu (action token ile çağrı yapılır)
  final String? actionToken;

  const DersDevirBildirimPage({
    super.key,
    this.talepId,
    this.actionToken,
  }) : assert(talepId != null || actionToken != null,
            'talepId ya da actionToken zorunludur.');

  @override
  State<DersDevirBildirimPage> createState() => _DersDevirBildirimPageState();
}

class _DersDevirBildirimPageState extends State<DersDevirBildirimPage> {
  bool _loading = true;
  bool _saving = false;
  String? _hata;
  DevirTalebiDetayDto? _detay;

  bool _showRedForm = false;
  final _redCtrl = TextEditingController();

  bool get _useToken =>
      widget.actionToken != null && widget.actionToken!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _detayYukle();
  }

  @override
  void dispose() {
    _redCtrl.dispose();
    super.dispose();
  }

  Future<void> _detayYukle() async {
    try {
      DevirTalebiDetayDto? detay;
      if (_useToken) {
        detay =
            await DersDevirService.getTalepDetayByToken(widget.actionToken!);
      } else {
        final res =
            await DersDevirService.getTalepDetay(talepId: widget.talepId!);
        detay = res.data;
      }
      if (!mounted) return;
      setState(() {
        _detay = detay;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = 'Talep detayı alınamadı: $e';
        _loading = false;
      });
    }
  }

  Future<void> _kabulEt() async {
    final t = _detay?.talep;
    if (t == null) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      if (_useToken) {
        await DersDevirService.talepKabulEtByToken(widget.actionToken!);
      } else {
        await DersDevirService.talepCevapla(
          talepId: t.id,
          islem: 'kabul',
        );
      }
      if (!mounted) return;
      ShowMessage.success(context, 'Devir kabul edildi.');
      _close();
    } on ApiException catch (e) {
      setState(() => _saving = false);
      if (mounted) ShowMessage.error(context, e.message);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ShowMessage.error(context, 'Hata: $e');
    }
  }

  Future<void> _reddet() async {
    final t = _detay?.talep;
    if (t == null) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final cevapNotu = _redCtrl.text.trim();
      if (_useToken) {
        await DersDevirService.talepRedEtByToken(
          widget.actionToken!,
          cevapNotu: cevapNotu,
        );
      } else {
        await DersDevirService.talepCevapla(
          talepId: t.id,
          islem: 'red',
          cevapNotu: cevapNotu,
        );
      }
      if (!mounted) return;
      ShowMessage.success(context, 'Devir reddedildi.');
      _close();
    } on ApiException catch (e) {
      setState(() => _saving = false);
      if (mounted) ShowMessage.error(context, e.message);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ShowMessage.error(context, 'Hata: $e');
    }
  }

  void _close() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      body: SafeArea(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: context.takvim.primary))
            : _hata != null
                ? _buildHataView(_hata!)
                : _buildContent(),
      ),
    );
  }

  Widget _buildHataView(String mesaj) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 56, color: _errorRed),
          const SizedBox(height: 16),
          Text(mesaj,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: _textSecondary)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _close,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Kapat'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final detay = _detay!;
    final t = detay.talep;

    final aktifDegil = t.durum != 'BEKLIYOR' ||
        t.suresiGecti ||
        !t.benHedefim ||
        !t.devralabilirMi;

    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBaslik(t),
                const SizedBox(height: 16),
                _buildEtkinlikKart(detay),
                const SizedBox(height: 16),
                _buildKatilimcilar(detay.katilimcilar),
                if (detay.digerRolAntrenor != null) ...[
                  const SizedBox(height: 16),
                  _buildDigerRolAntrenor(detay.digerRolAntrenor!),
                ],
                if ((t.talepNotu ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNotKart('Talep eden notu', t.talepNotu!),
                ],
                const SizedBox(height: 24),
                if (aktifDegil)
                  _buildDurumGosterimi(t)
                else if (_showRedForm)
                  _buildRedForm()
                else
                  _buildAksiyonButonlari(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kapat',
            icon: const Icon(Icons.close_rounded, color: _textPrimary),
            onPressed: _close,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBaslik(DevirTalebiTam t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.takvim.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.swap_horiz_rounded,
                  color: context.takvim.primary, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Ders Devir Teklifi',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${t.talepEdenAntrenorAdi}, bu dersi size ${t.rolLabel} rolünde devretmek istiyor.',
          style:
              const TextStyle(fontSize: 14, color: _textSecondary, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildEtkinlikKart(DevirTalebiDetayDto detay) {
    final e = detay.etkinlik;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKvRow(Icons.calendar_today_rounded, 'Tarih', e.tarih),
          const SizedBox(height: 8),
          _buildKvRow(Icons.access_time_rounded, 'Saat', e.saat),
          const SizedBox(height: 8),
          _buildKvRow(Icons.sports_tennis_rounded, 'Kort', e.kortAdi),
          if (e.urunAdi.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildKvRow(Icons.local_offer_rounded, 'Ürün', e.urunAdi),
          ],
        ],
      ),
    );
  }

  Widget _buildKvRow(IconData icon, String k, String v) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.takvim.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(k,
              style: const TextStyle(fontSize: 13, color: _textSecondary)),
        ),
        Expanded(
          child: Text(v,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildKatilimcilar(List<DevirTalebiKatilimciInfo> liste) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded,
                  size: 18, color: context.takvim.primary),
              const SizedBox(width: 8),
              Text(
                'Katılımcılar (${liste.length})',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (liste.isEmpty)
            const Text('Katılımcı yok',
                style: TextStyle(fontSize: 13, color: _textSecondary))
          else
            ...liste.map((k) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            context.takvim.primary.withValues(alpha: 0.15),
                        child: Text(
                          k.ad.isNotEmpty ? k.ad[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.takvim.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(k.adSoyad,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildDigerRolAntrenor(DevirTalebiDigerRolAntrenor a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: Colors.amber.shade800, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bu derste ${a.rolLabel}: ${a.adSoyad}',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotKart(String baslik, String icerik) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik,
              style: const TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(icerik, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildDurumGosterimi(DevirTalebiTam t) {
    String mesaj;
    IconData ikon;
    Color renk;

    if (t.suresiGecti) {
      mesaj = 'Bu talebin süresi geçti (ders başladı).';
      ikon = Icons.schedule_rounded;
      renk = _textSecondary;
    } else if (t.durum == 'KABUL_EDILDI') {
      mesaj = 'Bu talep kabul edildi.';
      ikon = Icons.check_circle_rounded;
      renk = _successGreen;
    } else if (t.durum == 'REDDEDILDI') {
      mesaj = 'Bu talep reddedildi.';
      ikon = Icons.cancel_rounded;
      renk = _errorRed;
    } else if (t.durum == 'GERI_CEKILDI') {
      mesaj = 'Talep eden, talebi geri çekti.';
      ikon = Icons.undo_rounded;
      renk = _textSecondary;
    } else if (!t.benHedefim) {
      mesaj = 'Bu talep size yönelik değil.';
      ikon = Icons.info_outline_rounded;
      renk = _textSecondary;
    } else if (!t.devralabilirMi) {
      mesaj = t.engelNedeni ?? 'Bu talebi kabul edemezsiniz.';
      ikon = Icons.block_rounded;
      renk = _errorRed;
    } else {
      mesaj = 'Bu talep artık aktif değil.';
      ikon = Icons.info_outline_rounded;
      renk = _textSecondary;
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: renk.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: renk.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(ikon, color: renk, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(mesaj,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: renk)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _close,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Kapat'),
          ),
        ),
      ],
    );
  }

  Widget _buildAksiyonButonlari() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _saving
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    setState(() => _showRedForm = true);
                  },
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Reddet',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: _errorRed,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _saving ? null : _kabulEt,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text('Kabul Et',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: _successGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRedForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _errorRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _errorRed.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_rounded, color: _errorRed, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Talebi Reddet',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                tooltip: 'Kapat',
                icon: const Icon(Icons.close_rounded),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => setState(() => _showRedForm = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _redCtrl,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Red nedeni (isteğe bağlı)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _reddet,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: const Text('Reddi Gönder',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: _errorRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
