class PendingAction {
  final int notificationId;
  final String title;
  final String body;
  final String actionType;
  final String? actionScreen;
  final Map<String, dynamic>? actionParams;

  PendingAction({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.actionType,
    this.actionScreen,
    this.actionParams,
  });

  Map<String, dynamic> toJson() => {
        'notificationId': notificationId,
        'title': title,
        'body': body,
        'actionType': actionType,
        'actionScreen': actionScreen,
        'actionParams': actionParams,
      };

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      notificationId: json['notificationId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      actionType: json['actionType'] as String? ?? 'NO_ACTION',
      actionScreen: json['actionScreen'] as String?,
      actionParams: json['actionParams'] != null
          ? Map<String, dynamic>.from(json['actionParams'])
          : null,
    );
  }
}
