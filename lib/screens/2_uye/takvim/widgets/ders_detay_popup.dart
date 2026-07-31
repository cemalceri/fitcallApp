// lib/screens/5_etkinlik/takvim/widgets/ders_detay_popup.dart

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/ders_teyit_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'takvim_constants.dart';

class DersDetayPopup extends StatefulWidget {
  final EtkinlikModel ders;
  final int uyeId;
  final VoidCallback onSuccess;

  const DersDetayPopup({
    super.key,
    required this.ders,
    required this.uyeId,
    required this.onSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required EtkinlikModel ders,
    required int uyeId,
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DersDetayPopup(
        ders: ders,
        uyeId: uyeId,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<DersDetayPopup> createState() => _DersDetayPopupState();
}

class _DersDetayPopupState extends State<DersDetayPopup> {
  final _aciklamaController = TextEditingController();
  bool _isLoading = false;
  bool _showKatilmayacagimForm = false;

  @override
  void dispose() {
    _aciklamaController.dispose();
    super.dispose();
  }

  void _takvimeEkle() {
    HapticFeedback.lightImpact();
    final ders = widget.ders;
    final aciklamaParcalari = [
      if (ders.antrenorAdi != null && ders.antrenorAdi!.isNotEmpty)
        'Antrenör: ${ders.antrenorAdi}',
      if (ders.urunAdi != null && ders.urunAdi!.isNotEmpty)
        'Program: ${ders.urunAdi}',
    ];
    final event = Event(
      title: 'Tenis Dersi — ${ders.kortAdi}',
      description: aciklamaParcalari.join('\n'),
      location: ders.kortAdi,
      startDate: ders.baslangicTarihSaat,
      endDate: ders.bitisTarihSaat,
      iosParams: const IOSParams(reminder: Duration(hours: 1)),
    );
    Add2Calendar.addEvent2Cal(event);
  }

  Future<void> _katilacagim() async {
    setState(() => _isLoading = true);

    try {
      await DersTeyitService.setDersTeyitBilgisi(
        uyeId: widget.uyeId.toString(),
        etkinlikId: widget.ders.id.toString(),
        durum: true,
        aciklama: null,
      );

      if (mounted) {
        Navigator.pop(context);
        ShowMessage.success(context, 'Katılım durumunuz kaydedildi');
        widget.onSuccess();
      }
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ShowMessage.error(context, e.message);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ShowMessage.error(context, 'Bir hata oluştu: $e');
      }
    }
  }

  Future<void> _katilmayacagim() async {
    setState(() => _isLoading = true);

    try {
      await DersTeyitService.setDersTeyitBilgisi(
        uyeId: widget.uyeId.toString(),
        etkinlikId: widget.ders.id.toString(),
        durum: false,
        aciklama: _aciklamaController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ShowMessage.success(context, 'Katılım durumunuz kaydedildi');
        widget.onSuccess();
      }
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ShowMessage.error(context, e.message);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ShowMessage.error(context, 'Bir hata oluştu: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teyit = widget.ders.getTeyitBilgisi(widget.uyeId);
    final teyitVerilmis = teyit != null && teyit.katilacakMi != null;
    final iptalEdildi = widget.ders.iptalMi;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _buildCompactHeaderWithCancelBadge(theme, iptalEdildi),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (iptalEdildi) ...[
                    _buildIptalDurumuCard(),
                    const SizedBox(height: 16),
                    _buildIletisimNotu(),
                    const SizedBox(height: 20),
                  ],
                  if (teyitVerilmis && !iptalEdildi) ...[
                    _buildTeyitSonrasiCard(teyit),
                    const SizedBox(height: 16),
                  ],
                  if (!teyitVerilmis && !iptalEdildi) ...[
                    _buildKatilimButonlari(),
                    const SizedBox(height: 16),
                    _buildBilgilendirmeNotu(),
                    const SizedBox(height: 20),
                  ],
                  if (!iptalEdildi &&
                      widget.ders.baslangicTarihSaat
                          .isAfter(DateTime.now())) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _takvimeEkle,
                        icon: const Icon(Icons.calendar_month_outlined,
                            size: 18),
                        label: const Text(
                          'Telefon Takvimine Ekle',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color:
                                TakvimColors.primary.withValues(alpha: 0.4),
                          ),
                          foregroundColor: TakvimColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Kapat',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeaderWithCancelBadge(ThemeData theme, bool iptalEdildi) {
    final saat =
        '${TimeUtils.formatTime(widget.ders.baslangicTarihSaat)} - ${TimeUtils.formatTime(widget.ders.bitisTarihSaat)}';
    final kort = widget.ders.kortAdi;
    final antrenor = widget.ders.antrenorAdi;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iptalEdildi
                      ? Colors.red.shade50
                      : TakvimColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.sports_tennis_rounded,
                  color:
                      iptalEdildi ? Colors.red.shade400 : TakvimColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  TimeUtils.formatDateFull(widget.ders.baslangicTarihSaat),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (iptalEdildi)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade500,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade500.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'İPTAL EDİLDİ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.access_time_rounded, saat),
              _buildInfoChip(Icons.sports_tennis_rounded, kort),
              if (antrenor != null && antrenor.isNotEmpty)
                _buildInfoChip(Icons.person_rounded, antrenor),
            ],
          ),
        ],
      ),
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
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIptalDurumuCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.cancel_rounded,
                color: Colors.red.shade600, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ders Durumu',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'İptal Edildi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                  ),
                ),
                // Ad soyad `iptal_eden_adi`'nda geliyor; `iptal_eden` id
                // olduğu için koşul da ada bakmalı (yoksa "null" yazıyordu).
                if ((widget.ders.iptalEdenAdi ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'İptal eden: ${widget.ders.iptalEdenAdi}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeyitSonrasiCard(UyeTeyit teyit) {
    final katilacak = teyit.katilacakMi == true;
    final mesaj = katilacak
        ? 'Bu ders için katılacağınızı belirttiniz.'
        : 'Bu ders için katılamayacağınızı belirttiniz.';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: teyit.durumColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: teyit.durumColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: teyit.durumColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(teyit.durumIcon, color: teyit.durumColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mesaj,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: teyit.durumColor,
                      ),
                    ),
                    if (teyit.aciklama != null &&
                        teyit.aciklama!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Açıklama: ${teyit.aciklama}',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildIletisimNotu(),
      ],
    );
  }

  Widget _buildIletisimNotu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TakvimColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TakvimColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: TakvimColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Değişiklik talebiniz varsa lütfen iletişime geçiniz.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKatilimButonlari() {
    if (_showKatilmayacagimForm) {
      return _buildKatilmayacagimForm();
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _katilacagim,
            icon: _isLoading
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
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: _isLoading
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    setState(() => _showKatilmayacagimForm = true);
                  },
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

  Widget _buildKatilmayacagimForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TakvimColors.notAttending.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TakvimColors.notAttending.withValues(alpha: 0.25),
        ),
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
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: TakvimColors.notAttending,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Katılamayacağımı Bildir',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _showKatilmayacagimForm = false),
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
                  color: TakvimColors.notAttending,
                  width: 1.5,
                ),
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
              onPressed: _isLoading ? null : _katilmayacagim,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _isLoading ? 'Gönderiliyor...' : 'Katılamayacağımı Bildir',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: TakvimColors.notAttending,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBilgilendirmeNotu() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TakvimColors.pending.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TakvimColors.pending.withValues(alpha: 0.35),
          width: 1.2,
        ),
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
                Icon(
                  Icons.info_rounded,
                  color: TakvimColors.pending,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Önemli Bilgiler',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TakvimColors.pending,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildBilgiMaddesi(
              'Ders iptali veya değişiklik taleplerinin en az 24 saat önceden bildirilmesini önemle rica ederiz. Bu süre içinde yapılmayan bildirimlerde ders, paket kapsamında kullanılmış sayılacaktır.'),
          const SizedBox(height: 6),
          _buildBilgiMaddesi(
              'Zamanında bildirilmeyen dersler sistem tarafından "gerçekleşti" olarak işaretlenmektedir.'),
          const SizedBox(height: 6),
          _buildBilgiMaddesi(
              'İstisnai hallerde, kort ve antrenör uygunluğu doğrultusunda telafi dersi planlanması için gerekli hassasiyet gösterilecektir; ancak telafi garantisi sunulamamaktadır.'),
          const SizedBox(height: 6),
          _buildBilgiMaddesi(
              'Saat değişikliği talepleriniz için kulübümüzle doğrudan iletişime geçmenizi rica ederiz. Bu gibi durumlarda "katılamayacağım" butonunun kullanılmaması sürecin daha sağlıklı ilerlemesini sağlayacaktır.'),
          const SizedBox(height: 6),
          _buildBilgiMaddesi(
              'Tüm sorularınız ve özel durumlarınız için ekibimiz size 8.30-20.30 saatleri arasında destek olmaktan memnuniyet duyacaktır.'),
        ],
      ),
    );
  }

  Widget _buildBilgiMaddesi(String text) {
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
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
