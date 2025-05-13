class NotificationModel {
  final int id;
  final int recipient;
  final String? actor;
  final String title;
  final String subject;
  final String body;
  final String notificationType; // Örneğin: 'DO', 'GO', 'PB', 'PS'
  final DateTime timestamp;
  final bool read;

  NotificationModel({
    required this.id,
    required this.recipient,
    this.actor,
    required this.title,
    required this.subject,
    required this.body,
    required this.notificationType,
    required this.timestamp,
    required this.read,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      recipient: json['recipient'] as int,
      actor: json['actor'] as String?,
      title: json['title'] as String,
      subject: json['subject'] as String,
      body: json['body'] as String,
      notificationType: json['notification_type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      read: json['read'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient': recipient,
      'actor': actor ?? '',
      'title': title,
      'subject': subject,
      'body': body,
      'notification_type': notificationType,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
    };
  }
}
