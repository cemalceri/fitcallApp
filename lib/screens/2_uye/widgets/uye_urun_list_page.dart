import 'package:fitcall/models/8_urun/uye_urun_model.dart';
import 'package:fitcall/screens/2_uye/widgets/uye_urun_list_view.dart';
import 'package:fitcall/services/urun/urun_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';

class UyeUrunListPage extends StatefulWidget {
  const UyeUrunListPage({super.key});

  @override
  State<UyeUrunListPage> createState() => _UyeUrunListPageState();
}

class _UyeUrunListPageState extends State<UyeUrunListPage> {
  late Future<List<UyeUrunModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchUrunler();
  }

  Future<List<UyeUrunModel>> _fetchUrunler() async {
    try {
      final res = await UyeUrunApiService.fetchUrunList();
      return res.data ?? [];
    } on ApiException catch (e) {
      if (mounted) {
        ShowMessage.error(context, e.message);
      }
      return [];
    }
  }

  Future<void> _refresh() async {
    final f = _fetchUrunler();
    setState(() => _future = f);
    await f;
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
          'Üyelik & Paket Bilgilerim',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<UyeUrunModel>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snap.hasError) {
              return _buildHata(context, '${snap.error}');
            }

            final list = snap.data ?? const <UyeUrunModel>[];
            // ListView içeriği boş olsa da RefreshIndicator çalışsın diye
            // her durumda kaydırılabilir bir gövde döndürüyoruz.
            return UyeUrunListView(urunler: list);
          },
        ),
      ),
    );
  }

  Widget _buildHata(BuildContext context, String mesaj) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline_rounded,
            size: 56, color: colorScheme.error.withValues(alpha: 0.7)),
        const SizedBox(height: 12),
        Center(
          child: Text('Bilgiler alınamadı',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(mesaj,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
