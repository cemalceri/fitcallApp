// lib/screens/1_common/ders_listesi/dersler_page.dart

import 'package:fitcall/models/9_yonetici/dashboard_models.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/services/yonetici/yonetici_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/1_common/ders_listesi/widgets/ders_istatistik_kartlar.dart';
import 'package:fitcall/screens/1_common/ders_listesi/widgets/ders_liste_item.dart';
import 'package:fitcall/screens/1_common/widgets/baslik_bandi.dart';
import 'package:fitcall/screens/1_common/widgets/bos_durum.dart';
import 'package:fitcall/screens/1_common/widgets/iskelet.dart';
import 'package:fitcall/screens/1_common/widgets/liste_satiri.dart';
import 'package:intl/intl.dart';
import 'package:fitcall/common/tarih_util.dart';
import 'package:fitcall/common/tema.dart';

class DerslerPage extends StatefulWidget {
  const DerslerPage({super.key});

  @override
  State<DerslerPage> createState() => _DerslerPageState();
}

class _DerslerPageState extends State<DerslerPage> {
  DerslerData? _data;
  bool _loading = true;
  String? _errorMessage;

  DateTime _secilenTarih = simdiKulup();
  String _filtre = 'tumu';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await YoneticiApiService.getDersler(
        tarih: _secilenTarih,
        filtre: _filtre,
      );
      if (mounted) {
        setState(() {
          _data = result.data;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Veriler yüklenirken bir hata oluştu.';
          _loading = false;
        });
      }
    }
  }

  void _onFiltreChanged(String filtre) {
    setState(() => _filtre = filtre);
    _loadData();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _secilenTarih,
      firstDate: simdiKulup().subtract(const Duration(days: 365)),
      lastDate: simdiKulup().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _secilenTarih = picked);
      _loadData();
    }
  }

  void _previousDay() {
    setState(
        () => _secilenTarih = _secilenTarih.subtract(const Duration(days: 1)));
    _loadData();
  }

  void _nextDay() {
    setState(() => _secilenTarih = _secilenTarih.add(const Duration(days: 1)));
    _loadData();
  }

  void _goToToday() {
    setState(() => _secilenTarih = simdiKulup());
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Kısa biçim: oklar ve "Bugün" arasında uzun gün adı kesiliyordu.
    final dateFormat = DateFormat('d MMM y, EEE', 'tr_TR');

    // Başlık, tarih seçici ve süzgeçler takım renginde bantta; liste sayfa
    // zemininde.
    final g = context.gecis;
    final kontrolZemini = g.onBaslik.withValues(alpha: 0.16);
    final kontrolStili = IconButton.styleFrom(
      backgroundColor: kontrolZemini,
      foregroundColor: g.onBaslik,
    );

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BaslikBandi(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dersler',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: g.onBaslik,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Tarih seçici
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Önceki gün',
                        onPressed: _previousDay,
                        icon: const Icon(Icons.chevron_left),
                        style: kontrolStili,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            // Yalnız kenarlık: dolgu üstünde beyaz yazı Binay
                            // açıkta eşiğin altında kalıyordu.
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: g.onBaslik.withValues(alpha: 0.6)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 16, color: g.onBaslik),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    dateFormat.format(_secilenTarih),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: g.onBaslik,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sonraki gün',
                        onPressed: _nextDay,
                        icon: const Icon(Icons.chevron_right),
                        style: kontrolStili,
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: _goToToday,
                        child: const Text('Bugün'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Filtre
                  _buildFiltreler(colorScheme),
                ],
              ),
            ),

            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltreler(ColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          BaslikCipi(
            etiket: 'Tümü',
            secili: _filtre == 'tumu',
            onSec: () => _onFiltreChanged('tumu'),
          ),
          const SizedBox(width: 8),
          BaslikCipi(
            etiket: 'Tamamlandı',
            secili: _filtre == 'tamamlandi',
            onSec: () => _onFiltreChanged('tamamlandi'),
          ),
          const SizedBox(width: 8),
          BaslikCipi(
            etiket: 'Bekliyor',
            secili: _filtre == 'bekliyor',
            onSec: () => _onFiltreChanged('bekliyor'),
          ),
          const SizedBox(width: 8),
          BaslikCipi(
            etiket: 'İptal',
            secili: _filtre == 'iptal',
            onSec: () => _onFiltreChanged('iptal'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const IskeletListe();
    }

    if (_errorMessage != null) {
      return BosDurum(
        ikon: Icons.error_outline_rounded,
        baslik: 'Liste alınamadı',
        aciklama: _errorMessage!,
        ikonRengi: context.renkler.hata,
        eylemEtiketi: 'Tekrar dene',
        eylemIkonu: Icons.refresh_rounded,
        onEylem: _loadData,
      );
    }

    if (_data == null || _data!.dersler.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.1),
            const BosDurum(
              ikon: Icons.event_busy_rounded,
              baslik: 'Ders yok',
              aciklama: 'Seçili tarih ve filtreye uyan ders bulunmuyor. '
                  'Başka bir gün seçebilir veya filtreyi değiştirebilirsiniz.',
            ),
          ],
        ),
      );
    }

    final dersler = _data!.dersler;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Bosluk.xxl),
        itemCount: dersler.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding:
                  const EdgeInsets.fromLTRB(Bosluk.l, 0, Bosluk.l, Bosluk.l),
              child: DersIstatistikKartlar(data: _data!.istatistikler),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 1) const ListeAyraci(solBosluk: 78),
              DersListeItemWidget(ders: dersler[index - 1]),
            ],
          );
        },
      ),
    );
  }
}
