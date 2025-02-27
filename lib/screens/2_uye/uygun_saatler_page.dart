// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:fitcall/common/api_urls.dart'; // getUygunSaatler URL'sinin burada tanımlı olduğunu varsayıyoruz.
import 'package:fitcall/common/windgets/show_message_widget.dart';
import 'package:fitcall/models/2_uye/uygun_saatler_model.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class UygunSaatlerPage extends StatefulWidget {
  const UygunSaatlerPage({super.key});

  @override
  UygunSaatlerPageState createState() => UygunSaatlerPageState();
}

class UygunSaatlerPageState extends State<UygunSaatlerPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  List<UygunSaatModel> _fetchedSlots = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectStartDate() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _fetchUygunSaatler() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Lütfen başlangıç ve bitiş tarihlerini seçiniz.")),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _fetchedSlots = [];
    });

    var token = AuthService.getToken();

    Map<String, dynamic> payload = {
      "start_date": _startDate!.toIso8601String().substring(0, 10),
      "end_date": _endDate!.toIso8601String().substring(0, 10),
    };

    final response = await http.post(
      Uri.parse(getUygunSaatler),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      List<dynamic> list = jsonResponse['uygun_saatler'];
      List<UygunSaatModel> slots =
          list.map((e) => UygunSaatModel.fromJson(e)).toList();
      setState(() {
        _fetchedSlots = slots;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ShowMessage.error(context, 'Uygun saatler alınamadı.');
    }
  }

  /// Günlere göre veriyi gruplamak için
  Map<String, List<UygunSaatModel>> _groupSlotsByDay() {
    Map<String, List<UygunSaatModel>> daysMap = {};
    for (var slot in _fetchedSlots) {
      // Tarihi "YYYY-MM-DD" formatında alıyoruz
      String dayKey = slot.tarih.toIso8601String().substring(0, 10);
      if (daysMap.containsKey(dayKey)) {
        daysMap[dayKey]!.add(slot);
      } else {
        daysMap[dayKey] = [slot];
      }
    }
    return daysMap;
  }

  /// Belirli bir gün içindeki saatleri, aynı "başlangıç, bitiş, kort, kortId" kombinasyonuna göre grupluyoruz.
  Map<String, List<UygunSaatModel>> _groupSlotsByTime(
      List<UygunSaatModel> slots) {
    Map<String, List<UygunSaatModel>> timesMap = {};
    for (var slot in slots) {
      String timeKey =
          "${slot.baslangic}-${slot.bitis}-${slot.kort}-${slot.kortId}";
      if (timesMap.containsKey(timeKey)) {
        timesMap[timeKey]!.add(slot);
      } else {
        timesMap[timeKey] = [slot];
      }
    }
    return timesMap;
  }

  /// Belirli bir zaman grubundaki uygun hocaları gösteren dialog
  void _showInstructorsDialog(List<UygunSaatModel> slots) {
    // Aynı zaman grubu için, hocaları ayıklıyoruz (benzersiz olacak şekilde)
    Map<int, String> instructors = {};
    for (var slot in slots) {
      instructors[slot.antrenorId] = slot.antrenor;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Uygun Hocalar"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: instructors.entries.map((entry) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(entry.value),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Kapat"),
            ),
          ],
        );
      },
    );
  }

  /// Gün kartlarını oluşturuyoruz
  Widget _buildDaysCards() {
    Map<String, List<UygunSaatModel>> daysMap = _groupSlotsByDay();
    List<String> sortedDays = daysMap.keys.toList()..sort();
    return Column(
      children: sortedDays.map((day) {
        // Her gün için zaman gruplarını oluşturuyoruz
        Map<String, List<UygunSaatModel>> timesMap =
            _groupSlotsByTime(daysMap[day]!);
        List<String> sortedTimeKeys = timesMap.keys.toList()..sort();

        // Tarihi "dd-MM-yyyy" formatında alıyoruz
        DateTime parsedDate = DateTime.parse(day);
        String formattedDate = DateFormat("dd-MM-yyyy").format(parsedDate);
        // Modelde eklediğiniz 'gun' alanını, bu gün grubundaki ilk slot'tan alıyoruz
        String gunAdi = daysMap[day]![0].gun;
        // Tarih ve gün adını yan yana ekliyoruz
        String headerTitle = "$formattedDate $gunAdi";

        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            title: Text(headerTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            children: sortedTimeKeys.map((timeKey) {
              // timeKey örn. "09:00-10:00-Kort A-1"
              List<UygunSaatModel> timeSlots = timesMap[timeKey]!;
              // Zaman dilimi bilgilerini ayrıştırıyoruz
              List<String> parts = timeKey.split("-");
              String zamanBaslangic = parts[0];
              String zamanBitis = parts[1];
              String kort = parts[2];
              return ListTile(
                leading: const Icon(Icons.schedule),
                title: Text("$zamanBaslangic - $zamanBitis"),
                subtitle: Text("Kort: $kort"),
                onTap: () {
                  _showInstructorsDialog(timeSlots);
                },
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Uygun Saatler"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarih aralığı seçimi
            const Text("Tarih Aralığı Seçiniz",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectStartDate,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_startDate == null
                        ? "Başlangıç Tarihi"
                        : DateFormat("dd-MM-yyyy").format(_startDate!)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectEndDate,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_endDate == null
                        ? "Bitiş Tarihi"
                        : DateFormat("dd-MM-yyyy").format(_endDate!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _fetchUygunSaatler,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Uygun Saat Sorgula",
                    style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _fetchedSlots.isEmpty
                    ? const Text("Ders alınabilecek uygun saat bulunamadı.")
                    : _buildDaysCards(),
          ],
        ),
      ),
    );
  }
}
