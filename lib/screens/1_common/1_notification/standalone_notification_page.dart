import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/services/notification/notification_action_service.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';

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
  String? _actionResult;
  bool _showAciklamaField = false;
  final _aciklamaController = TextEditingController();

  NotificationModel get notif => widget.notification;
  Map<String, dynamic> get displayData => notif.displayData ?? {};
  bool get isDersTeyit => notif.notificationType == NotificationType.dersTeyidi;
  bool get hasActionButtons => isDersTeyit && notif.hasAction;

  @override
  void initState() {
    super.initState();
    _markAsRead();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
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
                    if (_actionResult != null) _buildResultCard(),
                    if (_actionResult == null && hasActionButtons) ...[
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.close_rounded,
                  size: 20, color: Color(0xFF1E293B)),
            ),
            onPressed: _handleClose,
          ),
          const Expanded(
            child: Text('Bildirim Detayı',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = _getNotificationTheme();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: theme.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: theme.color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20)),
            child: Icon(theme.icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          Text(notif.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(notif.body,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 15,
                  height: 1.5),
              textAlign: TextAlign.center),
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.info_outline_rounded,
                    size: 18, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 10),
              const Text('Detaylar',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 16),
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
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w500)),
              ],
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_note_rounded,
                    size: 18, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 10),
              const Text('Açıklama (Opsiyonel)',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _aciklamaController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Katılamama nedeninizi yazabilirsiniz...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
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
          color: const Color(0xFF10B981),
          onTap: () => _executeAction('katilacak'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          label: _showAciklamaField ? 'Gönder' : 'Katılmayacağım',
          icon: _showAciklamaField ? Icons.send_rounded : Icons.cancel_rounded,
          color: const Color(0xFFEF4444),
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
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _showAciklamaField = false),
            child:
                Text('Vazgeç', style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
      bool outlined = false}) {
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
                    border: Border.all(color: color, width: 2))
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
                          color: outlined ? color : Colors.white))
                else ...[
                  Icon(icon, color: outlined ? color : Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(label,
                      style: TextStyle(
                          color: outlined ? color : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPositive
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: isPositive
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                shape: BoxShape.circle),
            child: Icon(isPositive ? Icons.check_rounded : Icons.close_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            isPositive
                ? 'Katılımınız Onaylandı'
                : 'Katılmayacağınız Bildirildi',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isPositive
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444)),
          ),
          const SizedBox(height: 8),
          Text(
            isPositive
                ? 'Dersinizde görüşmek üzere!'
                : 'Bildiriminiz antrenöre iletildi.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: const Text('Kapat',
                  style: TextStyle(
                      color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
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
            color: const Color(0xFF3B82F6),
            gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)]);
      case NotificationType.antrenorDegisikligi:
        return _NotificationTheme(
            icon: Icons.swap_horiz_rounded,
            color: const Color(0xFFF59E0B),
            gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)]);
      case NotificationType.dersIptal:
        return _NotificationTheme(
            icon: Icons.event_busy_rounded,
            color: const Color(0xFFEF4444),
            gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)]);
      case NotificationType.paketBitiyor:
      case NotificationType.paketBitti:
        return _NotificationTheme(
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF8B5CF6),
            gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)]);
      default:
        return _NotificationTheme(
            icon: Icons.notifications_rounded,
            color: const Color(0xFF6366F1),
            gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)]);
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
