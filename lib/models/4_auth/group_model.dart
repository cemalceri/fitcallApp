import 'dart:convert';

class GroupModel {
  final int id;
  final String name;
  final List<String> permissions;

  GroupModel({
    required this.id,
    required this.name,
    required this.permissions,
  });

  factory GroupModel.fromJson(dynamic json) {
    if (json is String) {
      try {
        return GroupModel(id: 0, name: json, permissions: []);
      } catch (_) {
        throw ArgumentError('Geçersiz JSON formatı: $json');
      }
    }
    if (json is! Map) {
      throw ArgumentError(
          'GroupModel.fromJson Map veya String bekler, ${json.runtimeType} geldi');
    }

    return GroupModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }

  /// Gelen JSON string doğrudan bir liste (array) içeriyorsa:
  /// örnek:
  /// [
  ///   {"id":4,"name":"uye","permissions":[]}
  /// ]
  static List<GroupModel> fromJsonList(String jsonString) {
    final List<dynamic> parsed = jsonDecode(jsonString);
    return parsed.map((item) => GroupModel.fromJson(item)).toList();
  }
}
