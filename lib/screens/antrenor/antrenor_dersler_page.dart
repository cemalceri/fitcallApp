import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/methods.dart';
import 'package:fitcall/common/widgets.dart';
import 'package:fitcall/models/ders_models.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Tarih formatlamak için gerekli paket

class AntrenorDerslerPage extends StatefulWidget {
  const AntrenorDerslerPage({super.key});

  @override
  State<AntrenorDerslerPage> createState() => _AntrenorDerslerPageState();
}

class _AntrenorDerslerPageState extends State<AntrenorDerslerPage> {
  List<DersModel?> gelecekDersler = [];
  List<DersModel?> gecmisDersler = [];
  bool _isUpcomingLoading = false;
  bool _isPastLoading = false;

  // Filtre seçenekleri; default "bugün" seçili
  String upcomingFilter = "today"; // seçenekler: "today", "thisWeek", "all"
  String pastFilter = "today"; // seçenekler: "today", "lastWeek", "all"

  @override
  void initState() {
    super.initState();
    _fetchAllLessons();
  }

  Future<void> _fetchAllLessons() async {
    await Future.wait([_fetchUpcomingLessons(), _fetchPastLessons()]);
    setState(() {});
  }

  /// Gelecek dersler için, seçili filtreye göre tarih aralığı hesapla
  Map<String, DateTime> _getUpcomingDateRange(String filter) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));
    if (filter == "today") {
      return {"start": todayStart, "end": todayEnd};
    } else if (filter == "thisWeek") {
      // Haftanın son günü (pazar) hesaplanıyor
      final int daysToSunday = 7 - now.weekday; // Eğer bugün pazar ise 0 döner
      final weekEnd = todayEnd.add(Duration(days: daysToSunday));
      return {"start": todayStart, "end": weekEnd};
    } else if (filter == "all") {
      // Tüm gelecek dersler: şimdi'den çok ileri bir tarihe kadar
      return {"start": now, "end": DateTime(2100)};
    }
    return {"start": todayStart, "end": todayEnd};
  }

  /// Geçmiş dersler için, seçili filtreye göre tarih aralığı hesapla
  Map<String, DateTime> _getPastDateRange(String filter) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));
    if (filter == "today") {
      return {"start": todayStart, "end": todayEnd};
    } else if (filter == "lastWeek") {
      // Örneğin: geçerli haftanın başlangıcını bulup bir hafta geriye alıyoruz.
      final currentWeekStart =
          todayStart.subtract(Duration(days: now.weekday - 1));
      final lastWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      final lastWeekEnd = currentWeekStart.subtract(const Duration(seconds: 1));
      return {"start": lastWeekStart, "end": lastWeekEnd};
    } else if (filter == "all") {
      // Tüm geçmiş dersler: çok eski bir tarihten şimdilik
      return {"start": DateTime(1900), "end": now};
    }
    return {"start": todayStart, "end": todayEnd};
  }

  /// API'ye baslangic ve bitis tarihleri göndererek gelecek dersleri getir
  Future<void> _fetchUpcomingLessons() async {
    setState(() {
      _isUpcomingLoading = true;
    });
    var token = await getToken(context);
    if (token != null) {
      final dateRange = _getUpcomingDateRange(upcomingFilter);
      try {
        var response = await http.post(
          Uri.parse(getAntrenorDersProgrami),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'baslangic': dateRange["start"]!.toIso8601String(),
            'bitis': dateRange["end"]!.toIso8601String(),
          }),
        );
        if (response.statusCode == 200) {
          // DersModel.fromJson metodunuzun, gelen JSON listesini doğru şekilde parse ettiğini varsayıyoruz.
          List<DersModel?> lessons = DersModel.fromJson(response);
          setState(() {
            gelecekDersler = lessons;
          });
        } else {
          throw Exception('API isteği başarısız oldu: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gelecek dersler alınırken hata: $e'),
          ),
        );
      } finally {
        setState(() {
          _isUpcomingLoading = false;
        });
      }
    }
  }

  /// API'ye baslangic ve bitis tarihleri göndererek geçmiş dersleri getir
  Future<void> _fetchPastLessons() async {
    setState(() {
      _isPastLoading = true;
    });
    var token = await getToken(context);
    if (token != null) {
      final dateRange = _getPastDateRange(pastFilter);
      try {
        var response = await http.post(
          Uri.parse(getAntrenorDersProgrami),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'baslangic': dateRange["start"]!.toIso8601String(),
            'bitis': dateRange["end"]!.toIso8601String(),
          }),
        );
        if (response.statusCode == 200) {
          List<DersModel?> lessons = DersModel.fromJson(response);
          setState(() {
            gecmisDersler = lessons;
          });
        } else {
          throw Exception('API isteği başarısız oldu: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geçmiş dersler alınırken hata: $e'),
          ),
        );
      } finally {
        setState(() {
          _isPastLoading = false;
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
        body: TabBarView(
          children: [
            _buildUpcomingTab(),
            _buildPastTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return Column(
      children: [
        _buildUpcomingFilterButtons(),
        Expanded(
          child: _isUpcomingLoading
              ? const LoadingSpinnerWidget(message: 'Dersler yükleniyor...')
              : _buildClassesList(gelecekDersler, Colors.blue, false),
        ),
      ],
    );
  }

  Widget _buildPastTab() {
    return Column(
      children: [
        _buildPastFilterButtons(),
        Expanded(
          child: _isPastLoading
              ? const LoadingSpinnerWidget(message: 'Dersler yükleniyor...')
              : _buildClassesList(gecmisDersler, Colors.green, true),
        ),
      ],
    );
  }

  Widget _buildUpcomingFilterButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: const Text("Bugün"),
            selected: upcomingFilter == "today",
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  upcomingFilter = "today";
                });
                _fetchUpcomingLessons();
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text("Bu Hafta"),
            selected: upcomingFilter == "thisWeek",
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  upcomingFilter = "thisWeek";
                });
                _fetchUpcomingLessons();
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text("Tümü"),
            selected: upcomingFilter == "all",
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  upcomingFilter = "all";
                });
                _fetchUpcomingLessons();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPastFilterButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: const Text("Bugün"),
            selected: pastFilter == "today",
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  pastFilter = "today";
                });
                _fetchPastLessons();
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text("Geçen Hafta"),
            selected: pastFilter == "lastWeek",
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  pastFilter = "lastWeek";
                });
                _fetchPastLessons();
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text("Tümü"),
            selected: pastFilter == "all",
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  pastFilter = "all";
                });
                _fetchPastLessons();
              }
            },
          ),
        ],
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

        // Tarih ve saat formatlama
        String formattedDate =
            DateFormat('dd-MM-yyyy').format(ders!.baslangicTarihSaat);
        String formattedTime =
            DateFormat('HH:mm').format(ders.baslangicTarihSaat);

        // Ders durumu belirleme
        String dersDurumu = ders.iptalMi == true ? "İptal Edildi" : "Aktif";

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
              '${ders.kortAdi} - ${ders.grupAdi}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 Tarih: $formattedDate'),
                Text('⏰ Saat: $formattedTime'),
                Text(
                    '📌 Antrenör Durumu: ${ders.tamamlandiAntrenor == true ? "Tamamlandı" : "Tamamlanmadı"}'),
                Text('📢 Ders Durumu: $dersDurumu',
                    style: TextStyle(
                        color:
                            ders.iptalMi == true ? Colors.red : Colors.green)),
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
                final dersId = ders.id;
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
