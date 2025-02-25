import 'package:fitcall/models/1_common/notification_model.dart';
import 'package:fitcall/screens/1_common/1_notification/notification_methods.dart';
import 'package:flutter/material.dart';

// NotificationIcon widget'ı: Bildirim ikonuna tıklandığında NotificationPage'e yönlendirir.
class NotificationIcon extends StatelessWidget {
  final List<NotificationModel> notifications;

  const NotificationIcon({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationPage(notifications: notifications),
          ),
        );
      },
    );
  }
}

// NotificationPage widget'ı: Bildirimleri "Bugün", "Son 7 Gün" ve "Son 30 Gün" olarak gruplandırır.
// Eğer gönderilen notifications listesi boş ise, bildirimler tekrar çekilir.
class NotificationPage extends StatefulWidget {
  final List<NotificationModel> notifications;

  const NotificationPage({super.key, required this.notifications});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late List<NotificationModel> _notifications;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notifications = widget.notifications;

    // Eğer listede hiç bildirim yoksa, bildirimleri tekrar çekiyoruz.
    if (_notifications.isEmpty) {
      _fetchNotifications();
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });
    // Context'e ihtiyaç duymayan bildirim çekme fonksiyonunu çağırıyoruz.
    List<NotificationModel> fetched = await fetchNotifications(context);
    setState(() {
      _notifications = fetched;
      _isLoading = false;
    });
  }

  /// Bildirimleri tarihe göre gruplandırır.
  List<Map<String, dynamic>> groupNotifications() {
    List<NotificationModel> today = [];
    List<NotificationModel> last7 = [];
    List<NotificationModel> last30 = [];
    DateTime now = DateTime.now();

    for (var notif in _notifications) {
      Duration diff = now.difference(notif.timestamp);
      if (diff.inDays == 0) {
        today.add(notif);
      } else if (diff.inDays < 7) {
        last7.add(notif);
      } else if (diff.inDays < 30) {
        last30.add(notif);
      }
    }
    return [
      {'title': 'Bugün', 'items': today},
      {'title': 'Son 7 Gün', 'items': last7},
      {'title': 'Son 30 Gün', 'items': last30},
    ];
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> groups = groupNotifications();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: groups.map((group) {
                List<NotificationModel> items = group['items'];
                if (items.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grup başlığı
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          group['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // Her bir bildirimi listeleyen kısım
                      ...items.map((notif) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withAlpha((0.05 * 255).toInt()),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              notif.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(notif.subject),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
