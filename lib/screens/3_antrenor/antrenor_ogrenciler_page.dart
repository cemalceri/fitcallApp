// lib/screens/5_etkinlik/antrenor_ogrenciler_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:fitcall/models/2_uye/uye_model.dart';
import 'package:fitcall/screens/1_common/widgets/show_message_widget.dart';
import 'package:fitcall/services/antrenor/antrenor_api_service.dart';
import 'package:fitcall/services/api_exception.dart';
import 'package:flutter/material.dart';

class AntrenorOgrencilerPage extends StatefulWidget {
  const AntrenorOgrencilerPage({super.key});

  @override
  State<AntrenorOgrencilerPage> createState() => _AntrenorOgrencilerPageState();
}

class _AntrenorOgrencilerPageState extends State<AntrenorOgrencilerPage> {
  List<UyeModel> students = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _yukleOgrenciler();
  }

  Future<void> _yukleOgrenciler() async {
    setState(() => isLoading = true);
    try {
      final res = await AntrenorApiService.getirOgrencilerim();
      final data = res.data;
      if (data == null) {
        ShowMessage.error(context, res.mesaj);
        return;
      }
      if (!mounted) return;
      setState(() => students = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      ShowMessage.error(context, 'Öğrenciler alınamadı: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showStudentDetails(UyeModel student) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('${student.adi} ${student.soyadi}'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              if (student.profilFotografi != null &&
                  student.profilFotografi!.isNotEmpty)
                Center(
                  child: ClipOval(
                    child: Image.network(
                      student.profilFotografi!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, size: 100);
                      },
                    ),
                  ),
                )
              else
                const Center(child: Icon(Icons.person, size: 100)),
              const SizedBox(height: 16),
              Text('Telefon: ${student.telefon ?? 'Bilinmiyor'}'),
              const SizedBox(height: 4),
              Text('Email: ${student.email ?? 'Bilinmiyor'}'),
              const SizedBox(height: 4),
              Text('Cinsiyet: ${student.cinsiyet}'),
              const SizedBox(height: 4),
              Text(
                'Doğum Tarihi: ${student.dogumTarihi != null ? student.dogumTarihi!.toLocal().toString().split(' ')[0] : 'Bilinmiyor'}',
              ),
              const SizedBox(height: 4),
              Text('Adres: ${student.adres}'),
              const SizedBox(height: 4),
              Text('Üye No: ${student.uyeNo}'),
              const SizedBox(height: 4),
              Text('Seviye Rengi: ${student.seviyeRengi}'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Kapat'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Öğrencilerim')),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: students.isEmpty
                    ? const Center(child: Text('Öğrenci bulunamadı.'))
                    : GridView.builder(
                        itemCount: students.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => showStudentDetails(student),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person,
                                    size: 50,
                                    color: Color.fromARGB(255, 47, 42, 42)),
                                const SizedBox(height: 10),
                                Text(
                                  '${student.adi} ${student.soyadi}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 14, 46, 190),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
      );
}
