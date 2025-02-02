import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/methods.dart';
import 'package:fitcall/common/widgets.dart';
import 'package:fitcall/models/ders_models.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AntrenorDerslerPage extends StatefulWidget {
  const AntrenorDerslerPage({super.key});

  @override
  State<AntrenorDerslerPage> createState() => _AntrenorDerslerPageState();
}

class _AntrenorDerslerPageState extends State<AntrenorDerslerPage> {
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
          Uri.parse(getAntrenorDersProgrami),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          // DersModel.fromJson metodunuz response.body veya içindeki JSON veriyi almalı.
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
      length: 2,
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
              ders!.kortAdi ?? 'Öğrenci Belli Değil',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 Tarih: ${ders.baslangicTarihSaat.toLocal()}'),
                Text(
                    '⏰ Saat: ${ders.baslangicTarihSaat.hour}:${ders.baslangicTarihSaat.minute}'),
                // Antrenörün belirlediği durumu gösteriyoruz.
                Text(
                    '📌 Antrenör Durumu: ${ders.tamamlandiAntrenor == true ? "Tamamlandı" : "Tamamlanmadı"}'),
                // Eğer daha önce kaydedilmiş antrenör açıklaması varsa, bunu göster.
                if (ders.antrenorAciklama != null &&
                    ders.antrenorAciklama!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '✏️ Açıklama: ${ders.antrenorAciklama}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
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

  void _showEditPopup(BuildContext context, DersModel ders) {
    // Eğer daha önce kaydedilmiş antrenör açıklaması varsa, TextField buna göre dolu gelsin.
    TextEditingController notController =
        TextEditingController(text: ders.antrenorAciklama ?? '');
    bool dersTamamlandi = ders.tamamlandiAntrenor ?? false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Ders Değerlendirme"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text("Ders tamamlandı mı?"),
                    value: dersTamamlandi,
                    onChanged: (bool? value) {
                      setState(() {
                        dersTamamlandi = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Not Ekle",
                      hintText: "Derse dair yorumlarınızı ekleyin...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Kapat"),
            ),
            ElevatedButton(
              onPressed: () async {
                final dersId = ders
                    .id; // Modelinizde id alanının bulunduğunu varsayıyoruz.
                final notValue = notController.text;
                var token = await getToken(context);
                if (token != null) {
                  try {
                    var response = await http.post(
                      Uri.parse(antrenorDersYapildiDurumu),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode({
                        'ders_id': dersId,
                        'not': notValue,
                        'antrenor_tamamlandi': dersTamamlandi,
                      }),
                    );
                    if (response.statusCode == 200) {
                      // API isteği başarılı ise, ilgili dersin durumu ve açıklamasını güncelliyoruz.
                      setState(() {
                        ders.tamamlandiAntrenor = dersTamamlandi;
                        ders.antrenorAciklama = notValue;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Değerlendirme kaydedildi.")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Hata: ${response.statusCode}")),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("API hatası: $e")),
                    );
                  }
                }
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
