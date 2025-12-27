class NotificationType {
  static const dersTeyidi = 'DERS_TEYIDI';
  static const gecikenOdeme = 'GECIKEN_ODEME';
  static const paketBitiyor = 'PAKET_BITIYOR';
  static const paketSuresiDoluyor = 'PAKET_SURESI_DOLUYOR';
  static const paketBitti = 'PAKET_BITTI';
  static const telafiKullanildi = 'TELAFI_KULLANILDI';
  static const telafiIade = 'TELAFI_IADE';
  static const dersIptal = 'DERS_IPTAL';
  static const paketSatinAlma = 'PAKET_SATIN_ALMA';
  static const paketHakGuncelleme = 'PAKET_HAK_GUNCELLEME';
  static const uyelikTanimlandi = 'UYELIK_TANIMLANDI';
  static const antrenorDegisikligi = 'ANTRENOR_DEGISIKLIGI';
  static const genel = 'GENEL';
}

class ActionType {
  static const navigateToScreen = 'NAVIGATE_TO_SCREEN';
  static const openDialog = 'OPEN_DIALOG';
  static const refreshData = 'REFRESH_DATA';
  static const noAction = 'NO_ACTION';
}

class NotificationModel {
  final int id;
  final String notificationType;
  final String title;
  final String body;
  final String actionType;
  final String? actionScreen;
  final Map<String, dynamic>? actionParams;
  final bool isRead;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.body,
    required this.actionType,
    this.actionScreen,
    this.actionParams,
    required this.isRead,
    required this.timestamp,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      notificationType: json['notification_type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      actionType: json['action_type'] as String,
      actionScreen: json['action_screen'] as String?,
      actionParams: json['action_params'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      notificationType: notificationType,
      title: title,
      body: body,
      actionType: actionType,
      actionScreen: actionScreen,
      actionParams: actionParams,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp,
    );
  }
}
