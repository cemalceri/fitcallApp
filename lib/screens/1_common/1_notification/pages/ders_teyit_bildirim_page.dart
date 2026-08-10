// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/notification/notification_model.dart';
import 'package:fitcall/screens/1_common/1_notification/widgets/bildirim_ortak_widgetlari.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/2_uye/takvim/widgets/takvim_constants.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:fitcall/services/etkinlik/ders_teyit_service.dart';
import 'package:fitcall/services/notification/notification_action_service.dart';
import 'package:fitcall/services/notification/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/common/tarih_util.dart';

class DersTeyitBildirimPage extends StatefulWidget {
  final NotificationModel notification;
  const DersTeyitBildirimPage({super.key, required this.notification});

  @override
  State<DersTeyitBildirimPage> createState() => _DersTeyitBildirimPageState();
}

class _DersTeyitBildirimPageState extends State<DersTeyitBildirimPage> {
  bool _loading = false;
  bool _checkingStatus = true;
  bool _actionDone = false;
  bool _showKatilmayacagimForm = false;
  bool _showKatilacagimLoading = false;
  final _aciklamaController = TextEditingController();

  bool? _previouslyConfirmed;
  bool? _previousKatilacakMi;
  bool _isLessonPast = false;
  bool _isLessonCancelled = false;
  bool _tokenSuresiDoldu = false;

  /// Ön kontrolde bir kez çözülüp saklanır: teyit hangi uçtan gönderilecek?
  bool _oturumGecerli = false;
  String? _uyeId;

  NotificationModel get notif => widget.notification;
  Map<String, dynamic> get displayData => notif.displayData ?? {};
  String? get _etkinlikId => displayData['etkinlik_id']?.toString();

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

  /// Okundu işareti.
  ///
  /// Oturum açıkken auth'lu uç kullanılır: `/api/n/<token>/` login'siz akış için
  /// var ve token'ı 72 saatlik aksiyon penceresine tabi — üç günden eski bir
  /// bildirimi açmak sunucuda gereksiz bir 410 (ve bir WARNING log satırı)
  /// üretiyordu. Token ucu yalnızca oturum yokken (FCM'den gelip giriş
  /// yapılmamış durumda) yedek olarak kalıyor.
  Future<void> _markAsRead() async {
    try {
      if (notif.id > 0 && await StorageService.tokenGecerliMi()) {
        await NotificationService.markNotificationsRead([notif.id]);
        NotificationService.refreshUnreadCount();
        return;
      }
      if (notif.hasAction) {
        await NotificationActionService.markAsRead(notif.actionToken!);
      }
    } catch (_) {}
  }

