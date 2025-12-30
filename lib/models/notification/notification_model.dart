import 'dart:convert';

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
  final Map<String, dynamic>? displayData;
  final String? actionToken;
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
    this.displayData,
    this.actionToken,
    required this.isRead,
    required this.timestamp,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      notificationType: json['notification_type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      actionType: json['action_type'] as String? ?? ActionType.noAction,
      actionScreen: json['action_screen'] as String?,
      actionParams: json['action_params'] as Map<String, dynamic>?,
      displayData: json['display_data'] as Map<String, dynamic>?,
      actionToken: json['action_token'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  factory NotificationModel.fromFCMData(Map<String, dynamic> data) {
    Map<String, dynamic>? actionParams;
    Map<String, dynamic>? displayData;

    try {
      final actionParamsRaw = data['action_params'];
      if (actionParamsRaw is String && actionParamsRaw.isNotEmpty) {
        actionParams = Map<String, dynamic>.from(jsonDecode(actionParamsRaw));
      } else if (actionParamsRaw is Map) {
        actionParams = Map<String, dynamic>.from(actionParamsRaw);
      }
    } catch (_) {}

    try {
      final displayDataRaw = data['display_data'];
      if (displayDataRaw is String && displayDataRaw.isNotEmpty) {
        displayData = Map<String, dynamic>.from(jsonDecode(displayDataRaw));
      } else if (displayDataRaw is Map) {
        displayData = Map<String, dynamic>.from(displayDataRaw);
      }
    } catch (_) {}

    return NotificationModel(
      id: int.tryParse(data['notification_id']?.toString() ?? '0') ?? 0,
      notificationType: data['notification_type']?.toString() ?? '',
      title: data['title']?.toString() ?? 'Bildirim',
      body: data['body']?.toString() ?? '',
      actionType: data['action_type']?.toString() ?? ActionType.noAction,
      actionScreen: data['action_screen']?.toString(),
      actionParams: actionParams,
      displayData: displayData,
      actionToken: data['action_token']?.toString(),
      isRead: false,
      timestamp: DateTime.now(),
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
      displayData: displayData,
      actionToken: actionToken,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp,
    );
  }

  bool get hasAction => actionToken != null && actionToken!.isNotEmpty;
}
