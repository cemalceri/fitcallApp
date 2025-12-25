// lib/screens/6_muhasebe/muhasebe_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/6_muhasebe/muhasebe_ozet_model.dart';
import 'package:fitcall/screens/6_muhasebe/widgets/para_hareket_page.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/muhasebe/muhasebe_service.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MuhasebePage extends StatefulWidget {
  const MuhasebePage({super.key});

  @override
  State<MuhasebePage> createState() => _MuhasebePageState();
}

class _MuhasebePageState extends State<MuhasebePage> {
  bool _isLoading = true;
  List<MuhasebeOzetModel> _rows = [];
  final Set<int> _selectedIndices = {};
  bool _isSelectionMode = false;

  final _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await MuhasebeService.fetch();
      _rows = res.data ?? [];
    } on ApiException catch (e) {
      if (mounted) ShowMessage.error(context, e.message);
    } catch (e) {
      if (mounted) ShowMessage.error(context, 'Beklenmeyen bir hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelection(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) _isSelectionMode = false;
      } else {
        // Sadece borçlu ayları seçilebilir
        if (_rows[index].fark < 0) {
          _selectedIndices.add(index);
          _isSelectionMode = true;
        }
      }
    });
  }

  void _clearSelection() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndices.clear();
      _isSelectionMode = false;
    });
  }

  double get _selectedTotal {
    double total = 0;
    for (final index in _selectedIndices) {
      total += _rows[index].fark.abs();
    }
    return total;
  }

  void _showPaymentSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PaymentInfoSheet(
        selectedCount: _selectedIndices.length,
        totalAmount: _selectedTotal,
        currencyFormat: _currencyFormat,
      ),
    );
  }

  String _getMonthName(int month) {
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
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final toplamFark = _rows.fold<double>(0, (p, e) => p + e.fark);

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
              if (!_isLoading && _rows.isNotEmpty)
                _buildSummaryCard(toplamFark, colorScheme),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _rows.isEmpty
                        ? _buildEmptyState(colorScheme)
                        : _buildMonthList(colorScheme),
              ),
              if (_isSelectionMode) _buildSelectionBar(colorScheme),
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
                  'Hesap Özeti',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Borç ve ödeme detayları',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_isSelectionMode)
            TextButton(
              onPressed: _clearSelection,
              child: const Text('İptal'),
            )
          else
            IconButton(
              onPressed: _loadData,
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

  Widget _buildSummaryCard(double toplamFark, ColorScheme colorScheme) {
    final isPositive = toplamFark >= 0;
    final summaryColor = isPositive ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            summaryColor.withValues(alpha: 0.15),
            summaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: summaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: summaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPositive
                  ? Icons.account_balance_wallet_outlined
                  : Icons.warning_amber_rounded,
              color: summaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPositive ? 'Fazla Ödeme' : 'Kalan Borç',
                  style: TextStyle(
                    fontSize: 14,
                    color: summaryColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currencyFormat.format(toplamFark.abs()),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: summaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (!isPositive && !_isSelectionMode)
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                // Borçlu tüm ayları seç
                setState(() {
                  _selectedIndices.clear();
                  for (int i = 0; i < _rows.length; i++) {
                    if (_rows[i].fark < 0) {
                      _selectedIndices.add(i);
                    }
                  }
                  if (_selectedIndices.isNotEmpty) {
                    _isSelectionMode = true;
                  }
                });
              },
              icon: const Icon(Icons.payment_rounded, size: 18),
              label: const Text('Öde'),
              style: FilledButton.styleFrom(
                backgroundColor: summaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
          Text('Veriler yükleniyor...'),
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
            'Hesap kaydı bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Henüz borç veya ödeme kaydınız yok',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthList(ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _rows.length,
        itemBuilder: (context, index) {
          final row = _rows[index];
          final isSelected = _selectedIndices.contains(index);
          final hasDebt = row.fark < 0;

          return _MonthCard(
            row: row,
            monthName: _getMonthName(row.ay),
            currencyFormat: _currencyFormat,
            isSelected: isSelected,
            isSelectionMode: _isSelectionMode,
            hasDebt: hasDebt,
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(index);
              } else {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParaHareketPage(yil: row.yil, ay: row.ay),
                  ),
                );
              }
            },
            onLongPress: hasDebt ? () => _toggleSelection(index) : null,
            onCheckChanged: hasDebt
                ? (value) {
                    if (value == true) {
                      _toggleSelection(index);
                    } else {
                      _toggleSelection(index);
                    }
                  }
                : null,
          );
        },
      ),
    );
  }

  Widget _buildSelectionBar(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_selectedIndices.length} ay seçildi',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currencyFormat.format(_selectedTotal),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _showPaymentSheet,
            icon: const Icon(Icons.payment_rounded),
            label: const Text('Ödeme Yap'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Month Card Widget                             */
/* -------------------------------------------------------------------------- */

class _MonthCard extends StatelessWidget {
  final MuhasebeOzetModel row;
  final String monthName;
  final NumberFormat currencyFormat;
  final bool isSelected;
  final bool isSelectionMode;
  final bool hasDebt;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool?>? onCheckChanged;

  const _MonthCard({
    required this.row,
    required this.monthName,
    required this.currencyFormat,
    required this.isSelected,
    required this.isSelectionMode,
    required this.hasDebt,
    required this.onTap,
    this.onLongPress,
    this.onCheckChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final farkColor = row.fark >= 0 ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.green.withValues(alpha: 0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? Colors.green.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox (sadece seçim modunda ve borçlu aylarda)
                if (isSelectionMode && hasDebt)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: onCheckChanged,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: Colors.green,
                    ),
                  ),

                // Ay ikonu
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        row.ay.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        row.yil.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$monthName ${row.yil}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _InfoChip(
                            label: 'Borç',
                            value: currencyFormat.format(row.borc),
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            label: 'Ödeme',
                            value: currencyFormat.format(row.odeme),
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Fark
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: farkColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currencyFormat.format(row.fark.abs()),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: farkColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.fark >= 0 ? 'Fazla' : 'Borç',
                      style: TextStyle(
                        fontSize: 11,
                        color: farkColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),

                if (!isSelectionMode) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                           Payment Info Sheet                               */
/* -------------------------------------------------------------------------- */

class _PaymentInfoSheet extends StatelessWidget {
  final int selectedCount;
  final double totalAmount;
  final NumberFormat currencyFormat;

  const _PaymentInfoSheet({
    required this.selectedCount,
    required this.totalAmount,
    required this.currencyFormat,
  });

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
            child: Column(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 48,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 20),

                // Başlık
                Text(
                  'Online Ödeme Yakında!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 12),

                // Tutar özeti
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Seçilen Tutar',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        currencyFormat.format(totalAmount),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Bilgilendirme
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Colors.amber.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Şimdilik kulübe başvurun',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Online ödeme özelliği üzerinde çalışıyoruz. Şu an için ödeme yapmak istiyorsanız lütfen kulüp yönetimiyle iletişime geçin.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
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
                        child: const Text('Kapat'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          final phoneNumber = '905422464982';
                          final whatsappUrl = 'https://wa.me/$phoneNumber';
                          launchUrl(Uri.parse(whatsappUrl),
                              mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.phone_outlined, size: 18),
                        label: const Text('İletişim'),
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
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
