// lib/screens/6_muhasebe/widgets/payment_summary_sheet.dart

import 'package:fitcall/models/6_muhasebe/payment_hesaplama_model.dart';
import 'package:fitcall/screens/6_muhasebe/widgets/payment_webview_page.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/muhasebe/muhasebe_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PaymentSummarySheet extends StatefulWidget {
  final List<Map<String, int>> seciliAylar;
  final VoidCallback onComplete;

  const PaymentSummarySheet({
    super.key,
    required this.seciliAylar,
    required this.onComplete,
  });

  @override
  State<PaymentSummarySheet> createState() => _PaymentSummarySheetState();
}

class _PaymentSummarySheetState extends State<PaymentSummarySheet> {
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  bool _isLoading = true;
  bool _isStarting = false;
  PaymentHesaplamaModel? _hesaplama;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHesaplama();
  }

  Future<void> _loadHesaplama() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await MuhasebeService.hesapla(widget.seciliAylar);
      if (mounted) {
        setState(() {
          _hesaplama = result.data;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Beklenmeyen hata: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startPayment() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);
    HapticFeedback.mediumImpact();

    try {
      final result = await MuhasebeService.baslat(widget.seciliAylar);
      final data = result.data;
      if (data == null) throw Exception('Yanıt alınamadı');

      final paymentUrl = data['payment_url'] as String?;
      final siparisId = data['siparis_id'] as String?;
      final status = data['status'] as String?;

      if (!mounted) return;

      // NonSecure: direkt tamamlandı
      if (status == 'completed') {
        Navigator.pop(context);
        ShowMessage.success(context, 'Ödemeniz başarıyla tamamlandı!');
        widget.onComplete();
        return;
      }

      // 3D akışı: WebView aç
      if (paymentUrl != null && siparisId != null) {
        Navigator.pop(context); // Sheet'i kapat
        final success = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentWebViewPage(
              paymentUrl: paymentUrl,
              siparisId: siparisId,
            ),
          ),
        );
        if (success == true) {
          widget.onComplete();
        }
      }
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } catch (e) {
      if (mounted) ShowMessage.error(context, 'Ödeme başlatılamadı: $e');
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: _isLoading
                ? const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _errorMessage != null
                    ? _buildError(colorScheme)
                    : _hesaplama != null
                        ? _buildContent(colorScheme)
                        : const SizedBox.shrink(),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme colorScheme) {
    return Column(
      children: [
        Icon(Icons.error_outline, size: 48, color: colorScheme.error),
        const SizedBox(height: 16),
        Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.error),
        ),
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat'),
        ),
      ],
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    final h = _hesaplama!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.payment_rounded,
                  color: Colors.green, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ödeme Detayı',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${widget.seciliAylar.length} ay seçildi',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Kalem listesi
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              // Borç kalemleri
              ...h.borcKalemleri.map((k) => _KalemRow(
                    aciklama: k.aciklama,
                    tutar: _currencyFormat.format(k.tutar),
                    color: Colors.red,
                    icon: Icons.receipt_outlined,
                  )),

              // Ara toplam
              if (h.feeKalemleri.isNotEmpty) ...[
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                _KalemRow(
                  aciklama: 'Ara Toplam',
                  tutar: _currencyFormat.format(h.araToplam),
                  isBold: true,
                ),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ],

              // Fee kalemleri
              ...h.feeKalemleri.map((k) => _KalemRow(
                    aciklama: k.aciklama,
                    tutar: _currencyFormat.format(k.tutar),
                    color: Colors.orange,
                    icon: Icons.add_circle_outline,
                  )),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Toplam
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Toplam Tutar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                _currencyFormat.format(h.toplamTutar),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Butonlar
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('İptal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _isStarting ? null : _startPayment,
                icon: _isStarting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      )
                    : const Icon(Icons.lock_rounded, size: 18),
                label: Text(_isStarting ? 'İşleniyor...' : 'Güvenli Ödeme'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KalemRow extends StatelessWidget {
  final String aciklama;
  final String tutar;
  final Color? color;
  final IconData? icon;
  final bool isBold;

  const _KalemRow({
    required this.aciklama,
    required this.tutar,
    this.color,
    this.icon,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color ?? colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              aciklama,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            tutar,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
