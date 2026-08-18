// lib/screens/3_antrenor/takvim/widgets/lesson_approval_dialog.dart

import 'package:fitcall/models/5_etkinlik/ders_katilim_data.dart';
import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/models/5_etkinlik/katilim_model.dart';
import 'package:fitcall/models/5_etkinlik/misafir_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/3_antrenor/takvim/widgets/katilim_not_dialog.dart';
import 'package:fitcall/screens/3_antrenor/takvim/widgets/misafir_ekle_sheet.dart';
import 'package:fitcall/screens/3_antrenor/takvim/widgets/plan_disi_uye_secim_sheet.dart';
import 'package:fitcall/screens/3_antrenor/takvim/widgets/yoklama_hizli_secim.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/etkinlik/takvim_service.dart';
import 'package:fitcall/services/uye/uye_api_service.dart';
import 'package:fitcall/screens/1_common/widgets/alt_sayfa.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'takvim_constants.dart';

/// Kilitli derste antrenörün gördüğü yoklama durumu.
///
/// Üç hal var, ikisi değil: yönetici onayı antrenör onay satırını yazmıyor,
/// dolayısıyla satırın hiç olmaması "ders yapılmadı" DEĞİL, "antrenör yoklama
/// almadı" demek. İkisini aynı kovaya koymak antrenöre vermediği kararı
/// göstermek olur.
@visibleForTesting
enum YoklamaDurumu { yapildi, yapilmadi, alinmadi }

@visibleForTesting
YoklamaDurumu yoklamaDurumu(bool? tamamlandi) => switch (tamamlandi) {
      true => YoklamaDurumu.yapildi,
      false => YoklamaDurumu.yapilmadi,
      null => YoklamaDurumu.alinmadi,
    };

class LessonApprovalDialog extends StatefulWidget {
  final EtkinlikModel ders;
  final int userId;
  final int? antrenorId;
  final VoidCallback onSuccess;

