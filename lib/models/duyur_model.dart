class AnnouncementModel {
  final String title;
  final String subtitle;
  final String content;
  final DateTime createdAt;

  AnnouncementModel({
    required this.title,
    required this.subtitle,
    required this.content,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      content: json['content'] as String? ?? '', // content alanı boş gelebilir
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
