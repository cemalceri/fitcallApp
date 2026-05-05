// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/3_antrenor/ders_devir_talebi_model.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/antrenor/antrenor_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'takvim_constants.dart';

class LessonDevirDialog extends StatefulWidget {
  final EtkinlikModel ders;
  final VoidCallback onSuccess;

  const LessonDevirDialog({
    super.key,
    required this.ders,
    required this.onSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required EtkinlikModel ders,
    required VoidCallback onSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => LessonDevirDialog(ders: ders, onSuccess: onSuccess),
    );
  }

  @override
  State<LessonDevirDialog> createState() => _LessonDevirDialogState();
}

class _LessonDevirDialogState extends State<LessonDevirDialog> {
  bool _loading = true;
  bool _saving = false;
  String? _yuklemeHatasi;

  String? _rol; // 'ANA' | 'YARDIMCI'
  List<DevirAdayAntrenorModel> _adaylar = const [];
  DevirAdayAntrenorModel? _secilen;
  final _notCtrl = TextEditingController();

  AktifDevirTalebiModel? get _mevcutTalep => widget.ders.aktifDevirTalebi;

  /// Dersin sahibi (talep eden) bu kullanıcı mı?
  bool get _benTalepEden =>
      _mevcutTalep != null && _mevcutTalep!.benTalepEdenim;

  @override
  void initState() {
    super.initState();
    if (_mevcutTalep == null) {
      _adaylariYukle();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _notCtrl.dispose();
    super.dispose();
  }

  Future<void> _adaylariYukle() async {
    try {
      final res = await DersDevirService.getAdayAntrenorListesi(
        dersId: widget.ders.id,
      );
      final data = res.data;
      if (!mounted) return;
      setState(() {
        _rol = data?.rol;
        _adaylar = data?.antrenorler ?? const [];
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _yuklemeHatasi = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _yuklemeHatasi = 'Antrenör listesi alınamadı: $e';
        _loading = false;
      });
    }
  }

  Future<void> _talepGonder() async {
    if (_secilen == null) return;
    if (!_secilen!.devralabilirMi) {
      ShowMessage.error(
          context, _secilen!.engelNedeni ?? 'Bu antrenöre devir yapılamaz.');
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      await DersDevirService.talepOlustur(
        dersId: widget.ders.id,
        hedefAntrenorId: _secilen!.id,
        talepNotu: _notCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ShowMessage.success(context, 'Devir talebi gönderildi.');
        widget.onSuccess();
      }
    } on ApiException catch (e) {
      setState(() => _saving = false);
      if (mounted) ShowMessage.error(context, e.message);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ShowMessage.error(context, 'Hata: $e');
    }
  }

  Future<void> _talepGeriCek() async {
    final talep = _mevcutTalep;
    if (talep == null) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      await DersDevirService.talepGeriCek(talepId: talep.id);
      if (mounted) {
        Navigator.pop(context);
        ShowMessage.success(context, 'Devir talebi geri çekildi.');
        widget.onSuccess();
      }
    } on ApiException catch (e) {
      setState(() => _saving = false);
      if (mounted) ShowMessage.error(context, e.message);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ShowMessage.error(context, 'Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 480,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: _buildBody()),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TakvimColors.primary.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TakvimColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.swap_horiz_rounded,
                color: TakvimColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mevcutTalep != null ? 'Devir Talebi' : 'Dersi Devret',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${TimeUtils.formatDateFull(widget.ders.baslangicTarihSaat)} • ${TimeUtils.formatTime(widget.ders.baslangicTarihSaat)}',
                  style: TextStyle(
                      fontSize: 13, color: TakvimColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: TakvimColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_yuklemeHatasi != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: TakvimColors.cancelled, size: 40),
            const SizedBox(height: 12),
            Text(_yuklemeHatasi!,
                textAlign: TextAlign.center,
                style: TextStyle(color: TakvimColors.textSecondary)),
          ],
        ),
      );
    }

    if (_mevcutTalep != null) {
      return _buildMevcutTalepView(_mevcutTalep!);
    }

    return _buildYeniTalepForm();
  }

  Widget _buildMevcutTalepView(AktifDevirTalebiModel t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TakvimColors.pending.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: TakvimColors.pending.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TakvimColors.pending.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pending_rounded,
                      color: TakvimColors.pending, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Devir talebi cevap bekliyor',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: TakvimColors.pending,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _kvRow('Rol', t.rolLabel),
          _kvRow('Talep eden', t.talepEdenAntrenorAdi),
          _kvRow('Hedef antrenör', t.hedefAntrenorAdi),
          if ((t.talepNotu ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Not',
              style: TextStyle(fontSize: 12, color: TakvimColors.textMuted),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(t.talepNotu!, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: TextStyle(
                fontSize: 12,
                color: TakvimColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(v,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildYeniTalepForm() {
    final rolLabel =
        _rol == DevirRolu.ana ? 'ana antrenör' : 'yardımcı antrenör';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bu derste $rolLabel olarak görev yapıyorsunuz. Seçtiğiniz antrenöre devir teklifi gönderilecek.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Antrenör Seçin',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (_adaylar.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Text(
                  'Devredilecek antrenör bulunamadı.',
                  style: TextStyle(color: TakvimColors.textSecondary),
                ),
              ),
            )
          else
            ..._adaylar.map(_buildAdayTile),
          const SizedBox(height: 16),
          const Text(
            'Not (isteğe bağlı)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notCtrl,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Devir nedeni / mesaj...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdayTile(DevirAdayAntrenorModel a) {
    final disabled = !a.devralabilirMi;
    final selected = !disabled && _secilen?.id == a.id;

    Color renk;
    try {
      final hex = (a.renk ?? '').replaceAll('#', '');
      renk = hex.length == 6
          ? Color(int.parse('FF$hex', radix: 16))
          : TakvimColors.primary;
    } catch (_) {
      renk = TakvimColors.primary;
    }

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    setState(() => _secilen = a);
                  },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? TakvimColors.primary.withValues(alpha: 0.08)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? TakvimColors.primary : Colors.grey.shade200,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: renk.withValues(alpha: 0.2),
                    radius: 18,
                    child: Text(
                      a.adi.isNotEmpty ? a.adi[0].toUpperCase() : '?',
                      style:
                          TextStyle(color: renk, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.adSoyad,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        if (disabled && (a.engelNedeni ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              a.engelNedeni!,
                              style: TextStyle(
                                fontSize: 11,
                                color: TakvimColors.cancelled,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle_rounded,
                        color: TakvimColors.primary, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    if (_mevcutTalep != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kapat'),
              ),
            ),
            if (_benTalepEden) ...[
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _talepGeriCek,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Talebi Geri Çek',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  style: FilledButton.styleFrom(
                    backgroundColor: TakvimColors.pending,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final canSend = _secilen != null && _secilen!.devralabilirMi && !_saving;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Vazgeç'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: canSend ? _talepGonder : null,
              style: FilledButton.styleFrom(
                backgroundColor: TakvimColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Devir Talebi Gönder',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
