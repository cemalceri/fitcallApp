// lib/models/ilce_model.dart
class IlceModel {
  final int id;
  final int ilId;
  final String ad;

  IlceModel({
    required this.id,
    required this.ilId,
    required this.ad,
  });

  factory IlceModel.fromJson(Map<String, dynamic> json) => IlceModel(
        id: json['id'] as int,
        ilId: json['il'] as int,
        ad: json['ad'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'il': ilId,
        'ad': ad,
      };
}
