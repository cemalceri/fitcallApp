// lib/screens/5_etkinlik/ders_teyit_page.dart

// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_teyit_service.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/common/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/buton_yukleniyor.dart';

class DersTeyitPage extends StatefulWidget {
  const DersTeyitPage({super.key});

  @override
  State<DersTeyitPage> createState() => _DersTeyitPageState();
}

class _DersTeyitPageState extends State<DersTeyitPage> {
  Map<String, dynamic>? _args;

  bool _isLoading = true;
  bool _posting = false;
  bool _cevapVerildi = false;
  bool? _secilenDurum; // null: seçilmedi, true: evet, false: hayır

  TeyitDetayModel? _detay;
  String? _hataMessaji;

  final TextEditingController _aciklamaController = TextEditingController();
  final FocusNode _aciklamaFocus = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_args != null) return;

    _args = ((ModalRoute.of(context)?.settings.arguments as Map?) ?? {})
        .cast<String, dynamic>();

    _loadDetay();
  }

  @override
  void dispose() {
    _aciklamaController.dispose();
    _aciklamaFocus.dispose();
    super.dispose();
  }

  Future<void> _loadDetay() async {
    final uyeId = _args?['uye_id']?.toString() ?? '';
    final etkinlikId = _args?['etkinlik_id']?.toString() ?? '';

    if (uyeId.isEmpty || etkinlikId.isEmpty) {
      setState(() {
        _isLoading = false;
        _hataMessaji = 'Eksik bilgi. Lütfen bildirime tekrar tıklayın.';
      });
      return;
    }

    try {
      // Okundu olarak işaretle
      await DersTeyitService.setTeyitOkunduApi(
        etkinlikId: etkinlikId,
        uyeId: uyeId,
      );

      // Detay bilgilerini al
      final res = await DersTeyitService.getTeyitDetayBilgisi(
        etkinlikId: etkinlikId,
        uyeId: uyeId,
      );

      setState(() {
        _detay = res.data;
        _isLoading = false;

        // Eğer zaten teyit verilmişse
        if (_detay?.teyitVerilmis == true) {
          _cevapVerildi = true;
          _secilenDurum = _detay?.teyit?.katilacakMi;
        }
      });
    } on ApiException catch (e) {
      setState(() {
        _isLoading = false;
        _hataMessaji = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hataMessaji = 'Bilgiler yüklenirken hata oluştu.';
      });
    }
  }

  Future<void> _submit() async {
    if (_posting || _secilenDurum == null) return;

    setState(() => _posting = true);
    HapticFeedback.mediumImpact();

    final uyeId = _args!['uye_id']?.toString() ?? '';
    final etkinlikId = _args!['etkinlik_id']?.toString() ?? '';

    try {
      final r = await DersTeyitService.setDersTeyitBilgisi(
        uyeId: uyeId,
        etkinlikId: etkinlikId,
        durum: _secilenDurum!,
        aciklama:
            _secilenDurum == false ? _aciklamaController.text.trim() : null,
      );

      setState(() => _cevapVerildi = true);
      HapticFeedback.heavyImpact();
      ShowMessage.success(context, r.mesaj);
    } on ApiException catch (e) {
      // DERS_GECMIS de 409 döner; aşağıdaki genel 409 dalı onu "karar zaten
      // verilmiş" sanıp ekranı cevaplanmış duruma çevirirdi. Cevap verilmedi,
      // ders geçti.
      if (e.code == 'DERS_GECMIS') {
        ShowMessage.warning(context, e.message);
      } else if (e.code == 'TEYIT_DEGISTIRME_YASAK' || e.statusCode == 409) {
        ShowMessage.warning(
          context,
          e.message.isNotEmpty
              ? e.message
              : 'Daha önce verdiğiniz karar değiştirilemez.',
        );
        setState(() => _cevapVerildi = true);
      } else if (e.code == 'TIMEOUT') {
        ShowMessage.error(context, 'Zaman aşımı. Lütfen tekrar deneyiniz.');
      } else {
        ShowMessage.error(
          context,
          e.message.isNotEmpty ? e.message : 'İşlem başarısız.',
        );
      }
    } catch (e) {
      ShowMessage.error(context, 'İşlem sırasında hata oluştu.');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ders Teyidi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoading()
          : _hataMessaji != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoading() => const IskeletKart(seritKutusu: 0);

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.renkler.hata.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: context.renkler.hata,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _hataMessaji!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Geri Dön'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Etkinlik bilgi kartı
          if (_detay != null) _buildEtkinlikKart(),

          const SizedBox(height: 24),

          // Teyit durumu veya seçim
          if (_cevapVerildi) _buildCevapVerildi() else _buildTeyitSecim(),
        ],
      ),
    );
  }

  Widget _buildEtkinlikKart() {
    final etkinlik = _detay!.etkinlik;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.sports_tennis_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _detay!.uye.adSoyad,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      etkinlik.kort,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Tarih ve saat
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.calendar_today_rounded,
                    'Tarih',
                    etkinlik.tarih,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.access_time_rounded,
                    'Saat',
                    '${etkinlik.saat} - ${etkinlik.bitisSaat}',
                  ),
                ),
              ],
            ),
          ),

          // Antrenör
          if (etkinlik.antrenor.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  etkinlik.antrenor,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildCevapVerildi() {
    final katilacak = _secilenDurum == true;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: katilacak
                  ? context.renkler.basari.withValues(alpha: 0.1)
                  : context.renkler.hata.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              katilacak ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 40,
              color: katilacak ? context.renkler.basari : context.renkler.hata,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            katilacak ? 'Katılımınız Onaylandı' : 'Katılmayacağınız Bildirildi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cevabınız alındı. Teşekkürler.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tamam'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeyitSecim() {
    final etkinlikGecmis = _detay?.etkinlik.gecmisMi ?? false;

    if (etkinlikGecmis) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.renkler.uyariZemin,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: context.renkler.uyari.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 48,
              color: context.renkler.uyari,
            ),
            const SizedBox(height: 16),
            Text(
              'Süre Doldu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.renkler.uyari,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu ders için teyit süresi geçmiştir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.renkler.uyari,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.renkler.uyari,
                  side: BorderSide(color: context.renkler.uyari),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tamam'),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Soru
        Text(
          'Bu derse katılacak mısınız?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 20),

        // Seçim butonları
        Row(
          children: [
            Expanded(
              child: _buildSecimButon(
                durum: true,
                icon: Icons.check_rounded,
                label: 'Evet',
                color: context.renkler.basari,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecimButon(
                durum: false,
                icon: Icons.close_rounded,
                label: 'Hayır',
                color: context.renkler.hata,
              ),
            ),
          ],
        ),

        // Açıklama alanı (Hayır seçilirse)
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _secilenDurum == false
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Açıklama (İsteğe bağlı)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _aciklamaController,
                      focusNode: _aciklamaFocus,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: InputDecoration(
                        hintText: 'Katılamama nedeninizi yazabilirsiniz...',
                        hintStyle: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 24),

        // Gönder butonu
        AnimatedOpacity(
          opacity: _secilenDurum != null ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: ElevatedButton(
            onPressed: _secilenDurum != null && !_posting ? _submit : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _posting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: ButonYukleniyorGostergesi(kalinlik: 2.5),
                  )
                : const Text(
                    'Gönder',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecimButon({
    required bool durum,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _secilenDurum == durum;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _secilenDurum = durum);

        // Hayır seçilirse açıklama alanına focus
        if (durum == false) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _aciklamaFocus.requestFocus();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? uzerineYazi(color)
                    : Theme.of(context).colorScheme.outline,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
