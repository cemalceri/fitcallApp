// lib/screens/6_muhasebe/widgets/para_hareket_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/services/muhasebe/para_hareket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitcall/models/6_muhasebe/para_hareket_model.dart';
import 'package:intl/intl.dart';

class ParaHareketPage extends StatefulWidget {
  final int yil;
  final int ay;
  const ParaHareketPage({super.key, required this.yil, required this.ay});

  @override
  State<ParaHareketPage> createState() => _ParaHareketPageState();
}

class _ParaHareketPageState extends State<ParaHareketPage> {
  late Future<List<ParaHareketModel>> _future;
  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  String get _monthName {
    const months = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return months[widget.ay];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _future = ParaHareketService.fetchForPeriod(widget.yil, widget.ay)
        .then((result) => result.data ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.05),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(colorScheme),
              Expanded(
                child: FutureBuilder<List<ParaHareketModel>>(
                  future: _future,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }
                    if (snap.hasError) {
                      return _buildErrorState(
                          colorScheme, snap.error.toString());
                    }
                    if (snap.data?.isEmpty ?? true) {
                      return _buildEmptyState(colorScheme);
                    }
                    return _buildTransactionList(snap.data!, colorScheme);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_monthName ${widget.yil}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Hesap hareketleri',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _loadData());
            },
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Hareketler yükleniyor...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Veri alınamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => setState(() => _loadData()),
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Kayıt bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu dönemde hesap hareketi yok',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
      List<ParaHareketModel> transactions, ColorScheme colorScheme) {
    // Toplam hesapla
    double toplamBorc = 0;
    double toplamOdeme = 0;
    for (final t in transactions) {
      if (t.hareketTuru == 'Alacak') {
        toplamBorc += t.tutar;
      } else {
        toplamOdeme += t.tutar;
      }
    }
    final fark = toplamOdeme - toplamBorc;

    return Column(
      children: [
        // Özet Kartı
        _buildSummaryRow(toplamBorc, toplamOdeme, fark, colorScheme),

        // Liste
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() => _loadData());
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return _TransactionCard(
                  transaction: transaction,
                  currencyFormat: _currencyFormat,
                  onTap: () => _showTransactionDetails(transaction),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
      double borc, double odeme, double fark, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Borç',
              value: _currencyFormat.format(borc),
              color: Colors.red,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Ödeme',
              value: _currencyFormat.format(odeme),
              color: Colors.green,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _SummaryItem(
              label: fark >= 0 ? 'Fazla' : 'Kalan',
              value: _currencyFormat.format(fark.abs()),
              color: fark >= 0 ? Colors.green : Colors.red,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(ParaHareketModel transaction) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TransactionDetailSheet(
        transaction: transaction,
        currencyFormat: _currencyFormat,
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Summary Item                                  */
/* -------------------------------------------------------------------------- */

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                           Transaction Card                                 */
/* -------------------------------------------------------------------------- */

class _TransactionCard extends StatelessWidget {
  final ParaHareketModel transaction;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.transaction,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOdeme = transaction.hareketTuru == 'Odeme';
    final typeColor = isOdeme ? Colors.green : Colors.red;
    final typeIcon =
        isOdeme ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final typeLabel = isOdeme ? 'Ödeme' : 'Borç';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // İkon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),

                const SizedBox(width: 14),

                // Bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd.MM.yyyy').format(transaction.tarih),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if ((transaction.aciklama ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          transaction.aciklama!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Tutar
                Text(
                  '${isOdeme ? '+' : '-'}${currencyFormat.format(transaction.tutar)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                        Transaction Detail Sheet                            */
/* -------------------------------------------------------------------------- */

class _TransactionDetailSheet extends StatelessWidget {
  final ParaHareketModel transaction;
  final NumberFormat currencyFormat;

  const _TransactionDetailSheet({
    required this.transaction,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOdeme = transaction.hareketTuru == 'Odeme';
    final typeColor = isOdeme ? Colors.green : Colors.red;
    final typeLabel = isOdeme ? 'Ödeme' : 'Borç';

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
            child: Column(
              children: [
                // İkon ve Tutar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOdeme
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 32,
                    color: typeColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${isOdeme ? '+' : '-'}${currencyFormat.format(transaction.tutar)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: typeColor,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Detaylar
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Tarih',
                        value: DateFormat('dd MMMM yyyy, EEEE', 'tr_TR')
                            .format(transaction.tarih),
                      ),
                      Divider(
                          height: 1,
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.3)),
                      if (transaction.odemeSekli != null) ...[
                        _DetailRow(
                          label: 'Ödeme Şekli',
                          value: transaction.odemeSekli!,
                        ),
                        Divider(
                            height: 1,
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.3)),
                      ],
                      _DetailRow(
                        label: 'Kayıt Tarihi',
                        value: DateFormat('dd.MM.yyyy HH:mm')
                            .format(transaction.olusturulmaZamani),
                      ),
                    ],
                  ),
                ),

                if ((transaction.aciklama ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Açıklama',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          transaction.aciklama!,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Kapat Butonu
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Kapat'),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
