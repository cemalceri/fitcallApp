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

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'],
      name: json['name'],
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'permissions': permissions,
    };
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
