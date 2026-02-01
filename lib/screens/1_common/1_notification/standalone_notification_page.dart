// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/screens/2_uye/takvim/widgets/takvim_constants.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_teyit_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/services/notification/notification_action_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';

const Color _textPrimary = Color(0xFF1A1A1A);
const Color _textSecondary = Color(0xFF6B7280);
const Color _successGreen = Color(0xFF10B981);
const Color _errorRed = Color(0xFFEF4444);
const Color _bgGray = Color(0xFFF9FAFB);

class StandaloneNotificationPage extends StatefulWidget {
  final NotificationModel notification;
  const StandaloneNotificationPage({super.key, required this.notification});

  @override
  State<StandaloneNotificationPage> createState() =>
      _StandaloneNotificationPageState();
}

class _StandaloneNotificationPageState
    extends State<StandaloneNotificationPage> {
  bool _loading = false;
  bool _checkingStatus = true;
  bool _actionDone = false;
  bool _showForm = false;
  final _aciklamaController = TextEditingController();

  bool? _previouslyConfirmed;
  bool? _previousKatilacakMi;
  bool _isLessonPast = false;

  NotificationModel get notif => widget.notification;
  Map<String, dynamic> get displayData => notif.displayData ?? {};
  bool get isDersTeyit => notif.notificationType == NotificationType.dersTeyidi;

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _checkPreviousConfirmation();
  }

  @override
  void dispose() {
    _aciklamaController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    if (!notif.hasAction) return;
    try {
      await NotificationActionService.markAsRead(notif.actionToken!);
    } catch (_) {}
  }

  Future<void> _checkPreviousConfirmation() async {
    if (!isDersTeyit) {
      setState(() => _checkingStatus = false);
      return;
    }

    try {
      final etkinlikId = displayData['etkinlik_id'];
      final tarihStr = displayData['tarih'];
      final saatStr = displayData['saat'];

      if (tarihStr != null) {
        final lessonDate = _parseLessonDate(tarihStr, saatStr);
        if (lessonDate != null && lessonDate.isBefore(DateTime.now())) {
          setState(() {
            _isLessonPast = true;
            _checkingStatus = false;
          });
          return;
        }
      }

      if (etkinlikId != null) {
        final uye = await StorageService.uyeBilgileriniGetir();
        if (uye != null) {
          final res = await DersTeyitService.getTeyitDetayBilgisi(
            etkinlikId: etkinlikId.toString(),
            uyeId: uye.id.toString(),
          );
          final data = res.data;
          if (data != null && data.teyit?.katilacakMi != null) {
            setState(() {
              _previouslyConfirmed = true;
              _previousKatilacakMi = data.teyit?.katilacakMi == true;
            });
          }
        }
      }
    } on ApiException catch (e) {
      ShowMessage.error(
          context, 'Teyit bilgisi alınırken hata oluştu: ${e.message}');
    } catch (e) {
      debugPrint('Teyit kontrolü hatası: $e');
    }

    setState(() => _checkingStatus = false);
  }

  DateTime? _parseLessonDate(String tarihStr, String? saatStr) {
    try {
      final months = {
        'ocak': 1,
        'şubat': 2,
        'mart': 3,
        'nisan': 4,
        'mayıs': 5,
        'haziran': 6,
        'temmuz': 7,
        'ağustos': 8,
        'eylül': 9,
        'ekim': 10,
        'kasım': 11,
        'aralık': 12,
      };

      final parts = tarihStr.toLowerCase().split(' ');
      if (parts.length >= 3) {
        final day = int.tryParse(parts[0]);
        final month = months[parts[1]];
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          int hour = 23, minute = 59;
          if (saatStr != null) {
            final tp = saatStr.split(':');
            if (tp.length >= 2) {
              hour = int.tryParse(tp[0]) ?? 23;
              minute = int.tryParse(tp[1]) ?? 59;
            }
          }
          return DateTime(year, month, day, hour, minute);
        }
      }

      final dotParts = tarihStr.split('.');
      if (dotParts.length >= 3) {
        final day = int.tryParse(dotParts[0]);
        final month = int.tryParse(dotParts[1]);
        final year = int.tryParse(dotParts[2]);
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day, 23, 59);
        }
      }
    } catch (e) {
      debugPrint('Tarih parse hatası: $e');
    }
    return null;
  }

  Future<void> _executeAction() async {
    if (!notif.hasAction || _loading) return;
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    try {
      await NotificationActionService.executeAction(
        notif.actionToken!,
        'katilmayacak',
        aciklama: _aciklamaController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _actionDone = true;
          _showForm = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ShowMessage.error(context, e.toString());
      }
    }
  }

  void _handleClose() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      SystemNavigator.pop();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      body: SafeArea(
        child: _checkingStatus
            ? const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: TakvimColors.primary),
              )
            : Column(
                children: [
                  _buildTopBar(),
                  Expanded(child: _buildContent()),
                ],
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: _bgGray,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: _textPrimary),
            onPressed: _handleClose,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLessonPast) {
      return _buildStatusView(
        icon: Icons.schedule_rounded,
        color: _textSecondary,
        title: 'Ders Tarihi Geçti',
        subtitle: 'Bu ders için katılım bildirimi artık yapılamaz.',
      );
    }

    if (_previouslyConfirmed == true) {
      final ok = _previousKatilacakMi == true;
      return _buildStatusView(
        icon: ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: ok ? _successGreen : _errorRed,
        title: ok ? 'Katılacaksınız' : 'Katılmayacaksınız',
        subtitle: 'Bu ders için daha önce cevap verdiniz.',
        showChangeHint: true,
      );
    }

    if (_actionDone) {
      return _buildStatusView(
        icon: Icons.cancel_rounded,
        color: _errorRed,
        title: 'Bildirildi',
        subtitle: 'Cevabınız iletildi.',
      );
    }

    return _buildConfirmationView();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  DURUM EKRANI
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStatusView({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    bool showChangeHint = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 24),
          Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 15, color: _textSecondary, height: 1.4),
              textAlign: TextAlign.center),
          if (showChangeHint) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: TakvimColors.primary),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Değiştirmek için kulüp ile iletişime geçin',
                      style: TextStyle(fontSize: 13, color: _textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleClose,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: _textSecondary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Kapat',
                  style: TextStyle(
                      color: _textPrimary, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TEYİT EKRANI
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildConfirmationView() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactHeader(),
          const SizedBox(height: 16),
          _buildNotificationMessage(),
          const SizedBox(height: 20),
          _buildKatilimSection(),
          const SizedBox(height: 16),
          _buildBilgilendirmeNotu(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleClose,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: const Text('Kapat',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: _textPrimary)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  KOMPAKT HEADER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCompactHeader() {
    final tarih = displayData['tarih'] ?? '';
    final saat = displayData['saat'] ?? '';
    final kort = displayData['kort_adi'] ?? displayData['kort'] ?? '';
    final antrenor =
        displayData['antrenor_adi'] ?? displayData['antrenor'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TakvimColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sports_tennis_rounded,
                  color: TakvimColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(tarih,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (saat.isNotEmpty)
              _buildInfoChip(Icons.access_time_rounded, saat),
            if (kort.isNotEmpty)
              _buildInfoChip(Icons.sports_tennis_rounded, kort),
            if (antrenor.isNotEmpty)
              _buildInfoChip(Icons.person_rounded, antrenor),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: TakvimColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BİLDİRİM MESAJI
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNotificationMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notif.title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 6),
          Text(notif.body,
              style: const TextStyle(
                  fontSize: 14, color: _textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  KATILIM BİLDİRİMİ
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildKatilimSection() {
    if (!_showForm) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _showForm = true);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  TakvimColors.notAttending,
                  TakvimColors.notAttending.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: TakvimColors.notAttending.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.event_busy_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Katılamayacak mısınız?',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      SizedBox(height: 2),
                      Text('Bildirmek için dokunun',
                          style:
                              TextStyle(fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TakvimColors.notAttending.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: TakvimColors.notAttending.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TakvimColors.notAttending.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_busy_rounded,
                    color: TakvimColors.notAttending, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Katılamayacağımı Bildir',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary)),
              ),
              IconButton(
                onPressed: () => setState(() => _showForm = false),
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.all(4),
                ),
                iconSize: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _aciklamaController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Açıklama (isteğe bağlı)',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: TakvimColors.notAttending, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _executeAction,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                  _loading ? 'Gönderiliyor...' : 'Katılamayacağımı Bildir',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: TakvimColors.notAttending,
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

  // ─────────────────────────────────────────────────────────────────────────
  //  ÖNEMLİ BİLGİLER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBilgilendirmeNotu() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TakvimColors.pending.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: TakvimColors.pending.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: TakvimColors.pending.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_rounded, color: TakvimColors.pending, size: 18),
                const SizedBox(width: 6),
                Text('Önemli Bilgiler',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TakvimColors.pending)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildMadde(
              'Ders iptali veya değişiklik taleplerinin en az 24 saat önceden bildirilmesini önemle rica ederiz. Bu süre içinde yapılmayan bildirimlerde ders, paket kapsamında kullanılmış sayılacaktır.'),
          const SizedBox(height: 8),
          _buildMadde(
              'Zamanında bildirilmeyen dersler sistem tarafından "gerçekleşti" olarak işaretlenmektedir.'),
          const SizedBox(height: 8),
          _buildMadde(
              'İstisnai hallerde, kort ve antrenör uygunluğu doğrultusunda telafi dersi planlanması için gerekli hassasiyet gösterilecektir; ancak telafi garantisi sunulamamaktadır.'),
          const SizedBox(height: 8),
          _buildMadde(
              'Saat değişikliği talepleriniz için kulübümüzle doğrudan iletişime geçmenizi rica ederiz. Bu gibi durumlarda "katılamayacağım" butonunun kullanılmaması sürecin daha sağlıklı ilerlemesini sağlayacaktır.'),
          const SizedBox(height: 8),
          _buildMadde(
              'Tüm sorularınız ve özel durumlarınız için ekibimiz size 8.30-20.30 saatleri arasında destek olmaktan memnuniyet duyacaktır.'),
        ],
      ),
    );
  }

  Widget _buildMadde(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: TakvimColors.pending.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
        ),
      ],
    );
  }
}