  Future<void> _checkPreviousConfirmation() async {
    try {
      final etkinlikId = displayData['etkinlik_id'];
      final tarihStr = displayData['tarih'];
      final saatStr = displayData['saat'];
      final iptalMi = displayData['iptal_mi'] == true;

      // İptal kontrolü
      if (iptalMi) {
        setState(() {
          _isLessonCancelled = true;
          _checkingStatus = false;
        });
        return;
      }

      // Geçmiş ders kontrolü
      if (tarihStr != null) {
        final lessonDate =
            _parseLessonDate(tarihStr.toString(), saatStr?.toString());
        if (lessonDate != null && lessonDate.isBefore(simdiKulup())) {
          setState(() {
            _isLessonPast = true;
            _checkingStatus = false;
          });
          return;
        }
      }

      _oturumGecerli = await StorageService.tokenGecerliMi();
      if (_oturumGecerli) {
        _uyeId = (await StorageService.uyeBilgileriniGetir())?.id.toString();
      }

      if (etkinlikId != null && _uyeId != null) {
        final res = await DersTeyitService.getTeyitDetayBilgisi(
          etkinlikId: etkinlikId.toString(),
          uyeId: _uyeId!,
        );
        final data = res.data;
        if (data != null && data.teyit?.katilacakMi != null) {
          setState(() {
            _previouslyConfirmed = true;
            _previousKatilacakMi = data.teyit?.katilacakMi == true;
          });
        }
      }
    } on ApiException catch (e) {
      debugPrint('Teyit ön-kontrolü atlandı: ${e.message}');
    } catch (e) {
      debugPrint('Teyit kontrolü hatası: $e');
    }

    if (mounted) {
      setState(() => _checkingStatus = false);
    }
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
    } catch (e) {
      debugPrint('Tarih parse hatası: $e');
    }
    return null;
  }

  /// Teyidi gönderir.
  ///
  /// Oturum açıkken auth'lu uç kullanılır. Token ucu (`/api/n/<token>/`)
  /// login'siz akış için var ve 72 saatlik pencereye tabi: üye üç günden eski
  /// bir teyit bildirimini açtığında, ders hâlâ gelecekte olsa bile cevap
  /// veremiyor, yalnızca "Bildirim süresi dolmuş." hatası alıyordu. Auth'lu
  /// uçta böyle bir pencere yok ve yazdığı kayıt aynı (`EtkinlikTeyitModel`).
  Future<void> _teyitGonder(bool katilacak, {String aciklama = ''}) async {
    final etkinlikId = _etkinlikId;
    if (_oturumGecerli && _uyeId != null && etkinlikId != null) {
      await DersTeyitService.setDersTeyitBilgisi(
        uyeId: _uyeId!,
        etkinlikId: etkinlikId,
        durum: katilacak,
        aciklama: aciklama.isEmpty ? null : aciklama,
      );
      return;
    }

    if (!notif.hasAction) {
      throw ApiException('NO_ACTION', 'Bu bildirim için işlem yapılamıyor.');
    }
    await NotificationActionService.executeAction(
      notif.actionToken!,
      katilacak ? 'katilacak' : 'katilmayacak',
      aciklama: aciklama,
    );
  }

  /// Hata gösterimi.
  ///
  /// Eskiden `e.toString()` basılıyordu; kullanıcı "Hata kodu:(TOKEN_EXPIRED):
  /// Bildirim süresi dolmuş." gibi teknik bir metin görüyordu. `ApiException`ın
  /// kendi `message`'ı zaten Türkçe ve kullanıcıya dönük. Süresi dolmuş token
  /// ise hata değil bir durum: sayfanın kendi durum görünümüne geçilir.
  void _hatayiGoster(Object e) {
    if (e is ApiException) {
      // Sunucu "ders başlamış" diyorsa ekrandaki tarih kontrolü tutmamış
      // demektir (display_data okunamamış olabilir); sayfayı doğru duruma al.
      if (e.code == 'DERS_GECMIS') {
        setState(() => _isLessonPast = true);
        return;
      }
      if (e.code == 'TOKEN_EXPIRED' || e.statusCode == 410) {
        setState(() => _tokenSuresiDoldu = true);
        return;
      }
      ShowMessage.error(context, e.message);
      return;
    }
    ShowMessage.error(context, 'İşlem tamamlanamadı. Lütfen tekrar deneyin.');
  }

  Future<void> _katilacagim() async {
    if (_showKatilacagimLoading) return;
    setState(() => _showKatilacagimLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await _teyitGonder(true);
      if (mounted) {
        setState(() {
          _showKatilacagimLoading = false;
          _actionDone = true;
          _previousKatilacakMi = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _showKatilacagimLoading = false);
        _hatayiGoster(e);
      }
    }
  }

  Future<void> _katilmayacagim() async {
    if (_loading) return;
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    try {
      await _teyitGonder(false, aciklama: _aciklamaController.text.trim());
      if (mounted) {
        setState(() {
          _loading = false;
          _actionDone = true;
          _showKatilmayacagimForm = false;
          _previousKatilacakMi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _hatayiGoster(e);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BildirimRenkleri.arkaplanGri,
      body: SafeArea(
        child: _checkingStatus
            ? const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: TakvimColors.primary),
              )
            : Column(
                children: [
                  BildirimUstBarWidget(onClose: _handleClose),
                  Expanded(child: _buildContent()),
                ],
              ),
      ),
    );
  }

  Widget _buildContent() {
    // İptal edilen ders
    if (_isLessonCancelled) {
      return BildirimDurumGorunumWidget(
        icon: Icons.cancel_rounded,
        color: BildirimRenkleri.hataKirmizi,
        title: 'Ders İptal Edildi',
        subtitle: 'Bu ders iptal edilmiştir.',
        onClose: _handleClose,
      );
    }

    // Geçmiş ders
    if (_isLessonPast) {
      return BildirimDurumGorunumWidget(
        icon: Icons.schedule_rounded,
        color: BildirimRenkleri.yaziIkincil,
        title: 'Ders Tarihi Geçti',
        subtitle: 'Bu ders için katılım bildirimi artık yapılamaz.',
        onClose: _handleClose,
      );
    }

    // Teyit verilmiş
    if (_previouslyConfirmed == true) {
      final katilacak = _previousKatilacakMi == true;
      return BildirimDurumGorunumWidget(
        icon: katilacak ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: katilacak
            ? BildirimRenkleri.basariYesil
            : BildirimRenkleri.hataKirmizi,
        title: katilacak ? 'Katılacaksınız' : 'Katılmayacaksınız',
        subtitle: 'Bu ders için daha önce cevap verdiniz.',
        showChangeHint: true,
        onClose: _handleClose,
      );
    }

    // Bildirim süresi dolmuş (yalnızca oturum yokken karşılaşılır: auth'lu uçta
    // süre penceresi yok). Kırmızı toast yerine ne yapılacağını söyleyen ekran.
    if (_tokenSuresiDoldu) {
      return BildirimDurumGorunumWidget(
        icon: Icons.timer_off_rounded,
        color: BildirimRenkleri.uyariTuruncu,
        title: 'Bildirim Süresi Doldu',
        subtitle: 'Bu bildirim üç günden eski. Uygulamaya giriş yapıp '
            'takviminizden katılım bildirebilirsiniz.',
        onClose: _handleClose,
      );
    }

    // Aksiyon tamamlandı
    if (_actionDone) {
      final katilacak = _previousKatilacakMi == true;
      return BildirimDurumGorunumWidget(
        icon: katilacak ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: katilacak
            ? BildirimRenkleri.basariYesil
            : BildirimRenkleri.hataKirmizi,
        title: 'Bildirildi',
        subtitle: 'Cevabınız iletildi.',
        onClose: _handleClose,
      );
    }

    // Teyit ekranı
    return _buildConfirmationView();
  }

  Widget _buildConfirmationView() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BildirimKompaktBaslikWidget(displayData: displayData),
          const SizedBox(height: 16),
          BildirimMesajKutusuWidget(
            title: notif.title,
            body: notif.body,
          ),
          const SizedBox(height: 16),
          _KatilimBolumu(
            showForm: _showKatilmayacagimForm,
            isKatilacagimLoading: _showKatilacagimLoading,
            isKatilmayacagimLoading: _loading,
            aciklamaController: _aciklamaController,
            onKatilacagim: _katilacagim,
            onKatilmayacagimTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showKatilmayacagimForm = true);
            },
            onFormClose: () => setState(() => _showKatilmayacagimForm = false),
            onKatilmayacagim: _katilmayacagim,
          ),
          const SizedBox(height: 14),
          const _BilgilendirmeNotu(),
          const SizedBox(height: 16),
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
                      fontWeight: FontWeight.w600,
                      color: BildirimRenkleri.yaziAna)),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                  DERS TEYİDİNE ÖZEL WIDGET'LAR (PRIVATE)                    */
