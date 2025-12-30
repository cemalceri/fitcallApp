// lib/screens/5_etkinlik/ders_teyit_page.dart

// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_teyit_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';

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
      if (e.code == 'TEYIT_DEGISTIRME_YASAK' || e.statusCode == 409) {
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
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

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Bilgiler yükleniyor...',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

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
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _hataMessaji!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
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
        color: Colors.white,
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
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sports_tennis_rounded,
                  color: Color(0xFF3B82F6),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      etkinlik.kort,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
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
              color: const Color(0xFFF8FAFC),
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
                  color: const Color(0xFFE2E8F0),
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
                const Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  etkinlik.antrenor,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
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
        Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
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
        color: Colors.white,
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
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFEF4444).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              katilacak ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 40,
              color:
                  katilacak ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            katilacak ? 'Katılımınız Onaylandı' : 'Katılmayacağınız Bildirildi',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cevabınız alındı. Teşekkürler.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
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
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 48,
              color: Color(0xFFD97706),
            ),
            const SizedBox(height: 16),
            const Text(
              'Süre Doldu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu ders için teyit süresi geçmiştir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD97706),
                  side: const BorderSide(color: Color(0xFFD97706)),
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
        const Text(
          'Bu derse katılacak mısınız?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
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
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecimButon(
                durum: false,
                icon: Icons.close_rounded,
                label: 'Hayır',
                color: const Color(0xFFEF4444),
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
                    const Text(
                      'Açıklama (İsteğe bağlı)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
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
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF3B82F6), width: 2),
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
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
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
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
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
                color: isSelected ? color : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
