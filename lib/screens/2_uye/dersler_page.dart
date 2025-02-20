import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/methods.dart';
import 'package:fitcall/common/widgets.dart';
import 'package:fitcall/models/0_ortak/etkinlik_model.dart';
import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DersListesiPage extends StatefulWidget {
  const DersListesiPage({super.key});

  @override
  State<DersListesiPage> createState() => _DersListesiPageState();
}

class _DersListesiPageState extends State<DersListesiPage> {
  List<EtkinlikModel?> gecmisDersler = [];
  List<EtkinlikModel?> gelecekDersler = [];
  bool _apiIstegiTamamlandiMi = false;

  // Prefs'den çekilen UyeModel örneği; mevcut kullanıcının id'si burada tutulacak.
  UyeModel? currentUye;

  @override
  void initState() {
    super.initState();
    _loadCurrentUye();
    _dersBilgileriniCek();
  }

  Future<void> _loadCurrentUye() async {
    currentUye = await uyeBilgileriniGetir(context);
    setState(() {});
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
          List<EtkinlikModel>? tumDersler = EtkinlikModel.fromJson(response);
          setState(() {
            gecmisDersler = (tumDersler ?? [])
                .where((element) =>
                    element!.bitisTarihSaat.isBefore(DateTime.now()))
                .toList();
            gelecekDersler = (tumDersler ?? [])
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

  Widget _buildClassesList(
      List<EtkinlikModel?> classes, Color color, bool isPast) {
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
        // Mevcut kullanıcının onay bilgisini, "uye_onaylari" listesinden arıyoruz.
        UyeEtkinlikOnayModel? userApproval;
        if (ders!.uyeOnaylari != null && currentUye != null) {
          for (final approval in ders.uyeOnaylari!) {
            if (approval.uye == currentUye!.id) {
              // id üzerinden karşılaştırma yapılıyor.
              userApproval = approval;
              break;
            }
          }
        }
        final bool userCompleted = userApproval?.tamamlandi ?? false;
        final String userAciklama = userApproval?.aciklama ?? '';

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
              ders.kortAdi ?? 'Kort Belli Değil',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 Tarih: ${ders.baslangicTarihSaat.toLocal()}'),
                Text(
                    '⏰ Saat: ${ders.baslangicTarihSaat.hour}:${ders.baslangicTarihSaat.minute}'),
                Text(
                    '📌 Durum: ${userCompleted ? "Tamamlandı" : "Tamamlanmadı"}'),
                if (userAciklama.isNotEmpty) Text('💬 Açıklama: $userAciklama'),
              ],
            ),
            trailing: isPast
                ? IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () {
                      _showEditPopup(
                          context, ders, userCompleted, userAciklama);
                    },
                  )
                : const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ),
        );
      },
    );
  }

  void _showEditPopup(BuildContext context, EtkinlikModel ders,
      bool userCompleted, String userAciklama) {
    TextEditingController notController =
        TextEditingController(text: userAciklama);
    bool dersTamamlandi = userCompleted;

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
                final dersId = ders.id;
                final notValue = notController.text;
                var token = await getToken(context);
                if (token != null) {
                  try {
                    var response = await http.post(
                      Uri.parse(setDersYapildiBilgisi),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode({
                        'ders_id': dersId,
                        'aciklama': notValue,
                        'tamamlandi': dersTamamlandi,
                      }),
                    );
                    if (response.statusCode == 200) {
                      setState(() {
                        if (ders.uyeOnaylari != null && currentUye != null) {
                          bool found = false;
                          for (var approval in ders.uyeOnaylari!) {
                            if (approval.uye == currentUye!.id) {
                              approval.tamamlandi = dersTamamlandi;
                              approval.aciklama = notValue;
                              found = true;
                              break;
                            }
                          }
                          if (!found) {
                            ders.uyeOnaylari!.add(UyeEtkinlikOnayModel(
                              id: 0, // API tarafından belirlenecek.
                              uye: currentUye!.id,
                              tamamlandi: dersTamamlandi,
                              aciklama: notValue,
                            ));
                          }
                        }
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
