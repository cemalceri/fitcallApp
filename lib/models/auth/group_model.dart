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

  static List<GroupModel> fromJsonList(String jsonString) {
    final parsed = jsonDecode(jsonString);
    return List<GroupModel>.from(
      parsed['groups'].map((group) => GroupModel.fromJson(group)),
    );
  }
}
