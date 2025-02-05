class UserModel {
  final int id;
  final String username;

  UserModel({
    required this.id,
    required this.username,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
    };
  }
}

class NotificationModel {
  final int id;
  final UserModel recipient;
  final UserModel? actor;
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
      recipient: UserModel.fromJson(json['recipient']),
      actor: json['actor'] != null ? UserModel.fromJson(json['actor']) : null,
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
      'recipient': recipient.toJson(),
      'actor': actor?.toJson(),
      'title': title,
      'subject': subject,
      'body': body,
      'notification_type': notificationType,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
    };
  }
}
