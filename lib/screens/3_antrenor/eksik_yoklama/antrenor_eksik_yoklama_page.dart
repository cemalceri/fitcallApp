// lib/screens/3_antrenor/eksik_yoklama/antrenor_eksik_yoklama_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/5_etkinlik/etkinlik_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/screens/1_common/widgets/spinner_widgets.dart';
import 'package:fitcall/screens/3_antrenor/eksik_yoklama/widgets/eksik_yoklama_listesi.dart';
import 'package:fitcall/screens/3_antrenor/takvim/widgets/lesson_approval_dialog.dart';
import 'package:fitcall/services/antrenor/antrenor_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/services/core/storage_service.dart';
import 'package:flutter/material.dart';

class AntrenorEksikYoklamaPage extends StatefulWidget {
  const AntrenorEksikYoklamaPage({super.key});

  @override
  State<AntrenorEksikYoklamaPage> createState() =>
      _AntrenorEksikYoklamaPageState();
}

class _AntrenorEksikYoklamaPageState extends State<AntrenorEksikYoklamaPage> {
  List<EtkinlikModel> _dersler = [];
  bool _isLoading = true;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _userId = await SecureStorageService.getValue('user_id') ?? 0;
    await _yukle();
  }

  Future<void> _yukle() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await AntrenorApiService.getAntrenorEksikYoklamalar();
      if (!mounted) return;
      setState(() {
        _dersler = res.data ?? [];
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ShowMessage.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ShowMessage.error(context, 'Eksik yoklamalar alınamadı');
    }
  }

  void _dersTap(EtkinlikModel ders) {
    LessonApprovalDialog.show(
      context: context,
      ders: ders,
      userId: _userId,
      onSuccess: _yukle, // yoklama tamamlanınca liste yenilenir (ders düşer)
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Eksik Yoklamalar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const LoadingSpinnerWidget(message: 'Yükleniyor...')
          : RefreshIndicator(
              onRefresh: _yukle,
              child: _dersler.isEmpty
                  ? _bosDurum(theme)
                  : EksikYoklamaListesi(
                      dersler: _dersler,
                      onDersTap: _dersTap,
                    ),
            ),
    );
  }

  Widget _bosDurum(ThemeData theme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Icon(Icons.task_alt_rounded,
            size: 64, color: const Color(0xFF10B981).withValues(alpha: 0.7)),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Eksik yoklama yok 🎉',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Tüm derslerin yoklaması tamamlanmış.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
