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
const Color _textPrimary = Color(0xFF262626);
const Color _textSecondary = Color(0xFF8E8E8E);
const Color _successGreen = Color(0xFF00D26A);
const Color _warningOrange = Color(0xFFFF9500);
const Color _errorRed = Color(0xFFED4956);
const Color _dividerColor = Color(0xFFDBDBDB);

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

  // Yeni state'ler - önceki teyit ve ders durumu kontrolü
  bool? _previouslyConfirmed; // Daha önce teyit verilmiş mi?
  bool?
      _previousKatilacakMi; // Önceki teyit değeri (true=katılacak, false=katılmayacak)
  bool _isLessonPast = false; // Ders tarihi geçmiş mi?
// Ders tarihi string

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

  /// Sayfa açıldığında bildirimi okundu olarak işaretle
  Future<void> _markAsRead() async {
    if (!notif.hasAction) return;

    try {
      await NotificationActionService.markAsRead(notif.actionToken!);
    } catch (_) {
      // Sessizce başarısız ol - kritik değil
    }
  }

  /// Önceki teyit durumunu ve ders tarihini kontrol et
  Future<void> _checkPreviousConfirmation() async {
    if (!isDersTeyit) {
      setState(() => _checkingStatus = false);
      return;
    }

    try {
      // displayData'dan etkinlik_id ve tarih bilgisi al
      final etkinlikId = displayData['etkinlik_id'];
      final tarihStr = displayData['tarih'];
      final saatStr = displayData['saat'];

      if (tarihStr != null) {
        // Tarih formatını parse et (örn: "15 Ocak 2025" veya "15.01.2025")
        final lessonDate = _parseLessonDate(tarihStr, saatStr);
        if (lessonDate != null && lessonDate.isBefore(DateTime.now())) {
          setState(() {
            _isLessonPast = true;
            _checkingStatus = false;
          });
          return;
        }
      }

      // Etkinlik ID varsa teyit durumunu kontrol et
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

  /// Tarih string'ini parse et
  DateTime? _parseLessonDate(String tarihStr, String? saatStr) {
    try {
      // "15 Ocak 2025" formatı
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

      // "15.01.2025" formatı
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _checkingStatus
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _textSecondary,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          if (displayData.isNotEmpty) ...[
                            _buildInfoCard(),
                            const SizedBox(height: 24),
                          ],
                          // Ders geçmişse uyarı göster
                          if (_isLessonPast) ...[
                            _buildPastLessonCard(),
                          ]
                          // Daha önce teyit verildiyse bilgi göster
                          else if (_previouslyConfirmed == true) ...[
                            _buildAlreadyConfirmedCard(),
                          ]
                          // Aksiyon sonucu varsa göster
                          else if (_actionResult != null) ...[
                            _buildResultCard(),
                          ]
                          // Aksiyon butonları
                          else if (hasActionButtons) ...[
                            if (_showAciklamaField) _buildAciklamaSection(),
                            const SizedBox(height: 16),
                            _buildActionButtons(),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(color: _dividerColor.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 22, color: _textPrimary),
            onPressed: _handleClose,
          ),
          const Expanded(
            child: Text(
              'Bildirim Detayı',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = _getNotificationTheme();
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.color.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(theme.icon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            notif.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            notif.body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    size: 20, color: _primaryBlue),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detaylar',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._buildInfoRows(),
        ],
      ),
    );
  }

  List<Widget> _buildInfoRows() {
    final rows = <Widget>[];

    if (displayData['tarih'] != null && displayData['saat'] != null) {
      rows.add(_buildInfoRow(Icons.event_rounded, 'Tarih & Saat',
          '${displayData['tarih']} - ${displayData['saat']}'));
    } else if (displayData['tarih'] != null) {
      rows.add(
          _buildInfoRow(Icons.event_rounded, 'Tarih', displayData['tarih']));
    }
    if (displayData['kort'] != null &&
        displayData['kort'].toString().isNotEmpty) {
      rows.add(_buildInfoRow(
          Icons.location_on_rounded, 'Kort', displayData['kort']));
    }
    if (displayData['antrenor'] != null) {
      rows.add(_buildInfoRow(
          Icons.sports_tennis_rounded, 'Antrenör', displayData['antrenor']));
    }
    if (displayData['uye_adi'] != null) {
      rows.add(
          _buildInfoRow(Icons.person_rounded, 'Üye', displayData['uye_adi']));
    }
    if (displayData['eski_antrenor'] != null &&
        displayData['yeni_antrenor'] != null) {
      rows.add(_buildInfoRow(Icons.swap_horiz_rounded, 'Değişiklik',
          '${displayData['eski_antrenor']} → ${displayData['yeni_antrenor']}'));
    }

    return rows;
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                         DERS GEÇMİŞ KARTI                                   */
  /* -------------------------------------------------------------------------- */
  Widget _buildPastLessonCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _textSecondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _textSecondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              color: _textSecondary,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ders Tarihi Geçmiş',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu dersin tarihi geçtiği için artık katılım bildirimi yapılamaz.',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleClose,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: _dividerColor),
              ),
              child: const Text(
                'Kapat',
                style:
                    TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                      DAHA ÖNCE TEYİT VERİLMİŞ KARTI                         */
  /* -------------------------------------------------------------------------- */
  Widget _buildAlreadyConfirmedCard() {
    final isPositive = _previousKatilacakMi == true;
    final color = isPositive ? _successGreen : _errorRed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: color,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isPositive
                ? 'Katılacağınızı Bildirdiniz'
                : 'Katılmayacağınızı Bildirdiniz',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isPositive
                ? 'Bu ders için daha önce katılacağınızı bildirdiniz.'
                : 'Bu ders için daha önce katılmayacağınızı bildirdiniz.',
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primaryBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _primaryBlue, size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cevabınızı değiştirmek isterseniz lütfen kulüp ile iletişime geçin.',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleClose,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: _dividerColor),
              ),
              child: const Text(
                'Kapat',
                style:
                    TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAciklamaSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _warningOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_note_rounded,
                    size: 20, color: _warningOrange),
              ),
              const SizedBox(width: 12),
              const Text(
                'Açıklama (Opsiyonel)',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _aciklamaController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Katılamama nedeninizi yazabilirsiniz...',
              hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          label: 'Katılacağım',
          icon: Icons.check_circle_rounded,
          color: _successGreen,
          onTap: () => _executeAction('katilacak'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          label: _showAciklamaField ? 'Gönder' : 'Katılmayacağım',
          icon: _showAciklamaField ? Icons.send_rounded : Icons.cancel_rounded,
          color: _errorRed,
          outlined: !_showAciklamaField,
          onTap: () {
            if (!_showAciklamaField) {
              setState(() => _showAciklamaField = true);
            } else {
              _executeAction('katilmayacak');
            }
          },
        ),
        if (_showAciklamaField) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _showAciklamaField = false),
            child:
                const Text('Vazgeç', style: TextStyle(color: _textSecondary)),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: outlined ? Colors.white : color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _loading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: outlined
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color, width: 2),
                  )
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_loading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: outlined ? color : Colors.white,
                    ),
                  )
                else ...[
                  Icon(icon, color: outlined ? color : Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: outlined ? color : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final isPositive = _actionResult == 'katilacak';
    final color = isPositive ? _successGreen : _errorRed;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              isPositive ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isPositive
                ? 'Katılımınız Onaylandı'
                : 'Katılmayacağınız Bildirildi',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPositive
                ? 'Dersinizde görüşmek üzere!'
                : 'Bildiriminiz antrenöre iletildi.',
            style: const TextStyle(fontSize: 14, color: _textSecondary),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleClose,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: _dividerColor),
              ),
              child: const Text(
                'Kapat',
                style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16),
              ),
            ),
          ),
        ],
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

  _NotificationTheme _getNotificationTheme() {
    switch (notif.notificationType) {
      case NotificationType.dersTeyidi:
        return _NotificationTheme(
          icon: Icons.event_available_rounded,
          color: _primaryBlue,
          gradient: const [Color(0xFF0095F6), Color(0xFF0077CC)],
        );
      case NotificationType.antrenorDegisikligi:
        return _NotificationTheme(
          icon: Icons.swap_horiz_rounded,
          color: _warningOrange,
          gradient: const [Color(0xFFFF9500), Color(0xFFFF7700)],
        );
      case NotificationType.dersIptal:
        return _NotificationTheme(
          icon: Icons.event_busy_rounded,
          color: _errorRed,
          gradient: const [Color(0xFFED4956), Color(0xFFD32F2F)],
        );
      case NotificationType.paketBitiyor:
      case NotificationType.paketBitti:
        return _NotificationTheme(
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF8B5CF6),
          gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        );
      default:
        return _NotificationTheme(
          icon: Icons.notifications_rounded,
          color: const Color(0xFF6366F1),
          gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
        );
    }
  }
}

class _NotificationTheme {
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  _NotificationTheme(
      {required this.icon, required this.color, required this.gradient});
}