/* -------------------------------------------------------------------------- */

class _KatilimBolumu extends StatelessWidget {
  final bool showForm;
  final bool isKatilacagimLoading;
  final bool isKatilmayacagimLoading;
  final TextEditingController aciklamaController;
  final VoidCallback onKatilacagim;
  final VoidCallback onKatilmayacagimTap;
  final VoidCallback onFormClose;
  final VoidCallback onKatilmayacagim;

  const _KatilimBolumu({
    required this.showForm,
    required this.isKatilacagimLoading,
    required this.isKatilmayacagimLoading,
    required this.aciklamaController,
    required this.onKatilacagim,
    required this.onKatilmayacagimTap,
    required this.onFormClose,
    required this.onKatilmayacagim,
  });

  @override
  Widget build(BuildContext context) {
    if (showForm) {
      return _KatilmayacagimForm(
        aciklamaController: aciklamaController,
        isLoading: isKatilmayacagimLoading,
        onClose: onFormClose,
        onSubmit: onKatilmayacagim,
      );
    }

    return _KatilimButonlari(
      isKatilacagimLoading: isKatilacagimLoading,
      onKatilacagim: onKatilacagim,
      onKatilmayacagim: onKatilmayacagimTap,
    );
  }
}

class _KatilimButonlari extends StatelessWidget {
  final bool isKatilacagimLoading;
  final VoidCallback onKatilacagim;
  final VoidCallback onKatilmayacagim;

