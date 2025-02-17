import 'dart:convert';

class UserModel {
  final int id;
  final String password;
  final bool isSuperuser;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final bool isStaff;
  final bool isActive;
  final DateTime dateJoined;
  final List<int> groups;
  final List<dynamic> userPermissions;

  UserModel({
    required this.id,
    required this.password,
    required this.isSuperuser,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isStaff,
    required this.isActive,
    required this.dateJoined,
    required this.groups,
    required this.userPermissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      password: json['password'],
      isSuperuser: json['is_superuser'],
      username: json['username'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'],
      isStaff: json['is_staff'] ?? false,
      isActive: json['is_active'] ?? false,
      dateJoined: json['date_joined'] != null
          ? DateTime.parse(json['date_joined'])
          : DateTime.now(),
      groups: List<int>.from(json['groups']) ?? [],
      userPermissions: List<dynamic>.from(json['user_permissions']) ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'password': password,
      'is_superuser': isSuperuser,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'is_staff': isStaff,
      'is_active': isActive,
      'date_joined': dateJoined.toIso8601String(),
      'groups': groups,
      'user_permissions': userPermissions,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
