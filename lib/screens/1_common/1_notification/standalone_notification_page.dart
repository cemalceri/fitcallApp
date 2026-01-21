// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_teyit_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/services/notification/notification_action_service.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';

/* -------------------------------------------------------------------------- */
/*                             RENK SABİTLERİ                                  */
/* -------------------------------------------------------------------------- */
const Color _primaryBlue = Color(0xFF0095F6);
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
  String? _actionResult;
  bool _showAciklamaField = false;
  final _aciklamaController = TextEditingController();

  bool? _previouslyConfirmed;
  bool? _previousKatilacakMi;
  bool _isLessonPast = false;

  NotificationModel get notif => widget.notification;
  Map<String, dynamic> get displayData => notif.displayData ?? {};
  bool get isDersTeyit => notif.notificationType == NotificationType.dersTeyidi;
  bool get hasActionButtons => isDersTeyit && notif.hasAction;

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
            final timeParts = saatStr.split(':');
            if (timeParts.length >= 2) {
              hour = int.tryParse(timeParts[0]) ?? 23;
              minute = int.tryParse(timeParts[1]) ?? 59;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      body: SafeArea(
        child: _checkingStatus
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primaryBlue,
                ),
              )
            : Column(
                children: [
                  // Üst bar
                  _buildTopBar(),

                  // Ana içerik
                  Expanded(
                    child: _buildContent(),
                  ),
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
    // Ders geçmişse
    if (_isLessonPast) {
      return _buildStatusView(
        icon: Icons.schedule_rounded,
        iconBgColor: _textSecondary.withValues(alpha: 0.1),
        iconColor: _textSecondary,
        title: 'Ders Tarihi Geçti',
        subtitle: 'Bu ders için katılım bildirimi artık yapılamaz.',
      );
    }

    // Daha önce teyit verilmişse
    if (_previouslyConfirmed == true) {
      final isPositive = _previousKatilacakMi == true;
      return _buildStatusView(
        icon: isPositive ? Icons.check_circle_rounded : Icons.cancel_rounded,
        iconBgColor:
            (isPositive ? _successGreen : _errorRed).withValues(alpha: 0.1),
        iconColor: isPositive ? _successGreen : _errorRed,
        title: isPositive ? 'Katılacaksınız' : 'Katılmayacaksınız',
        subtitle: 'Bu ders için daha önce cevap verdiniz.',
        showChangeHint: true,
      );
    }

    // İşlem sonucu
    if (_actionResult != null) {
      final isPositive = _actionResult == 'katilacak';
      return _buildStatusView(
        icon: isPositive ? Icons.check_circle_rounded : Icons.cancel_rounded,
        iconBgColor:
            (isPositive ? _successGreen : _errorRed).withValues(alpha: 0.1),
        iconColor: isPositive ? _successGreen : _errorRed,
        title: isPositive ? 'Katılımınız Onaylandı' : 'Bildirildi',
        subtitle:
            isPositive ? 'Dersinizde görüşmek üzere!' : 'Cevabınız iletildi.',
      );
    }

    // Normal akış - teyit bekleniyor
    return _buildConfirmationView();
  }

  /// Durum gösterimi (geçmiş, teyitli, sonuç)
  Widget _buildStatusView({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
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
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: _textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
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
                      size: 18, color: _primaryBlue),
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
          _buildCloseButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Ana teyit ekranı
  Widget _buildConfirmationView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                // Bildirim kartı
                _buildNotificationCard(),

                // Açıklama alanı (opsiyonel)
                if (_showAciklamaField) ...[
                  const SizedBox(height: 16),
                  _buildAciklamaField(),
                ],
              ],
            ),
          ),
        ),

        // Sabit butonlar
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0095F6), Color(0xFF0077CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // İkon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),

          // Başlık
          Text(
            notif.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // İçerik
          Text(
            notif.body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAciklamaField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Açıklama (opsiyonel)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _aciklamaController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Neden katılamayacağınızı yazabilirsiniz...',
              hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
              filled: true,
              fillColor: _bgGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ana buton - Katılacağım
          if (!_showAciklamaField) ...[
            _buildPrimaryButton(
              label: 'Katılacağım',
              icon: Icons.check_rounded,
              color: _successGreen,
              onTap: () => _executeAction('katilacak'),
            ),
            const SizedBox(height: 12),
          ],

          // İkincil buton - Katılmayacağım / Gönder
          _buildSecondaryButton(
            label: _showAciklamaField ? 'Gönder' : 'Katılmayacağım',
            icon: _showAciklamaField ? Icons.send_rounded : Icons.close_rounded,
            onTap: () {
              if (!_showAciklamaField) {
                setState(() => _showAciklamaField = true);
              } else {
                _executeAction('katilmayacak');
              }
            },
          ),

          // Vazgeç linki
          if (_showAciklamaField) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _showAciklamaField = false),
              child: const Text(
                'Vazgeç',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isConfirm = _showAciklamaField;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _loading ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: isConfirm ? Colors.white : _errorRed,
          backgroundColor: isConfirm ? _errorRed : Colors.transparent,
          side:
              isConfirm ? BorderSide.none : const BorderSide(color: _errorRed),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _loading && _showAciklamaField
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _handleClose,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: _textSecondary.withValues(alpha: 0.3)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'Kapat',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _executeAction(String action) async {
    if (!notif.hasAction || _loading) return;

    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    try {
      final aciklama =
          action == 'katilmayacak' ? _aciklamaController.text.trim() : '';
      await NotificationActionService.executeAction(notif.actionToken!, action,
          aciklama: aciklama);

      if (mounted) {
        setState(() {
          _loading = false;
          _actionResult = action;
          _showAciklamaField = false;
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
}
