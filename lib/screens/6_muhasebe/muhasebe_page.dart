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
        // Sadece o ayda borç oluşmuş aylar seçilebilir (aylık net negatif)
        if (_rows[index].buAyNet < 0) {
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
      total += _rows[index].buAyNet.abs();
    }
    return total;
  }

  /// Üstteki büyük kartın kaynağı: en yeni ayın kümülatif kapanış bakiyesi
  /// (Liste yeniden eskiye sıralı geldiği için _rows.first en güncel ay)
  double get _kumulatifBakiye {
    if (_rows.isEmpty) return 0;
    return _rows.first.kapanisBakiyesi;
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
                _buildSummaryCard(_kumulatifBakiye, colorScheme),
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

  /// Üst kart: kümülatif bakiye gösterir
  /// Pozitif = fazla ödeme (yeşil), Negatif = borç (kırmızı), 0 = nötr
  Widget _buildSummaryCard(double kapanisBakiyesi, ColorScheme colorScheme) {
    final isPositive = kapanisBakiyesi > 0;
    final isZero = kapanisBakiyesi == 0;
    final summaryColor = isZero
        ? colorScheme.onSurfaceVariant
        : (isPositive ? Colors.green : Colors.red);

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
              isZero
                  ? Icons.check_circle_outline_rounded
                  : isPositive
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
                  isZero
                      ? 'Borç Yok'
                      : isPositive
                          ? 'Fazla Ödeme'
                          : 'Kalan Borç',
                  style: TextStyle(
                    fontSize: 14,
                    color: summaryColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _currencyFormat.format(kapanisBakiyesi.abs()),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: summaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isPositive && !isZero && !_isSelectionMode)
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                // O ayda net borç oluşmuş ayları seç
                setState(() {
                  _selectedIndices.clear();
                  for (int i = 0; i < _rows.length; i++) {
                    if (_rows[i].buAyNet < 0) {
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
          final hasMonthDebt = row.buAyNet < 0;

          return _MonthCard(
            row: row,
            monthName: _getMonthName(row.ay),
            currencyFormat: _currencyFormat,
            isSelected: isSelected,
            isSelectionMode: _isSelectionMode,
            hasMonthDebt: hasMonthDebt,
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
            onLongPress: hasMonthDebt ? () => _toggleSelection(index) : null,
            onCheckChanged: hasMonthDebt
                ? (value) {
                    _toggleSelection(index);
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

/* -------------------------------------------------------------------------- */
/*                              Month Card Widget                             */
/* -------------------------------------------------------------------------- */

class _MonthCard extends StatelessWidget {
  final MuhasebeOzetModel row;
  final String monthName;
  final NumberFormat currencyFormat;
  final bool isSelected;
  final bool isSelectionMode;
  final bool hasMonthDebt;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool?>? onCheckChanged;

  const _MonthCard({
    required this.row,
    required this.monthName,
    required this.currencyFormat,
    required this.isSelected,
    required this.isSelectionMode,
    required this.hasMonthDebt,
    required this.onTap,
    this.onLongPress,
    this.onCheckChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Kalan'a göre vurgu rengi (sol rozet + sağ vurgu çizgisi için)
    final Color accentColor;
    if (row.kapanisBakiyesi > 0) {
      accentColor = Colors.green.shade600;
    } else if (row.kapanisBakiyesi < 0) {
      accentColor = Colors.red.shade600;
    } else {
      accentColor = colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.green.withValues(alpha: 0.08)
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
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sol renkli vurgu çizgisi (Kalan rengine göre)
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Checkbox (sadece seçim modu + bu ayda borç varsa)
                        if (isSelectionMode && hasMonthDebt)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Checkbox(
                              value: isSelected,
                              onChanged: onCheckChanged,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              activeColor: Colors.green,
                            ),
                          ),

                        // Ay rozeti (gradient + ay/yıl)
                        Container(
                          width: 56,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor.withValues(alpha: 0.18),
                                accentColor.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                row.ay.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                  letterSpacing: -0.5,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                row.yil.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor.withValues(alpha: 0.75),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Orta: Ay adı + durum etiketi
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                monthName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              _StatusBadge(
                                kapanisBakiyesi: row.kapanisBakiyesi,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Sağ: 4 satır rakam
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _DataRow(
                                label: 'Önceki',
                                value: row.acilisBakiyesi,
                                cf: currencyFormat,
                                kind: _RowKind.signed,
                              ),
                              const SizedBox(height: 3),
                              _DataRow(
                                label: 'Borç',
                                value: row.borc,
                                cf: currencyFormat,
                                kind: _RowKind.alwaysNegative,
                              ),
                              const SizedBox(height: 3),
                              _DataRow(
                                label: 'Ödeme',
                                value: row.odeme,
                                cf: currencyFormat,
                                kind: _RowKind.alwaysPositive,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 1,
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 6),
                              _DataRow(
                                label: 'Kalan',
                                value: row.kapanisBakiyesi,
                                cf: currencyFormat,
                                kind: _RowKind.signed,
                                isHighlighted: true,
                              ),
                            ],
                          ),
                        ),

                        if (!isSelectionMode) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                        ],
                      ],
                    ),
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
/*                            Status Badge                                    */
/* -------------------------------------------------------------------------- */

class _StatusBadge extends StatelessWidget {
  final double kapanisBakiyesi;

  const _StatusBadge({required this.kapanisBakiyesi});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color color;
    final String label;
    final IconData icon;

    if (kapanisBakiyesi > 0) {
      color = Colors.green.shade600;
      label = 'Fazla';
      icon = Icons.arrow_upward_rounded;
    } else if (kapanisBakiyesi < 0) {
      color = Colors.red.shade600;
      label = 'Borç';
      icon = Icons.arrow_downward_rounded;
    } else {
      color = colorScheme.onSurfaceVariant;
      label = 'Borç Yok';
      icon = Icons.check_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              Data Row                                      */
/* -------------------------------------------------------------------------- */

enum _RowKind {
  /// Pozitif=yeşil, negatif=kırmızı (Önceki, Kalan için)
  signed,

  /// Her zaman kırmızı, "-" ile gösterilir (Borç için, ham değer pozitif gelir)
  alwaysNegative,

  /// Her zaman yeşil, "+" ile gösterilir (Ödeme için, ham değer pozitif gelir)
  alwaysPositive,
}

class _DataRow extends StatelessWidget {
  final String label;
  final double value;
  final NumberFormat cf;
  final _RowKind kind;
  final bool isHighlighted;

  const _DataRow({
    required this.label,
    required this.value,
    required this.cf,
    required this.kind,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Renk ve gösterim metni
    Color color;
    String displayValue;

    if (value == 0) {
      color = colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
      displayValue = '—';
    } else {
      switch (kind) {
        case _RowKind.signed:
          if (value > 0) {
            color = Colors.green.shade600;
            displayValue =
                '${isHighlighted ? '+' : ''}${cf.format(value.abs())}';
          } else {
            color = Colors.red.shade600;
            displayValue = '-${cf.format(value.abs())}';
          }
          break;
        case _RowKind.alwaysNegative:
          color = Colors.red.shade600;
          displayValue = '-${cf.format(value.abs())}';
          break;
        case _RowKind.alwaysPositive:
          color = Colors.green.shade600;
          displayValue = '${isHighlighted ? '+' : ''}${cf.format(value.abs())}';
          break;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: isHighlighted ? 13 : 11.5,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // taşınca sondan görünsün
            physics: const ClampingScrollPhysics(),
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: isHighlighted ? 15 : 12.5,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                color: color,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              softWrap: false,
            ),
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
                Text(
                  'Online Ödeme Yakında!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
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
                          const phoneNumber = '905422462982';
                          const whatsappUrl = 'https://wa.me/$phoneNumber';
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
