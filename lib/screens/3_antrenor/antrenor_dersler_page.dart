// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/widgets/show_message_widget.dart';
import 'package:fitcall/common/widgets/spinner_widgets.dart';
import 'package:fitcall/models/0_ortak/etkinlik_model.dart';
import 'package:fitcall/models/3_antrenor/antrenor_model.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Tarih formatlamak için gerekli paket

class AntrenorDerslerPage extends StatefulWidget {
  const AntrenorDerslerPage({super.key});

  @override
  State<AntrenorDerslerPage> createState() => _AntrenorDerslerPageState();
}

class _AntrenorDerslerPageState extends State<AntrenorDerslerPage> {
  List<EtkinlikModel>? gelecekDersler = [];
  List<EtkinlikModel>? gecmisDersler = [];
  bool _isUpcomingLoading = false;
  bool _isPastLoading = false;

  // Filtre seçenekleri; default "bugün" seçili
  String upcomingFilter = "today"; // seçenekler: "today", "thisWeek", "all"
  String pastFilter = "today"; // seçenekler: "today", "lastWeek", "all"

  // Giriş yapan antrenörün id'si. Bu değeri uygulamanızın kullanıcı yönetiminden alabilirsiniz.
  AntrenorModel? currentAntrenor;

  @override
  void initState() {
    super.initState();
    _fetchAllLessons();
    _loadCurrentAntrenor();
  }

  Future<void> _fetchAllLessons() async {
    await Future.wait([_fetchUpcomingLessons(), _fetchPastLessons()]);
    setState(() {});
  }

  Future<void> _loadCurrentAntrenor() async {
    currentAntrenor = await AuthService.antrenorBilgileriniGetir();
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
      final int daysToSunday = 7 - now.weekday;
      final weekEnd = todayEnd.add(Duration(days: daysToSunday));
      return {"start": todayStart, "end": weekEnd};
    } else if (filter == "all") {
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
      final currentWeekStart =
          todayStart.subtract(Duration(days: now.weekday - 1));
      final lastWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      final lastWeekEnd = currentWeekStart.subtract(const Duration(seconds: 1));
      return {"start": lastWeekStart, "end": lastWeekEnd};
    } else if (filter == "all") {
      return {"start": DateTime(1900), "end": now};
    }
    return {"start": todayStart, "end": todayEnd};
  }

  Future<void> _fetchUpcomingLessons() async {
    setState(() {
      _isUpcomingLoading = true;
    });
    var token = await AuthService.getToken();
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
          List<EtkinlikModel>? lessons = EtkinlikModel.fromJson(response);
          setState(() {
            gelecekDersler = lessons;
          });
        } else {
          ShowMessage.error(context,
              'Gelecek dersler alınırken hata: ${response.statusCode}');
        }
      } catch (e) {
        ShowMessage.error(context, 'Gelecek dersler alınırken hata: $e');
      } finally {
        setState(() {
          _isUpcomingLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPastLessons() async {
    setState(() {
      _isPastLoading = true;
    });
    var token = await AuthService.getToken();
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
          List<EtkinlikModel>? lessons = EtkinlikModel.fromJson(response);
          setState(() {
            gecmisDersler = lessons;
          });
        } else {
          ShowMessage.error(
              context, 'Geçmiş dersler alınırken hata: ${response.statusCode}');
        }
      } catch (e) {
        ShowMessage.error(context, 'Geçmiş dersler alınırken hata: $e');
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

  Widget _buildClassesList(
      List<EtkinlikModel>? classes, Color color, bool isPast) {
    if (classes == null || classes.isEmpty) {
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
            DateFormat('dd-MM-yyyy').format(ders.baslangicTarihSaat);
        String formattedTime =
            DateFormat('HH:mm').format(ders.baslangicTarihSaat);

        // Ders durumu
        String dersDurumu = ders.iptalMi == true ? "İptal Edildi" : "Aktif";

        bool displayCompleted = false;
        String displayAciklama = "";
        bool isMainAntrenor = false;
        bool isYardimciAntrenor = false;
        if (currentAntrenor != null) {
          isMainAntrenor = ders.antrenor == currentAntrenor!.id;
          isYardimciAntrenor = ders.yardimciAntrenor == currentAntrenor!.id;

          if (isMainAntrenor) {
            displayCompleted = ders.tamamlandiAntrenor ?? false;
            displayAciklama = ders.antrenorAciklama ?? "";
          } else if (isYardimciAntrenor) {
            displayCompleted = ders.tamamlandiYardimciAntrenor ?? false;
            displayAciklama = ders.yardimciAntrenorAciklama ?? "";
          }
        }
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
                    '📌 Durum: ${displayCompleted ? "Tamamlandı" : "Tamamlanmadı"}'),
                if (displayAciklama.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '✏️ Açıklama: $displayAciklama',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                Text('📢 Ders Durumu: $dersDurumu',
                    style: TextStyle(
                        color:
                            ders.iptalMi == true ? Colors.red : Colors.green)),
              ],
            ),
            trailing: (isMainAntrenor || isYardimciAntrenor)
                ? IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () {
                      _showEditPopup(context, ders, displayCompleted,
                          displayAciklama, isYardimciAntrenor);
                    },
                  )
                : const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ),
        );
      },
    );
  }

  void _showEditPopup(BuildContext context, EtkinlikModel ders,
      bool currentCompleted, String currentAciklama, bool isYardimci) {
    TextEditingController notController =
        TextEditingController(text: currentAciklama);
    bool dersTamamlandi = currentCompleted;

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
                var token = await AuthService.getToken();
                if (token != null) {
                  try {
                    // Payload'da, hangi rolün güncelleneceğini belirtmek için 'is_yardimci' alanı ekleniyor.
                    Map<String, dynamic> payload = {
                      'ders_id': dersId,
                      'not': notValue,
                      'is_yardimci': isYardimci,
                    };
                    // Eğer ana antrenör ise 'antrenor_tamamlandi', yardımcı ise 'yardimci_antrenor_tamamlandi'
                    if (isYardimci) {
                      payload['yardimci_antrenor_tamamlandi'] = dersTamamlandi;
                    } else {
                      payload['antrenor_tamamlandi'] = dersTamamlandi;
                    }
                    var response = await http.post(
                      Uri.parse(antrenorDersYapildiDurumu),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode(payload),
                    );
                    if (response.statusCode == 200) {
                      setState(() {
                        if (isYardimci) {
                          ders.tamamlandiYardimciAntrenor = dersTamamlandi;
                          ders.yardimciAntrenorAciklama = notValue;
                        } else {
                          ders.tamamlandiAntrenor = dersTamamlandi;
                          ders.antrenorAciklama = notValue;
                        }
                      });
                      ShowMessage.success(context, 'Ders durumu güncellendi.');
                    } else {
                      ShowMessage.error(context,
                          'Ders durumu güncellenirken hata: ${response.statusCode}');
                    }
                  } catch (e) {
                    ShowMessage.error(
                        context, 'Ders durumu güncellenirken hata: $e');
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
