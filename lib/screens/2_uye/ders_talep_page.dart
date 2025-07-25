// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/models/2_uye/ders_talebi_model.dart';
import 'package:fitcall/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DersTalepPage extends StatefulWidget {
  const DersTalepPage({super.key});

  @override
  DersTalepPageState createState() => DersTalepPageState();
}

class DersTalepPageState extends State<DersTalepPage> {
  final _formKey = GlobalKey<FormState>();

  // Form alanları için controller'lar
  final TextEditingController seviyeController = TextEditingController();
  final TextEditingController referansController = TextEditingController();
  final TextEditingController aciklamaController = TextEditingController();

  // Eklenen zaman dilimleri listesi
  final List<DersZamanDilimiModel> _zamanDilimleri = [];

  // Önceki taleplerin listesi
  List<DersTalebiModel> _previousRequests = [];
  bool _isLoadingRequests = false;

  // SharedPreferences'ten alınacak bilgiler
  String? token;
  String? uye;
  int? user;

  // Saat listesi: 07:00'dan 21:00'e kadar
  final List<String> _saatler = List.generate(15, (index) {
    final hour = 7 + index;
    return "${hour.toString().padLeft(2, '0')}:00";
  });

  // Gün seçenekleri: key int, value gün adı
  final Map<int, String> _gunler = {
    1: "Pazartesi",
    2: "Salı",
    3: "Çarşamba",
    4: "Perşembe",
    5: "Cuma",
    6: "Cumartesi",
    7: "Pazar",
  };

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final tokenValue = await AuthService.getToken();
    final uyeInfo = await AuthService.uyeBilgileriniGetir();
    final userInfo = await AuthService.userBilgileriniGetir();
    setState(() {
      token = tokenValue;
      uye = uyeInfo?.id.toString();
      user = userInfo?.id;
    });
    _fetchPreviousRequests();
  }

  Future<void> _fetchPreviousRequests() async {
    setState(() {
      _isLoadingRequests = true;
    });
    final response = await http.post(
      Uri.parse(getUyedersTalepListesi),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      setState(() {
        _previousRequests =
            data.map((e) => DersTalebiModel.fromJson(e)).toList();
        _isLoadingRequests = false;
      });
    } else {
      setState(() {
        _isLoadingRequests = false;
      });
      ShowMessage.error(context, 'Talepler alınırken bir hata oluştu.');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _zamanDilimleri.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Lütfen tüm alanları doldurunuz ve en az bir zaman dilimi ekleyiniz.')),
      );
      return;
    }

    Map<String, dynamic> dersTalebiData = {
      'uye': uye,
      'seviye': seviyeController.text,
      'referans': referansController.text,
      'antrenor': null,
      'aktif_mi': true,
      'aciklama': aciklamaController.text,
      'user': user,
      'zaman_dilimleri': _zamanDilimleri.map((e) => e.toJson()).toList(),
    };

    final response = await http.post(
      Uri.parse(dersTalebiOlustur),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(dersTalebiData),
    );

    if (response.statusCode == 200) {
      ShowMessage.success(context, 'Ders talebi başarıyla oluşturuldu.');
      _fetchPreviousRequests(); // Yeni talep eklendikten sonra listeyi yenile
    } else {
      ShowMessage.error(context, 'Ders talebi oluşturulurken bir hata oluştu.');
    }
  }

  Future<void> _showZamanDilimiDialog() async {
    int? selectedGun;
    List<String> selectedSaatler = [];
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Zaman Dilimi Ekle"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: "Gün Seçiniz",
                        border: OutlineInputBorder(),
                      ),
                      items: _gunler.entries.map((entry) {
                        return DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedGun = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? "Lütfen bir gün seçiniz" : null,
                    ),
                    SizedBox(height: 16),
                    Text("Saat Seçiniz"),
                    Wrap(
                      spacing: 8,
                      children: _saatler.map((saat) {
                        bool isSelected = selectedSaatler.contains(saat);
                        return FilterChip(
                          label: Text(saat),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setStateDialog(() {
                              if (selected) {
                                selectedSaatler.add(saat);
                              } else {
                                selectedSaatler.remove(saat);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedGun != null && selectedSaatler.isNotEmpty) {
                      setState(() {
                        _zamanDilimleri.add(
                          DersZamanDilimiModel(
                              gun: selectedGun!,
                              saatler: List.from(selectedSaatler)),
                        );
                      });
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text("Lütfen gün ve en az bir saat seçiniz.")),
                      );
                    }
                  },
                  child: Text("Ekle"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildZamanDilimiList() {
    if (_zamanDilimleri.isEmpty) {
      return Text("Henüz zaman dilimi eklenmedi.");
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _zamanDilimleri.length,
      itemBuilder: (context, index) {
        final item = _zamanDilimleri[index];
        return ListTile(
          title: Text("${_gunler[item.gun]} - ${item.saatler.join(', ')}"),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                _zamanDilimleri.removeAt(index);
              });
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteRequest(int id) async {
    final response = await http.post(
      Uri.parse(silUyedersTalebi),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id': id}),
    );
    if (response.statusCode == 200) {
      ShowMessage.success(context, 'Talep başarıyla silindi.');
      _fetchPreviousRequests();
    } else {
      ShowMessage.error(context, 'Talep silinirken bir hata oluştu.');
    }
  }

  Future<void> _showRequestDetails(DersTalebiModel talep) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Talep Detayları"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Seviye: ${talep.seviye ?? '-'}"),
                SizedBox(height: 8),
                Text("Referans: ${talep.referans ?? '-'}"),
                SizedBox(height: 8),
                Text("Açıklama:"),
                Text(talep.aciklama ?? '-',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Zaman Dilimleri:"),
                ...talep.zamanDilimleri.map((zaman) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                        "${_gunler[zaman.gun]}: ${zaman.saatler.join(', ')}"),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (talep.id != null) {
                  _deleteRequest(talep.id!);
                  Navigator.pop(context);
                }
              },
              child: Text("Sil", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Kapat"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviousRequests() {
    if (_isLoadingRequests) {
      return Center(child: CircularProgressIndicator());
    }
    if (_previousRequests.isEmpty) {
      return Text("Önceki talep bulunamadı.");
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _previousRequests.length,
      itemBuilder: (context, index) {
        final talep = _previousRequests[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text("Seviye: ${talep.seviye ?? '-'}"),
            subtitle: Text(
                "Zaman Dilimleri: ${talep.zamanDilimleri.map((z) => _gunler[z.gun]).join(', ')}"),
            onTap: () => _showRequestDetails(talep),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ders Talep Formu')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          'Ders Talebi Oluştur',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: seviyeController,
                          decoration: InputDecoration(
                            labelText: 'Seviye',
                            prefixIcon: Icon(Icons.school),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Seviye gerekli'
                              : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: referansController,
                          decoration: InputDecoration(
                            labelText: 'Referansınız (varsa)',
                            prefixIcon: Icon(Icons.link),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: aciklamaController,
                          decoration: InputDecoration(
                            labelText: 'Lütfen tüm diğer detayları yazınız.',
                            prefixIcon: Icon(Icons.note),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          maxLines: 7,
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Zaman Dilimleri',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showZamanDilimiDialog,
                              icon: Icon(Icons.add),
                              label: Text('Ekle'),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildZamanDilimiList(),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Gönder', style: TextStyle(fontSize: 18)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Divider(),
              SizedBox(height: 8),
              Text(
                "Önceki Taleplerim",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildPreviousRequests(),
            ],
          ),
        ),
      ),
    );
  }
}