  const LessonApprovalDialog({
    super.key,
    required this.ders,
    required this.userId,
    this.antrenorId,
    required this.onSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required EtkinlikModel ders,
    required int userId,
    int? antrenorId,
    required VoidCallback onSuccess,
  }) async {
    altSayfaGoster<void>(
      context,
      cocuk: LessonApprovalDialog(
        ders: ders,
        userId: userId,
        antrenorId: antrenorId,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<LessonApprovalDialog> createState() => _LessonApprovalDialogState();
}

class _LessonApprovalDialogState extends State<LessonApprovalDialog> {
  bool _isSaving = false;
  bool _isLoading = true;

  // Mevcut katılım verisi (backend'den)
  DersKatilimDto? _katilimData;

  // Form state
  String? _secilenDurum; // 'yapildi' | 'yapilmadi'
  String? _secilenNeden;
  final _aciklamaCtrl = TextEditingController();

  // Katılım state — _katilimData yüklendikten sonra doldurulur
  // uyeId -> KatilimModel
  final Map<int, KatilimModel> _katilimMap = {};

  // Misafirler ayrı listede: üye kimlikleri yok, _katilimMap uye_id anahtarlı.
  final List<MisafirModel> _misafirler = [];

  /// Hızlı onay ekranından detaya geçildi mi?
  ///
  /// Antrenörün en sık yaşadığı durum "ders oldu, herkes geldi". Bu tek
  /// dokunuşla bitiyor; sapma varsa detay açılıyor. Kalabalık ikinci adıma
  /// taşındığı için %90 durumda hiç görülmüyor.
  bool _detayAcik = false;

  static const _yapildiNedenleri = [
    {'code': 'YPL_PLAN', 'label': 'Planlanan ders yapıldı'},
    {'code': 'YPL_TELAFI', 'label': 'Telafi dersi yapıldı'},
  ];

  static const _yapilmadiNedenleri = [
    {'code': 'YMD_OGRENCI', 'label': 'Öğrenci gelmedi'},
    {'code': 'YMD_ANTRENOR', 'label': 'Antrenör mazeretli'},
    {'code': 'YMD_HAVA', 'label': 'Hava şartları'},
    {'code': 'YMD_KORT', 'label': 'Kort müsait değil'},
    {'code': 'YMD_DIGER', 'label': 'Diğer'},
  ];

  @override
  void initState() {
    super.initState();
    _loadKatilim();
  }

  @override
  void dispose() {
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKatilim() async {
    try {
      final res =
          await TakvimService.getDersKatilimlari(dersId: widget.ders.id);
      final data = res.data;
      if (!mounted) return;

      setState(() {
        _katilimData = data;
        _isLoading = false;

        // Mevcut katılımları map'e koy
        if (data != null) {
          for (final k in data.katilimlar) {
            _katilimMap[k.uyeId] = k;
          }
          _misafirler
            ..clear()
            ..addAll(data.misafirler);

          // Antrenör onayı varsa form alanlarını doldur
          final ao = data.antrenorOnayi;
          if (ao?.tamamlandi != null) {
            _secilenDurum = ao!.tamamlandi! ? 'yapildi' : 'yapilmadi';
            _secilenNeden = ao.onayRedIptalNedeni;
            _aciklamaCtrl.text = ao.aciklama ?? '';
            // Daha önce kaydedilmiş ders doğrudan detayda açılır: antrenör
            // düzeltmeye geliyordur, hızlı onay ekranı yolu uzatır.
            _detayAcik = true;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ShowMessage.error(context, 'Katılım bilgisi yüklenemedi');
    }
  }

  bool get _kilitli => _katilimData?.kilitliMi ?? false;

  String _getNedenLabel(String? code, bool tamamlandi) {
    if (code == null) return '';
    final liste = tamamlandi ? _yapildiNedenleri : _yapilmadiNedenleri;
    final found = liste.where((n) => n['code'] == code).firstOrNull;
    return found?['label'] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Builder(
        builder: (context) => _isLoading
            ? _buildLoadingView()
            : _kilitli
                ? _buildKilitliView()
                : _detayAcik
                    ? _buildFormView()
                    : _buildHizliOnayView(),
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                              LOADING                                       */
  /* -------------------------------------------------------------------------- */

  Widget _buildLoadingView() {
    return SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Katılım bilgisi yükleniyor...',
            style: TextStyle(color: context.takvim.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                              KİLİTLİ VIEW                                  */
  /* -------------------------------------------------------------------------- */

  Widget _buildKilitliView() {
    final ao = _katilimData?.antrenorOnayi;
    final durum = yoklamaDurumu(ao?.tamamlandi);
    final (color, ikon, baslik) = switch (durum) {
      YoklamaDurumu.yapildi => (
          context.takvim.completed,
          Icons.check_circle_rounded,
          'Ders Yapıldı',
        ),
      YoklamaDurumu.yapilmadi => (
          context.takvim.notDone,
          Icons.cancel_rounded,
          'Ders Yapılmadı',
        ),
      // Takvim bloğu da bu dersi "bekliyor" rengiyle çiziyor; aynı ton.
      YoklamaDurumu.alinmadi => (
          context.takvim.pending,
          Icons.help_outline_rounded,
          'Yoklama Alınmadı',
        ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(color, 'Ders Yoklaması'),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(ikon, color: color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              baslik,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            if (durum == YoklamaDurumu.alinmadi) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Bu derse yoklama girmemişsiniz',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.takvim.textSecondary,
                                ),
                              ),
                            ] else if (ao?.onayRedIptalNedeni != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _getNedenLabel(ao!.onayRedIptalNedeni,
                                    durum == YoklamaDurumu.yapildi),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.takvim.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if ((ao?.aciklama ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Açıklama',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.takvim.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ao!.aciklama!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildKatilimOzeti(readonly: true),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_rounded,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          durum == YoklamaDurumu.alinmadi
                              ? 'Siz yoklama girmeden yönetici bu dersi sonuçlandırdığı için kayıt kilitlenmiştir. Değişiklik için yöneticinizle iletişime geçin.'
                              : 'Yönetici onayı verildiği için bu ders kilitlenmiştir. Değişiklik için yöneticinizle iletişime geçin.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.10),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: context.takvim.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tamam',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                              FORM VIEW                                     */
  /* -------------------------------------------------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                              HIZLI ONAY                                    */
  /* -------------------------------------------------------------------------- */

  /// Dialog'un açılış ekranı: en sık senaryo tek dokunuş.
  Widget _buildHizliOnayView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context.takvim.primary, 'Ders Yoklaması'),
        // Küçük ekran + büyük yazı ölçeğinde üç kart sayfaya sığmıyor.
        Flexible(
          child: SingleChildScrollView(
            child: YoklamaHizliSecim(
              katilimcilar: _katilimMap.values
                  .map((k) => k.adSoyad.trim())
                  .where((ad) => ad.isNotEmpty)
                  .toList(),
              kaydediliyor: _isSaving,
              onHepsiGeldi: _hepsiGeldiKaydet,
              onEksikFazla: () => setState(() {
                _detayAcik = true;
                _secilenDurum = 'yapildi';
                _secilenNeden = 'YPL_PLAN';
              }),
              onYapilmadi: () => setState(() {
                _detayAcik = true;
                _secilenDurum = 'yapilmadi';
                _secilenNeden = null;
              }),
            ),
          ),
        ),
      ],
    );
  }

  /// Tek dokunuşla: herkes katıldı, planlanan ders yapıldı, kaydet.
  Future<void> _hepsiGeldiKaydet() async {
    setState(() {
      _secilenDurum = 'yapildi';
      _secilenNeden = 'YPL_PLAN';
      for (final entry in _katilimMap.entries.toList()) {
        _katilimMap[entry.key] = entry.value.copyWith(katildi: true);
      }
    });
    await _kaydet();
  }

  Widget _buildFormView() {
    final hasOnceden = _katilimData?.antrenorOnayi?.tamamlandi != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(
          context.takvim.primary,
          hasOnceden ? 'Yoklamayı Güncelle' : 'Yoklama Al',
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ders durumu',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildDurumSecimi(),
                if (_secilenDurum != null) ...[
                  const SizedBox(height: 20),
                  _buildNedenSecimi(),
                  const SizedBox(height: 16),
                  _buildAciklamaField(),
                ],
                // Sadece "yapıldı" seçildiğinde katılımcı listesi açılır
                if (_secilenDurum == 'yapildi') ...[
                  const SizedBox(height: 24),
                  _buildKatilimEditor(),
                ],
              ],
            ),
          ),
        ),
        _buildActions(),
      ],
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                              KATILIM EDITOR                                */
  /* -------------------------------------------------------------------------- */

  Widget _buildKatilimEditor() {
    final entries = _katilimMap.values.toList()
      ..sort((a, b) {
        // Planlı önce, plan dışı sonra; ada göre
        if (a.planliMi != b.planliMi) return a.planliMi ? -1 : 1;
        return a.adSoyad.compareTo(b.adSoyad);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.groups_rounded, size: 18),
            const SizedBox(width: 6),
            const Text(
              'Katılımcılar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            // Üye ile misafir ayrı: biri listeden seçilir, diğerinin adı yazılır.
            TextButton.icon(
              onPressed: _planDisiEkle,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Üye'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                visualDensity: VisualDensity.compact,
              ),
            ),
            TextButton.icon(
              onPressed: _misafirEkle,
              icon: const Icon(Icons.person_add_alt_rounded, size: 18),
              label: const Text('Misafir'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty && _misafirler.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(Icons.people_outline_rounded,
                    size: 32,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 8),
                Text(
                  'Bu derste planlı katılımcı yok',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.takvim.textSecondary,
                  ),
                ),
                Text(
                  'Plan dışı üye ekleyebilirsiniz',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.takvim.textMuted,
                  ),
                ),
              ],
            ),
          )
        else ...[
          ...entries.map((k) => _buildKatilimRow(k)),
          ..._misafirler.map((m) => _buildMisafirRow(m)),
        ],
      ],
    );
  }

  Widget _buildMisafirRow(MisafirModel m) {
    final kilitli = m.kararVerildiMi;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        m.adSoyad,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Misafir',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                if ((m.notMetni ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    m.notMetni!,
                    style: TextStyle(
                        fontSize: 11, color: context.takvim.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (kilitli) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.lock_rounded,
                          size: 12, color: context.takvim.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Yönetici karar verdi',
                        style: TextStyle(
                            fontSize: 11, color: context.takvim.textMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!kilitli) ...[
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  size: 19,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              onPressed: () => _misafirDuzenle(m),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Düzenle',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  size: 20, color: Colors.red.shade400),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _misafirler.remove(m));
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Sil',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _misafirEkle() async {
    HapticFeedback.lightImpact();
    final yeni = await MisafirEkleSheet.goster(context);
    if (yeni == null) return;
    setState(() => _misafirler.add(yeni));
  }

  Future<void> _misafirDuzenle(MisafirModel m) async {
    final guncel = await MisafirEkleSheet.goster(context, mevcut: m);
    if (guncel == null) return;
    setState(() {
      final i = _misafirler.indexOf(m);
      if (i >= 0) _misafirler[i] = guncel;
    });
  }

  Widget _buildKatilimRow(KatilimModel k) {
    final katildi = k.katildi;

    Color borderColor;
    Color bgColor;
    if (katildi == true) {
      borderColor = context.takvim.completed;
      bgColor = context.takvim.completed.withValues(alpha: 0.06);
    } else if (katildi == false) {
      borderColor = context.takvim.cancelled;
      bgColor = context.takvim.cancelled.withValues(alpha: 0.06);
    } else {
      borderColor = Theme.of(context).colorScheme.outlineVariant;
      bgColor = Colors.grey.withValues(alpha: 0.10);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        k.adSoyad,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (k.planDisiMi) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Plan Dışı',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (k.planDisiMi) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _notDuzenle(k),
                    child: Row(
                      children: [
                        Icon(
                          (k.notMetni ?? '').isEmpty
                              ? Icons.note_add_outlined
                              : Icons.sticky_note_2_outlined,
                          size: 14,
                          color: context.takvim.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            (k.notMetni ?? '').isEmpty
                                ? 'Not ekle'
                                : k.notMetni!,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.takvim.textMuted,
                              fontStyle: (k.notMetni ?? '').isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Katıldı / Katılmadı toggle
          ToggleButtons(
            isSelected: [katildi == true, katildi == false],
            borderRadius: BorderRadius.circular(8),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 32),
            selectedColor: Colors.white,
            fillColor: katildi == true
                ? context.takvim.completed
                : (katildi == false
                    ? context.takvim.cancelled
                    : Theme.of(context).colorScheme.onSurfaceVariant),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            onPressed: (i) {
              HapticFeedback.selectionClick();
              setState(() {
                _katilimMap[k.uyeId] =
                    k.copyWith(katildi: i == 0 ? true : false);
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.check_rounded, size: 18),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
          // Plan dışı için sil butonu — yönetici karar verdiyse kilitli:
          // arkasında borç ya da paket düşümü var, silinirse öksüz kalır.
          if (k.planDisiMi)
            k.kararVerildiMi
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.lock_rounded,
                        size: 18, color: context.takvim.textMuted),
                  )
                : IconButton(
                    tooltip: 'Sil',
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 20, color: Colors.red.shade400),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _katilimMap.remove(k.uyeId));
                    },
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
        ],
      ),
    );
  }

  /// Sadece kilitli view'da gösterilen özet
  Widget _buildKatilimOzeti({required bool readonly}) {
    final entries = _katilimMap.values.toList()
      ..sort((a, b) {
        if (a.planliMi != b.planliMi) return a.planliMi ? -1 : 1;
        return a.adSoyad.compareTo(b.adSoyad);
      });

    if (entries.isEmpty && _misafirler.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.groups_rounded, size: 18),
            SizedBox(width: 6),
            Text(
              'Katılım Durumu',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...entries.map((k) {
          final katildi = k.katildi;
          IconData icon;
          Color color;
          if (katildi == true) {
            icon = Icons.check_circle_rounded;
            color = context.takvim.completed;
          } else if (katildi == false) {
            icon = Icons.cancel_rounded;
            color = context.takvim.cancelled;
          } else {
            icon = Icons.remove_circle_outline_rounded;
            color = Theme.of(context).colorScheme.onSurfaceVariant;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    k.adSoyad,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                if (k.planDisiMi)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Plan Dışı',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        ..._misafirler.map((m) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child:
                        Text(m.adSoyad, style: const TextStyle(fontSize: 13)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Misafir',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                              HEADER / FORM PARTS                           */
  /* -------------------------------------------------------------------------- */

  Widget _buildHeader(Color accentColor, String title) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.how_to_reg_rounded, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${TimeUtils.formatDateFull(widget.ders.baslangicTarihSaat)} • ${TimeUtils.formatTime(widget.ders.baslangicTarihSaat)}',
                  style: TextStyle(
                      fontSize: 13, color: context.takvim.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Kapat',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: context.takvim.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurumSecimi() {
    return Column(
      children: [
        _DurumSecenegi(
          isSelected: _secilenDurum == 'yapildi',
          icon: Icons.check_circle_rounded,
          color: context.takvim.completed,
          title: 'Ders yapıldı',
          subtitle: 'Katılımcıları işaretleyin',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _secilenDurum = 'yapildi';
              _secilenNeden = 'YPL_PLAN';
            });
          },
        ),
        const SizedBox(height: 10),
        _DurumSecenegi(
          isSelected: _secilenDurum == 'yapilmadi',
          icon: Icons.cancel_rounded,
          color: context.takvim.cancelled,
          title: 'Ders yapılmadı',
          subtitle: 'Tüm üyeler katılmadı sayılır',
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _secilenDurum = 'yapilmadi';
              _secilenNeden = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNedenSecimi() {
    final aktifListe =
        _secilenDurum == 'yapildi' ? _yapildiNedenleri : _yapilmadiNedenleri;
    final color = _secilenDurum == 'yapildi'
        ? context.takvim.completed
        : context.takvim.cancelled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _secilenDurum == 'yapildi' ? 'Detay' : 'Neden yapılmadı?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.takvim.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: aktifListe.map((n) {
            final isSelected = _secilenNeden == n['code'];
            return ChoiceChip(
              label: Text(n['label']!),
              selected: isSelected,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                setState(() => _secilenNeden = n['code']);
              },
              selectedColor: color.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? color : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAciklamaField() {
    return TextField(
      controller: _aciklamaCtrl,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'Açıklama (isteğe bağlı)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.10),
      ),
    );
  }

  Widget _buildActions() {
    final canSave =
        _secilenDurum != null && _secilenNeden != null && !_isSaving;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Vazgeç'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: canSave ? _kaydet : null,
              style: FilledButton.styleFrom(
                backgroundColor: context.takvim.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Kaydet',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                              ACTIONS                                       */
  /* -------------------------------------------------------------------------- */

  Future<void> _planDisiEkle() async {
    HapticFeedback.lightImpact();
    final mevcutIds = _katilimMap.keys.toSet();

    final secilen = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlanDisiUyeSecimSheet(haricUyeIds: mevcutIds),
    );

    if (secilen == null) return;

    // Seçilen üyeyi map'ten getir
    // Sheet sadece id döndürdüğü için adı sheet içinden alıp burada cache'lemek lazım.
    // Basitleştirmek için sheet kapanmadan önce cache'i tekrar kullanıyoruz:
    final cevap = await _uyeAdiniGetir(secilen);
    if (cevap == null) return;

    setState(() {
      _katilimMap[secilen] = KatilimModel(
        uyeId: secilen,
        adSoyad: cevap,
        planliMi: false,
        katildi: true, // plan dışı eklenince varsayılan: katıldı
        planDisiMi: true,
      );
    });

    // Not iste
    if (mounted) {
      _notDuzenle(_katilimMap[secilen]!);
    }
  }

  Future<String?> _uyeAdiniGetir(int uyeId) async {
    // UyeApiService'den (cache'li) ad bilgisini çek
    // import etmek için service dosyasını ekledik
    try {
      final res = await _getCachedUyeAdi(uyeId);
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getCachedUyeAdi(int uyeId) async {
    // ignore: avoid_dynamic_calls
    final dyn = await _importedUyeService();
    final list = dyn.data as List?;
    if (list == null) return null;
    for (final u in list) {
      if (u.id == uyeId) return u.adSoyad;
    }
    return null;
  }

  // UyeApiService.getAktifUyeler() çağırılıyor — sheet zaten cache'i doldurdu.
  // Bu fonksiyon placeholder; gerçek import aşağıdaki sheet üzerinden yapılır.
  Future<dynamic> _importedUyeService() async {
    // ignore: implementation_imports
    return await UyeApiService.getAktifUyeler();
  }

  void _notDuzenle(KatilimModel k) async {
    final yeniNot = await showDialog<String?>(
      context: context,
      builder: (_) => KatilimNotDialog(
        adSoyad: k.adSoyad,
        baslangicNot: k.notMetni,
      ),
    );
    if (yeniNot == null) return; // iptal
    setState(() {
      _katilimMap[k.uyeId] = k.copyWith(
        notMetni: yeniNot.isEmpty ? null : yeniNot,
        clearNot: yeniNot.isEmpty,
      );
    });
  }

  Future<void> _kaydet() async {
    setState(() => _isSaving = true);

    try {
      final tamamlandi = _secilenDurum == 'yapildi';
      // "yapılmadı" ise boş gönder, backend planlıları otomatik işaretler
      final katilimList = tamamlandi
          ? _katilimMap.values
              .where((k) => k.katildi != null) // null = işaretlenmemiş, atla
              .toList()
          : <KatilimModel>[];

      await TakvimService.setDersKatilimi(
        dersId: widget.ders.id,
        userId: widget.userId,
        tamamlandi: tamamlandi,
        aciklama: _aciklamaCtrl.text.trim(),
        onayRedIptalNedeni: _secilenNeden,
        katilimlar: katilimList,
        // "Yapılmadı"da misafir gönderilmez; backend kararsız kayıtları siler,
        // karar verilmiş kayıt varsa isteği reddeder.
        misafirler: tamamlandi ? _misafirler : const [],
      );

      if (mounted) {
        Navigator.pop(context);
        ShowMessage.success(context, 'Ders ve katılım kaydedildi');
        widget.onSuccess();
      }
    } on ApiException catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ShowMessage.error(context, e.message);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ShowMessage.error(context, 'Hata: $e');
    }
  }
}

/* -------------------------------------------------------------------------- */
/*                              YARDIMCI WIDGET'LAR                           */
/* -------------------------------------------------------------------------- */

class _DurumSecenegi extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DurumSecenegi({
    required this.isSelected,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? color
                  : Theme.of(context).colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 12, color: context.takvim.textSecondary),
                    ),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