  const _KatilimButonlari({
    required this.isKatilacagimLoading,
    required this.onKatilacagim,
    required this.onKatilmayacagim,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // KATILACAĞIM
        Expanded(
          child: FilledButton.icon(
            onPressed: isKatilacagimLoading ? null : onKatilacagim,
            icon: isKatilacagimLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_rounded, size: 18),
            label: const Text(
              'Katılacağım',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: BildirimRenkleri.basariYesil,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // KATILAMAYACAĞIM
        Expanded(
          child: FilledButton.icon(
            onPressed: isKatilacagimLoading ? null : onKatilmayacagim,
            icon: const Icon(Icons.event_busy_rounded, size: 18),
            label: const Text(
              'Katılamayacağım',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: TakvimColors.notAttending,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KatilmayacagimForm extends StatelessWidget {
  final TextEditingController aciklamaController;
  final bool isLoading;
  final VoidCallback onClose;
  final VoidCallback onSubmit;

  const _KatilmayacagimForm({
    required this.aciklamaController,
    required this.isLoading,
    required this.onClose,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
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
                        color: BildirimRenkleri.yaziAna)),
              ),
              IconButton(
                onPressed: onClose,
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
            controller: aciklamaController,
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
              onPressed: isLoading ? null : onSubmit,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                  isLoading ? 'Gönderiliyor...' : 'Katılamayacağımı Bildir',
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
}

class _BilgilendirmeNotu extends StatelessWidget {
  const _BilgilendirmeNotu();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          const SizedBox(height: 12),
          _buildMadde(
              'Ders iptali veya değişiklik taleplerinin en az 24 saat önceden bildirilmesini önemle rica ederiz. Bu süre içinde yapılmayan bildirimlerde ders, paket kapsamında kullanılmış sayılacaktır.'),
          const SizedBox(height: 6),
          _buildMadde(
              'Zamanında bildirilmeyen dersler sistem tarafından "gerçekleşti" olarak işaretlenmektedir.'),
          const SizedBox(height: 6),
          _buildMadde(
              'İstisnai hallerde, kort ve antrenör uygunluğu doğrultusunda telafi dersi planlanması için gerekli hassasiyet gösterilecektir; ancak telafi garantisi sunulamamaktadır.'),
          const SizedBox(height: 6),
          _buildMadde(
              'Saat değişikliği talepleriniz için kulübümüzle doğrudan iletişime geçmenizi rica ederiz. Bu gibi durumlarda "katılamayacağım" butonunun kullanılmaması sürecin daha sağlıklı ilerlemesini sağlayacaktır.'),
          const SizedBox(height: 6),
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
