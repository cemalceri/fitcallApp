import 'package:flutter/material.dart';

class AntrenorDerslerPage extends StatelessWidget {
  AntrenorDerslerPage({super.key});

  // Gelecek Dersler Listesi (Örnek)
  final List<Map<String, String>> upcomingClasses = [
    {
      'date': '12 Şubat 2024',
      'time': '14:00',
      'student': 'Ahmet Yılmaz',
      'status': 'Planlandı',
    },
    {
      'date': '15 Şubat 2024',
      'time': '16:00',
      'student': 'Zeynep Kaya',
      'status': 'Planlandı',
    },
    {
      'date': '20 Şubat 2024',
      'time': '10:00',
      'student': 'Mehmet Öz',
      'status': 'Planlandı',
    },
  ];

  // Geçmiş Dersler Listesi (Örnek)
  final List<Map<String, String>> pastClasses = [
    {
      'date': '05 Şubat 2024',
      'time': '14:00',
      'student': 'Ayşe Demir',
      'status': 'Tamamlandı',
    },
    {
      'date': '02 Şubat 2024',
      'time': '16:00',
      'student': 'Emre Can',
      'status': 'Tamamlandı',
    },
    {
      'date': '29 Ocak 2024',
      'time': '10:00',
      'student': 'Fatma Aksoy',
      'status': 'Tamamlandı',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 Sekme: Gelecek Dersler & Geçmiş Dersler
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Derslerim'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Gelecek Dersler'),
              Tab(text: 'Geçmiş Dersler'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildClassesList(upcomingClasses, Colors.blue, context, false),
            _buildClassesList(pastClasses, Colors.green, context, true),
          ],
        ),
      ),
    );
  }

  // Dersleri Listeleyen Widget
  Widget _buildClassesList(List<Map<String, String>> classes, Color color,
      BuildContext context, bool isPast) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final lesson = classes[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: color,
              child: const Icon(Icons.calendar_today, color: Colors.white),
            ),
            title: Text(
              lesson['student']!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 Tarih: ${lesson['date']}'),
                Text('⏰ Saat: ${lesson['time']}'),
                Text('📌 Durum: ${lesson['status']}'),
              ],
            ),
            trailing: isPast
                ? IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () {
                      _showEditPopup(context, lesson);
                    },
                  )
                : const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ),
        );
      },
    );
  }

  // **Popup Penceresi (Geçmiş Dersler için)**
  void _showEditPopup(BuildContext context, Map<String, String> lesson) {
    TextEditingController notController = TextEditingController();
    bool dersTamamlandi = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Ders Değerlendirme"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ders Bilgileri
              Text(
                lesson['student']!,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('📅 Tarih: ${lesson['date']}'),
              Text('⏰ Saat: ${lesson['time']}'),
              const Divider(),
              // Not Ekleme Alanı
              TextField(
                controller: notController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Not Ekle",
                  hintText: "Derse dair yorumlarınızı ekleyin...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Ders Tamamlandı Checkbox
              Row(
                children: [
                  Checkbox(
                    value: dersTamamlandi,
                    onChanged: (value) {
                      dersTamamlandi = value!;
                    },
                  ),
                  const Text("Ders Tamamlandı"),
                ],
              ),
            ],
          ),
          actions: [
            // Kapat Butonu
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Kapat"),
            ),
            // Kaydet Butonu
            ElevatedButton(
              onPressed: () {
                // Burada not ve tamamlanma durumu API'ye gönderilebilir.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        "Not kaydedildi: ${notController.text}, Tamamlandı: $dersTamamlandi"),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }
}
