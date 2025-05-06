// lib/modules/auth/models/kullanici_model.dart

class KullaniciModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;

  KullaniciModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory KullaniciModel.fromJson(Map<String, dynamic> json) => KullaniciModel(
        id: json['id'] as int,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        email: json['email'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      };
}
