/// Bildirimden sonra yapılacak ertelenmiş aksiyon modelleri
enum PendingActionType { dersTeyit, bildirimListe }

class PendingAction {
  final PendingActionType type;
  final Map<String, dynamic> data;

  const PendingAction({required this.type, required this.data});

  /* ---------- json helpers ---------- */
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'data': data,
      };

  static PendingAction? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final typeStr = json['type'] as String?;
    final dataMap = (json['data'] as Map?)?.cast<String, dynamic>() ?? {};
    final type = PendingActionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => PendingActionType.bildirimListe,
    );
    return PendingAction(type: type, data: dataMap);
  }
}
