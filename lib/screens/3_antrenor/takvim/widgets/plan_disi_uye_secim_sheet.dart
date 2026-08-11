// lib/screens/3_antrenor/takvim/widgets/plan_disi_uye_secim_sheet.dart

import 'package:fitcall/models/2_uye/basit_uye_model.dart';
import 'package:fitcall/services/uye/uye_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Plan dışı üye seçim sheet'i.
/// Seçilen üyenin id'sini Navigator.pop ile döner. İptal halinde null.
class PlanDisiUyeSecimSheet extends StatefulWidget {
  /// Bu id'ler listede gösterilmez (zaten katılımda olan üyeler)
  final Set<int> haricUyeIds;

  const PlanDisiUyeSecimSheet({
    super.key,
    this.haricUyeIds = const {},
  });

  @override
  State<PlanDisiUyeSecimSheet> createState() => _PlanDisiUyeSecimSheetState();
}

class _PlanDisiUyeSecimSheetState extends State<PlanDisiUyeSecimSheet> {
  final _searchCtrl = TextEditingController();
  List<BasitUyeModel> _all = [];
  List<BasitUyeModel> _filtered = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await UyeApiService.getAktifUyeler();
      if (!mounted) return;
      setState(() {
        _all = (res.data ?? [])
            .where((u) => !widget.haricUyeIds.contains(u.id))
            .toList();
        _filtered = _all;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Üye listesi yüklenemedi';
        _isLoading = false;
      });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.trim();
    setState(() {
      _filtered = _all.where((u) => u.matches(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = MediaQuery.of(context).size.height;

    return Container(
      height: h * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Plan Dışı Üye Ekle',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Listeden bir üye seçin',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'İsim, telefon veya üye no ile ara...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Temizle',
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => _searchCtrl.clear(),
                      ),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildListContent()),
        ],
      ),
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Tekrar dene')),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Eklenebilecek üye yok'
                  : 'Sonuç bulunamadı',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => Divider(
          height: 1, color: Theme.of(context).colorScheme.outlineVariant),
      itemBuilder: (ctx, i) {
        final u = _filtered[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.withValues(alpha: 0.10),
            child: Text(
              u.adSoyad.isNotEmpty ? u.adSoyad[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(
            u.adSoyad,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            [
              if (u.uyeNo > 0) 'Üye No: ${u.uyeNo}',
              if (u.telefon.isNotEmpty) u.telefon,
            ].join(' • '),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.add_circle_outline_rounded),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context, u.id);
          },
        );
      },
    );
  }
}
