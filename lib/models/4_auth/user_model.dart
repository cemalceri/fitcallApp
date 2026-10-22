import 'package:fitcall/common/tarih_util.dart';
import 'dart:convert';

/// Giriş yanıtındaki hesap bilgisi.
///
/// Sunucu 2026-10-22'den beri yalnız bu alanları gönderiyor; parola hash'i,
/// is_superuser/is_staff ve izin listeleri artık gelmiyor (cihaza da yazılmıyor).
class UserModel {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final bool isActive;
  final DateTime dateJoined;

  UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isActive,
    required this.dateJoined,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      isActive: json['is_active'] ?? false,
      dateJoined: json['date_joined'] != null
          ? parseApiTarihOrNow(json['date_joined'])
          : simdiKulup(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'is_active': isActive,
      'date_joined': dateJoined.toIso8601String(),
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
