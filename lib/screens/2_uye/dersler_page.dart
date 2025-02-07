import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/methods.dart';
import 'package:fitcall/common/widgets.dart';
import 'package:fitcall/models/0_ortak/ders_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DersListesiPage extends StatefulWidget {
  const DersListesiPage({super.key});

  @override
  State<DersListesiPage> createState() => _DersListesiPageState();
}

class _DersListesiPageState extends State<DersListesiPage> {
  List<DersModel?> gecmisDersler = [];
  List<DersModel?> gelecekDersler = [];
  bool _apiIstegiTamamlandiMi = false;

  @override
  void initState() {
    super.initState();
    _dersBilgileriniCek();
  }

  Future<void> _dersBilgileriniCek() async {
    var token = await getToken(context);
    if (token != null) {
      try {
        var response = await http.post(
          Uri.parse(getDersProgrami),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          List<DersModel?> tumDersler = DersModel.fromJson(response);
          setState(() {
            gecmisDersler = tumDersler
                .where((element) =>
                    element!.bitisTarihSaat.isBefore(DateTime.now()))
                .toList();
            gelecekDersler = tumDersler
                .where((element) =>
                    element!.bitisTarihSaat.isAfter(DateTime.now()))
                .toList();
          });
        } else {
          throw Exception('API isteği başarısız oldu: ${response.statusCode}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dersler alınırken bir hata oluştu: $e'),
            ),
          );
        }
      } finally {
        setState(() {
          _apiIstegiTamamlandiMi = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 sekme: Gelecek Dersler & Geçmiş Dersler
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ders Listesi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Gelecek Dersler'),
              Tab(text: 'Geçmiş Dersler'),
            ],
          ),
        ),
        body: _apiIstegiTamamlandiMi
            ? TabBarView(
                children: [
                  _buildClassesList(gelecekDersler, Colors.blue, false),
                  _buildClassesList(gecmisDersler, Colors.green, true),
                ],
              )
            : const LoadingSpinnerWidget(message: 'Dersler yükleniyor...'),
      ),
    );
  }

  // Dersleri Listeleyen Widget
  Widget _buildClassesList(List<DersModel?> classes, Color color, bool isPast) {
    if (classes.isEmpty) {
      return const Center(
        child: Text(
          "Bu kategoriye ait ders bulunmamaktadır.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final ders = classes[index];
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
              ders!.kortAdi ?? 'Kort Belli Değil',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 Tarih: ${ders.baslangicTarihSaat.toLocal()}'),
                Text(
                    '⏰ Saat: ${ders.baslangicTarihSaat.hour}:${ders.baslangicTarihSaat.minute}'),
                Text(
                    '📌 Durum: ${ders.bitisTarihSaat.isBefore(DateTime.now()) ? "Tamamlandı" : "Planlandı"}'),
              ],
            ),
            trailing: isPast
                ? IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () {
                      _showEditPopup(context, ders);
                    },
                  )
                : const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ),
        );
      },
    );
  }

  // **Popup Penceresi (Geçmiş Dersler için)**
  void _showEditPopup(BuildContext context, DersModel ders) {
    TextEditingController notController = TextEditingController();
    bool dersTamamlandi = false;

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
                      setState(() {});
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
